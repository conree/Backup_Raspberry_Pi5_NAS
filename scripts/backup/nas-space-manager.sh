#!/bin/bash
# Pi NAS Backup Space Management Script
# Intelligent space monitoring and cleanup for Raspberry Pi NAS backups

set -e

# Configuration
BACKUP_DESTINATIONS="/path/to/local/backup/destination /home/YOUR_USERNAME/backups"
MIN_FREE_SPACE_GB=50  # Keep at least 50GB free (adjust for Pi storage)
KEEP_RECENT_BACKUPS=5  # Always keep the 5 most recent backup sets
LOG_RETENTION_DAYS=30  # Keep logs for 30 days

# Google Drive space management
GDRIVE_QUOTA_WARNING_GB=100  # Warn when less than 100GB free on Google Drive
GDRIVE_REMOTE="gdrive:"

# Function to get available space in GB
get_available_space_gb() {
    local path=$1
    if [ -d "$path" ]; then
        df -BG "$path" | awk 'NR==2 {gsub(/G/, "", $4); print $4}'
    else
        echo "0"
    fi
}

# Function to check Google Drive quota
check_gdrive_quota() {
    echo "[INFO] Checking Google Drive quota..."
    
    if command -v rclone >/dev/null 2>&1; then
        local quota_info=$(rclone about "$GDRIVE_REMOTE" 2>/dev/null | grep -E "Total|Free|Used" || echo "")
        
        if [ -n "$quota_info" ]; then
            echo "[INFO] Google Drive quota:"
            echo "$quota_info" | while read line; do
                echo "[INFO]   $line"
            done
        else
            echo "[WARN] Could not retrieve Google Drive quota information"
            return 1
        fi
    else
        echo "[WARN] rclone not found - cannot check Google Drive quota"
        return 1
    fi
    
    return 0
}

# Function to estimate backup size (separate info and calculation)
estimate_backup_size_gb() {
    local total_size_kb=0
    
    # Check photos directory size (if it exists)
    if [ -d "/srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333/photo_collection" ]; then
        local photos_size=$(du -sk "/srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333/photo_collection" 2>/dev/null | awk '{print $1}' || echo "0")
        total_size_kb=$((total_size_kb + photos_size))
    fi
    
    # Check docker config size (if it exists)
    if [ -d "/home/YOUR_USERNAME/docker" ]; then
        local docker_size=$(du -sk "/home/YOUR_USERNAME/docker" 2>/dev/null | awk '{print $1}' || echo "0")
        total_size_kb=$((total_size_kb + docker_size))
    fi
    
    # Convert KB to GB and add 20% buffer (using integer arithmetic)
    local estimated_gb=$((total_size_kb / 1024 / 1024))
    local buffered_gb=$((estimated_gb + estimated_gb / 5 + 2))  # +20% + 2GB minimum
    
    echo "$buffered_gb"
}

# Function to show backup size info (separate from calculation)
show_backup_size_info() {
    echo "[INFO] Estimating backup size..."
    
    # Check photos directory size (if it exists)
    if [ -d "/srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333/photo_collection" ]; then
        local photos_size=$(du -sk "/srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333/photo_collection" 2>/dev/null | awk '{print $1}' || echo "0")
        local photos_gb=$((photos_size / 1024 / 1024))
        echo "[INFO]   Photos: ${photos_gb}GB"
    else
        echo "[INFO]   Photos directory not found - assuming 0GB"
    fi
    
    # Check docker config size (if it exists)
    if [ -d "/home/YOUR_USERNAME/docker" ]; then
        local docker_size=$(du -sk "/home/YOUR_USERNAME/docker" 2>/dev/null | awk '{print $1}' || echo "0")
        local docker_gb=$((docker_size / 1024 / 1024))
        echo "[INFO]   Docker configs: ${docker_gb}GB"
    else
        echo "[INFO]   Docker config directory not found - assuming 0GB"
    fi
}

# Function to clean up old backup logs
cleanup_old_logs() {
    echo "[INFO] Cleaning up old log files..."
    
    for log_dir in "/home/YOUR_USERNAME/logs" "/var/log/pi-nas-backup"; do
        if [ -d "$log_dir" ]; then
            local cleaned_count=$(find "$log_dir" -name "backup*.log*" -mtime +$LOG_RETENTION_DAYS -delete -print 2>/dev/null | wc -l)
            if [ "$cleaned_count" -gt 0 ]; then
                echo "[INFO]   Removed $cleaned_count old log files from $log_dir"
            fi
        else
            echo "[INFO]   Log directory $log_dir does not exist"
        fi
    done
}

# Function to clean up failed backup attempts
cleanup_failed_backups() {
    echo "[INFO] Checking for failed backup artifacts to clean up..."
    
    # Clean up any temporary files or incomplete uploads
    for backup_dest in $BACKUP_DESTINATIONS; do
        if [ -d "$backup_dest" ]; then
            # Remove any .tmp files older than 1 day
            local tmp_cleaned=$(find "$backup_dest" -name "*.tmp" -mtime +1 -delete -print 2>/dev/null | wc -l)
            if [ "$tmp_cleaned" -gt 0 ]; then
                echo "[INFO]   Removed $tmp_cleaned temporary files from $backup_dest"
            fi
        else
            echo "[INFO]   Backup destination $backup_dest does not exist"
        fi
    done
}

# Function to check space before backup
check_space_before_backup() {
    # Show backup size information first
    show_backup_size_info
    
    # Get the calculated backup size
    local estimated_backup_size=$(estimate_backup_size_gb)
    local space_check_passed=true
    
    echo "[INFO] Space check before Pi NAS backup:"
    echo "[INFO]   Estimated backup size: ${estimated_backup_size}GB"
    echo "[INFO]   Minimum free space required: ${MIN_FREE_SPACE_GB}GB"
    
    # Check local storage space
    for backup_dest in $BACKUP_DESTINATIONS; do
        local dest_parent=$(dirname "$backup_dest")
        if [ -d "$dest_parent" ]; then
            local available_space=$(get_available_space_gb "$dest_parent")
            local total_needed=$((MIN_FREE_SPACE_GB + estimated_backup_size))
            
            echo "[INFO]   Available space on $dest_parent: ${available_space}GB"
            echo "[INFO]   Total space needed: ${total_needed}GB"
            
            if [ "$available_space" -lt "$total_needed" ]; then
                echo "[WARN] Insufficient space on $dest_parent"
                space_check_passed=false
            fi
        else
            echo "[INFO]   Parent directory $dest_parent does not exist"
        fi
    done
    
    # Check Google Drive quota (but don't fail on it)
    if ! check_gdrive_quota; then
        echo "[WARN] Google Drive quota check failed or low space detected"
    fi
    
    if [ "$space_check_passed" = false ]; then
        echo "[WARN] Space check failed - consider cleanup or adding storage"
        echo "[INFO] Running automatic cleanup..."
        cleanup_old_logs
        cleanup_failed_backups
        
        echo "[INFO] Space check completed with warnings"
        return 1
    else
        echo "[INFO] Space check passed. Proceeding with backup."
    fi
    
    return 0
}

# Function to show current backup inventory
show_backup_inventory() {
    echo "[INFO] Current Pi NAS backup inventory:"
    
    for backup_dest in $BACKUP_DESTINATIONS; do
        if [ -d "$backup_dest" ]; then
            echo "[INFO] Local backup destination: $backup_dest"
            local total_size=$(du -sh "$backup_dest" 2>/dev/null | awk '{print $1}' || echo "0")
            local file_count=$(find "$backup_dest" -type f 2>/dev/null | wc -l)
            echo "[INFO]   Total size: $total_size"
            echo "[INFO]   File count: $file_count"
        else
            echo "[INFO] Backup destination $backup_dest does not exist"
        fi
    done
    
    # Show Google Drive info if available
    if command -v rclone >/dev/null 2>&1; then
        echo "[INFO] Google Drive backup destinations:"
        for gdrive_path in "NAS_Backup/PhotoCollection" "NAS_Backup/Config" "NAS_Backup/Docker" "NAS_Backup/System"; do
            local file_count=$(rclone ls "$GDRIVE_REMOTE$gdrive_path" 2>/dev/null | wc -l || echo "0")
            echo "[INFO]   $gdrive_path: $file_count files"
        done
    else
        echo "[INFO] rclone not available for Google Drive inventory"
    fi
}

# Function to perform comprehensive cleanup
perform_cleanup() {
    echo "[INFO] Performing comprehensive Pi NAS backup cleanup..."
    
    cleanup_old_logs
    cleanup_failed_backups
    
    echo "[INFO] Cleanup completed."
}

# Main execution
case "${1:-check}" in
    "check")
        check_space_before_backup
        ;;
    "cleanup")
        perform_cleanup
        ;;
    "inventory")
        show_backup_inventory
        ;;
    "quota")
        check_gdrive_quota
        ;;
    *)
        echo "Usage: $0 {check|cleanup|inventory|quota}"
        echo "  check    - Check space and cleanup if needed before backup"
        echo "  cleanup  - Force cleanup of old logs and failed backups"
        echo "  inventory - Show current backup inventory"
        echo "  quota    - Check Google Drive quota"
        exit 1
        ;;
esac
