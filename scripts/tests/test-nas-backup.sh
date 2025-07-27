#!/bin/bash
# Pi NAS Backup System - Comprehensive Testing Script
# Tests all backup components and services for Raspberry Pi NAS setup

set -e

# Configuration
DOCKER_PATH="/home/YOUR_USERNAME/docker"
BACKUP_SCRIPT_PATH="/usr/local/bin/configured/raspberry-pi-nas-backup/scripts/backup"
LOG_DIR="/home/YOUR_USERNAME/logs"
TEST_DIR="/tmp/nas_backup_test_$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="$LOG_DIR/nas_test_$(date +%Y%m%d_%H%M%S).log"

echo_status() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

echo_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$LOG_FILE"
}

echo_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

echo_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as correct user (not root)
if [ "$EUID" -eq 0 ]; then
    echo_error "Do not run as root. Run as your regular Pi user."
    exit 1
fi

echo_status "=== RASPBERRY PI NAS BACKUP SYSTEM TEST SUITE ==="
echo_status "Started at: $(date)"

# Create test directory and log directory
mkdir -p "$TEST_DIR"
mkdir -p "$LOG_DIR"

# Test 1: System Health Check
echo_status "Test 1: Checking system health..."

# Check CPU temperature
if command -v vcgencmd &> /dev/null; then
    CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    if (( $(echo "$CPU_TEMP > 80" | bc -l) )); then
        echo_warning "CPU temperature high: ${CPU_TEMP}°C"
    else
        echo_success "CPU temperature normal: ${CPU_TEMP}°C"
    fi
else
    echo_warning "vcgencmd not available - cannot check CPU temperature"
fi

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
if (( $(echo "$MEM_USAGE > 85" | bc -l) )); then
    echo_warning "Memory usage high: ${MEM_USAGE}%"
else
    echo_success "Memory usage normal: ${MEM_USAGE}%"
fi

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
    echo_warning "Disk usage high: ${DISK_USAGE}%"
else
    echo_success "Disk usage normal: ${DISK_USAGE}%"
fi

# Test 2: Docker Service Health
echo_status "Test 2: Checking Docker services..."

if command -v docker &> /dev/null; then
    echo_success "Docker is installed"
    
    # Check if Docker daemon is running
    if systemctl is-active docker &> /dev/null; then
        echo_success "Docker service is running"
        
        # Check running containers
        RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null)
        if [ -n "$RUNNING_CONTAINERS" ]; then
            echo_success "Docker containers are running:"
            echo "$RUNNING_CONTAINERS" | tee -a "$LOG_FILE"
        else
            echo_warning "No Docker containers currently running"
        fi
        
        # Check specific services
        SERVICES=("plex" "immich" "portainer")
        for service in "${SERVICES[@]}"; do
            if docker ps --format "{{.Names}}" | grep -q "$service"; then
                echo_success "Service running: $service"
            else
                echo_warning "Service not running: $service"
            fi
        done
        
    else
        echo_error "Docker service is not running"
    fi
else
    echo_error "Docker is not installed"
fi

# Test 3: Docker Configuration Files
echo_status "Test 3: Checking Docker configurations..."

if [ -d "$DOCKER_PATH" ]; then
    echo_success "Docker configuration directory exists: $DOCKER_PATH"
    
    # Check for docker-compose files
    COMPOSE_FILES=$(find "$DOCKER_PATH" -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null)
    if [ -n "$COMPOSE_FILES" ]; then
        echo_success "Found docker-compose files:"
        echo "$COMPOSE_FILES" | tee -a "$LOG_FILE"
    else
        echo_warning "No docker-compose files found"
    fi
    
    # Check directory sizes
    DOCKER_SIZE=$(du -sh "$DOCKER_PATH" 2>/dev/null | cut -f1)
    echo_status "Docker configuration size: $DOCKER_SIZE"
    
else
    echo_error "Docker configuration directory not found: $DOCKER_PATH"
fi

# Test 4: Backup Script Verification
echo_status "Test 4: Checking backup scripts..."

if [ -d "$BACKUP_SCRIPT_PATH" ]; then
    echo_success "Backup script directory exists: $BACKUP_SCRIPT_PATH"
    
    # Check for backup scripts
    BACKUP_SCRIPTS=$(find "$BACKUP_SCRIPT_PATH" -name "*backup*.sh" 2>/dev/null)
    if [ -n "$BACKUP_SCRIPTS" ]; then
        echo_success "Found backup scripts:"
        for script in $BACKUP_SCRIPTS; do
            if [ -x "$script" ]; then
                echo_success "Executable: $(basename "$script")"
            else
                echo_warning "Not executable: $(basename "$script")"
            fi
        done
    else
        echo_warning "No backup scripts found"
    fi
    
else
    echo_error "Backup script directory not found: $BACKUP_SCRIPT_PATH"
fi

# Test 5: Cron Job Status
echo_status "Test 5: Checking backup scheduling..."
BACKUP_TIMERS=$(systemctl list-timers --no-pager 2>/dev/null | grep backup)
if [ -n "$BACKUP_TIMERS" ]; then
    echo_success "Backup timers configured:"
    echo "$BACKUP_TIMERS" | tee -a "$LOG_FILE"
    if echo "$BACKUP_TIMERS" | grep -q "daily-backup|weekly-full-backup"; then
        echo_success "EndeavourOS Nuclear Backup timers found"
    else
        echo_warning "No nuclear backup timers found"
    fi
else
    echo_warning "No backup timers configured"
fi
    echo "$CRON_JOBS" | tee -a "$LOG_FILE"
    
    # Check for backup-related cron jobs
    if echo "$CRON_JOBS" | grep -q "backup"; then
        echo_success "Backup cron jobs found"
    else
        echo_warning "No backup-related cron jobs found"
    fi

    echo_warning "No cron jobs configured"

# Test 6: Storage Mount Points
echo_status "Test 6: Checking storage mounts..."

# Check for common NAS mount points
MOUNT_POINTS=("/srv" "/mnt" "/media")
for mount in "${MOUNT_POINTS[@]}"; do
    if mountpoint -q "$mount" 2>/dev/null; then
        MOUNT_SIZE=$(df -h "$mount" | awk 'NR==2 {print $2}')
        MOUNT_USAGE=$(df -h "$mount" | awk 'NR==2 {print $5}')
        echo_success "Mount point active: $mount (Size: $MOUNT_SIZE, Usage: $MOUNT_USAGE)"
    else
        # Check if directory exists and has content
        if [ -d "$mount" ] && [ "$(ls -A "$mount" 2>/dev/null)" ]; then
            echo_status "Directory exists with content: $mount"
        fi
    fi
done

# Check for external drives
EXTERNAL_DRIVES=$(lsblk -f | grep -E "(sd|nvme)" | grep -v "SWAP" | wc -l)
echo_status "External drives detected: $EXTERNAL_DRIVES"

# Test 7: Network Connectivity
echo_status "Test 7: Testing network connectivity..."

# Check local network connectivity
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo_success "Internet connectivity working"
else
    echo_error "No internet connectivity"
fi

# Check if Pi is accessible on network
PI_IP=$(hostname -I | awk '{print $1}')
if [ -n "$PI_IP" ]; then
    echo_success "Pi IP address: $PI_IP"
else
    echo_error "No IP address assigned"
fi

# Test 8: Service Accessibility
echo_status "Test 8: Testing service accessibility..."

SERVICES_TO_TEST=(
    "32400:Plex"
    "2283:Immich" 
    "9000:Portainer"
    "22:SSH"
)

for service in "${SERVICES_TO_TEST[@]}"; do
    PORT=$(echo "$service" | cut -d':' -f1)
    NAME=$(echo "$service" | cut -d':' -f2)
    
    if nc -z localhost "$PORT" 2>/dev/null; then
        echo_success "Service accessible: $NAME (port $PORT)"
    else
        echo_warning "Service not accessible: $NAME (port $PORT)"
    fi
done

# Test 9: Log File Analysis
echo_status "Test 9: Analyzing backup logs..."

if [ -d "$LOG_DIR" ]; then
    RECENT_LOGS=$(find "$LOG_DIR" -name "*backup*" -mtime -7 2>/dev/null | wc -l)
    if [ "$RECENT_LOGS" -gt 0 ]; then
        echo_success "Found $RECENT_LOGS recent backup logs"
        
        # Check latest log for errors
        LATEST_LOG=$(find "$LOG_DIR" -name "*backup*" -mtime -7 -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [ -n "$LATEST_LOG" ]; then
            if grep -q -i "error\|failed\|failure" "$LATEST_LOG" 2>/dev/null; then
                echo_warning "Errors found in latest backup log: $LATEST_LOG"
            else
                echo_success "Latest backup log shows no errors"
            fi
        fi
    else
        echo_warning "No recent backup logs found"
    fi
else
    echo_warning "Log directory not found: $LOG_DIR"
fi

# Test 10: Backup Destination Verification
echo_status "Test 10: Verifying backup destinations..."

# Check for common backup directories
BACKUP_DIRS=("/backup" "/mnt/backup" "$HOME/backups" "$LOG_DIR/../backups")
BACKUP_FOUND=false

for backup_dir in "${BACKUP_DIRS[@]}"; do
    if [ -d "$backup_dir" ]; then
        BACKUP_SIZE=$(du -sh "$backup_dir" 2>/dev/null | cut -f1)
        BACKUP_FILES=$(find "$backup_dir" -type f 2>/dev/null | wc -l)
        echo_success "Backup directory found: $backup_dir (Size: $BACKUP_SIZE, Files: $BACKUP_FILES)"
        BACKUP_FOUND=true
    fi
done

if [ "$BACKUP_FOUND" = false ]; then
    echo_warning "No backup directories found in common locations"
fi

# Test 11: System Performance Check
echo_status "Test 11: System performance check..."

# Check load average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if (( $(echo "$LOAD_AVG > 2.0" | bc -l) )); then
    echo_warning "High system load: $LOAD_AVG"
else
    echo_success "System load normal: $LOAD_AVG"
fi

# Check uptime
UPTIME_DAYS=$(uptime | awk '{print $3}' | sed 's/,//')
echo_status "System uptime: $UPTIME_DAYS days"

# Check available space on important partitions
echo_status "Storage space analysis:"
df -h | grep -E "(/$|/home|/srv|/mnt)" | while read line; do
    echo_status "  $line"
done | tee -a "$LOG_FILE"

# Cleanup
rm -rf "$TEST_DIR"

# Summary
echo_status "=== TEST SUITE COMPLETE ==="
echo_status "Completed at: $(date)"
echo_status "Full test log: $LOG_FILE"

echo_status ""
echo_status "RASPBERRY PI NAS BACKUP SYSTEM STATUS:"

# Count passed/failed tests based on log
PASS_COUNT=$(grep -c "\[PASS\]" "$LOG_FILE" 2>/dev/null || echo "0")
WARN_COUNT=$(grep -c "\[WARN\]" "$LOG_FILE" 2>/dev/null || echo "0")
FAIL_COUNT=$(grep -c "\[FAIL\]" "$LOG_FILE" 2>/dev/null || echo "0")

echo_success "✓ Tests passed: $PASS_COUNT"
if [ "$WARN_COUNT" -gt 0 ]; then
    echo_warning "⚠ Warnings: $WARN_COUNT"
fi
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo_error "✗ Tests failed: $FAIL_COUNT"
fi

echo_status ""
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo_status "Your Pi NAS backup system is operational!"
else
    echo_status "Please address failed tests before relying on backups."
fi
echo_status "Run this test monthly to ensure continued reliability."
