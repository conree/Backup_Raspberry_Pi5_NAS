#!/bin/bash
# NAS Backup Script - Complete backup solution for Pi 5 NAS
# Version: 2.0
# Description: Automated backup with bandwidth limiting and comprehensive logging

# Configuration
LOG_FILE="/home/YOUR_USERNAME/logs/backup.log"
CONFIG_DIR="/home/YOUR_USERNAME/scripts/backup"
BACKUP_DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOCK_FILE="/tmp/nas_backup.lock"

# Backup paths - Update these to match your drive UUIDs
PHOTOS_PATH="/srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333/photo_collection"
DOCKER_CONFIG_PATH="/home/YOUR_USERNAME/docker"
OMV_CONFIG_PATH="/tmp/omv_config_backup.json"

# Google Drive paths
GDRIVE_PHOTOS="gdrive:NAS_Backup/PhotoCollection"
GDRIVE_CONFIG="gdrive:NAS_Backup/Config"
GDRIVE_DOCKER="gdrive:NAS_Backup/Docker"
GDRIVE_SYSTEM="gdrive:NAS_Backup/System"

# Bandwidth limits (MB/s)
PHOTOS_BANDWIDTH=50
CONFIG_BANDWIDTH=10
DOCKER_BANDWIDTH=10

# Create necessary directories
mkdir -p /home/YOUR_USERNAME/logs
mkdir -p "$CONFIG_DIR"

# Function: Log with timestamp
log_message() {
    echo "[$BACKUP_DATE] $1" | tee -a "$LOG_FILE"
}

# Function: Check if another backup is running
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            log_message "ERROR: Another backup process is already running (PID: $pid)"
            exit 1
        else
            log_message "WARN: Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

# Function: Remove lock on exit
cleanup() {
    rm -f "$LOCK_FILE"
    log_message "Backup process completed"
}

# Function: Check available space
check_space() {
    local path="$1"
    local min_space_gb="$2"
    
    if [ -d "$path" ]; then
        local available_gb=$(df "$path" | awk 'NR==2 {print int($4/1024/1024)}')
        if [ "$available_gb" -lt "$min_space_gb" ]; then
            log_message "WARN: Low disk space on $path: ${available_gb}GB available"
            return 1
        fi
    fi
    return 0
}

# Function: Test rclone connection
test_rclone() {
    log_message "Testing rclone connection to Google Drive..."
    if rclone lsd gdrive: > /dev/null 2>&1; then
        log_message "SUCCESS: rclone connection verified"
        return 0
    else
        log_message "ERROR: rclone connection failed"
        return 1
    fi
}

# Function: Backup with retry logic
backup_with_retry() {
    local source="$1"
    local destination="$2"
    local bandwidth="$3"
    local transfers="$4"
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        log_message "Backup attempt $((retry_count + 1)): $source -> $destination"
        
        if rclone sync "$source" "$destination" \
            --bwlimit "${bandwidth}M" \
            --transfers "$transfers" \
            --checkers 4 \
            --log-file="$LOG_FILE" \
            --log-level INFO \
            --exclude "*.tmp" \
            --exclude "*.temp" \
            --exclude "*.lock" \
            --exclude ".DS_Store" \
            --exclude "Thumbs.db" \
            --stats 30s \
            --stats-one-line; then
            
            log_message "SUCCESS: Backup completed for $source"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_message "WARN: Backup attempt $retry_count failed for $source"
            if [ $retry_count -lt $max_retries ]; then
                local wait_time=$((retry_count * 60))
                log_message "Waiting ${wait_time}s before retry..."
                sleep $wait_time
            fi
        fi
    done
    
    log_message "ERROR: Backup failed after $max_retries attempts: $source"
    return 1
}

# Function: Generate system info backup
backup_system_info() {
    local temp_dir="/tmp/system_backup_$$"
    mkdir -p "$temp_dir"
    
    # Collect system information
    {
        echo "=== System Backup Created: $(date) ==="
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -a)"
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
        echo "Uptime: $(uptime)"
        echo "Memory: $(free -h)"
        echo "Storage: $(df -h)"
        echo "Temperature: $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')"
        echo "Throttling: $(vcgencmd get_throttled 2>/dev/null || echo 'N/A')"
    } > "$temp_dir/system_info.txt"
    
    # Copy important config files
    cp /boot/firmware/config.txt "$temp_dir/" 2>/dev/null
    cp /etc/fstab "$temp_dir/" 2>/dev/null
    cp /etc/crontab "$temp_dir/" 2>/dev/null
    crontab -l > "$temp_dir/user_crontab.txt" 2>/dev/null
    
    # Docker information
    if command -v docker > /dev/null; then
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$temp_dir/docker_containers.txt"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" > "$temp_dir/docker_images.txt"
    fi
    
    # SnapRAID status
    if command -v snapraid > /dev/null; then
        snapraid status > "$temp_dir/snapraid_status.txt" 2>/dev/null
    fi
    
    # Network configuration
    ip addr show > "$temp_dir/network_interfaces.txt"
    
    # Backup system info to cloud
    rclone sync "$temp_dir" "$GDRIVE_SYSTEM" \
        --bwlimit "${CONFIG_BANDWIDTH}M" \
        --log-file="$LOG_FILE" \
        --log-level INFO
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Function: Check backup integrity
verify_backup() {
    local source="$1"
    local destination="$2"
    
    log_message "Verifying backup integrity: $destination"
    
    if rclone check "$source" "$destination" \
        --one-way \
        --log-file="$LOG_FILE" \
        --log-level ERROR; then
        log_message "SUCCESS: Backup verification passed for $destination"
        return 0
    else
        log_message "WARN: Backup verification found differences in $destination"
        return 1
    fi
}

# Function: Send notification (optional - requires mail setup)
send_notification() {
    local status="$1"
    local message="$2"
    
    # Example using mail command (configure postfix/sendmail separately)
    # echo "$message" | mail -s "NAS Backup $status" admin@yourdomain.com
    
    # Alternative: Log to system journal
    logger -t nas_backup "$status: $message"
}

# Function: Generate backup report
generate_report() {
    local start_time="$1"
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local duration=$(( $(date -d "$end_time" +%s) - $(date -d "$start_time" +%s) ))
    
    log_message "=== Backup Report ==="
    log_message "Start Time: $start_time"
    log_message "End Time: $end_time"
    log_message "Duration: ${duration}s ($((duration/60))m $((duration%60))s)"
    
    # Check Google Drive usage
    if command -v rclone > /dev/null; then
        local usage=$(rclone about gdrive: 2>/dev/null | grep "Total:" | awk '{print $2, $3}')
        log_message "Google Drive Usage: $usage"
    fi
    
    log_message "=== End Report ==="
}

# Main backup function
main() {
    local start_time="$BACKUP_DATE"
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    log_message "=== Starting NAS Backup Process ==="
    log_message "Script Version: 2.0"
    log_message "Start Time: $start_time"
    
    # Pre-flight checks
    check_lock
    
    # Check available disk space (minimum 1GB free)
    # Intelligent space check with cleanup and estimation
    if ! ./nas-space-manager.sh check; then
        log_message "ERROR: Space check failed - insufficient storage or quota"
        exit 1
    fi
    
    # Test rclone connection
    if ! test_rclone; then
        log_message "ERROR: Cannot connect to Google Drive. Aborting backup."
        exit 1
    fi
    
    # Initialize counters
    local success_count=0
    local total_backups=0
    
    # Backup Photo Collection
    if [ -d "$PHOTOS_PATH" ]; then
        log_message "Starting backup: Photo Collection ($(du -sh "$PHOTOS_PATH" | cut -f1))"
        total_backups=$((total_backups + 1))
        
        if backup_with_retry "$PHOTOS_PATH" "$GDRIVE_PHOTOS" "$PHOTOS_BANDWIDTH" 2; then
            success_count=$((success_count + 1))
            # Verify backup integrity
            verify_backup "$PHOTOS_PATH" "$GDRIVE_PHOTOS"
        fi
    else
        log_message "WARN: Photo collection directory not found: $PHOTOS_PATH"
    fi
    
    # Backup OpenMediaVault configuration
    log_message "Backing up OMV configuration..."
    total_backups=$((total_backups + 1))
    
    if sudo omv-confdbadm read conf.system.general > "$OMV_CONFIG_PATH" 2>/dev/null; then
        if backup_with_retry "$OMV_CONFIG_PATH" "$GDRIVE_CONFIG/" "$CONFIG_BANDWIDTH" 1; then
            success_count=$((success_count + 1))
        fi
        rm -f "$OMV_CONFIG_PATH"
    else
        log_message "WARN: Could not export OMV configuration"
    fi
    
    # Backup Docker configurations
    if [ -d "$DOCKER_CONFIG_PATH" ]; then
        log_message "Starting backup: Docker configurations ($(du -sh "$DOCKER_CONFIG_PATH" | cut -f1))"
        total_backups=$((total_backups + 1))
        
        if backup_with_retry "$DOCKER_CONFIG_PATH" "$GDRIVE_DOCKER" "$DOCKER_BANDWIDTH" 1; then
            success_count=$((success_count + 1))
        fi
    else
        log_message "WARN: Docker configuration directory not found: $DOCKER_CONFIG_PATH"
    fi
    
    # Backup system information
    log_message "Backing up system information..."
    total_backups=$((total_backups + 1))
    backup_system_info
    success_count=$((success_count + 1))
    
    # Generate final report
    generate_report "$start_time"
    
    # Send notification
    if [ $success_count -eq $total_backups ]; then
        send_notification "SUCCESS" "All $total_backups backup tasks completed successfully"
        log_message "SUCCESS: All backup tasks completed ($success_count/$total_backups)"
    else
        send_notification "PARTIAL" "Backup completed with warnings ($success_count/$total_backups successful)"
        log_message "WARN: Backup completed with warnings ($success_count/$total_backups successful)"
    fi
    
    # Cleanup old log files (keep last 30 days)
    find "$(dirname "$LOG_FILE")" -name "backup.log.*" -mtime +30 -delete 2>/dev/null
    
    log_message "=== Backup Process Finished ==="
}

# Script usage information
usage() {
    echo "NAS Backup Script v2.0"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -t, --test     Test mode (verify connections only)"
    echo "  -v, --verify   Verify existing backups without uploading"
    echo "  -f, --force    Force backup even if another process is running"
    echo ""
    echo "Configuration:"
    echo "  Edit paths and settings at the top of this script"
    echo "  Ensure rclone is configured with 'gdrive' remote"
    echo ""
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    -t|--test)
        log_message "=== Test Mode ==="
        test_rclone
        exit $?
        ;;
    -v|--verify)
        log_message "=== Verification Mode ==="
        verify_backup "$PHOTOS_PATH" "$GDRIVE_PHOTOS"
        verify_backup "$DOCKER_CONFIG_PATH" "$GDRIVE_DOCKER"
        exit 0
        ;;
    -f|--force)
        rm -f "$LOCK_FILE"
        ;;
    "")
        # Normal execution
        ;;
    *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
esac

# Run main backup process
main
