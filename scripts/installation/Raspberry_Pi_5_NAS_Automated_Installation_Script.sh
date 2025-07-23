#!/bin/bash
# Pi 5 NAS Automated Installation Script
# Version: 1.0
# Description: Complete setup automation for Pi 5 NAS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/home/$(whoami)/nas_install.log"
CONFIG_FILE="$SCRIPT_DIR/install.conf"

# Default configuration
DEFAULT_TIMEZONE="America/New_York"
DEFAULT_USERNAME="YOUR_USERNAME"
DEFAULT_OMV_PASSWORD="openmediavault"

# Functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
}

# Check hardware compatibility
check_hardware() {
    info "Checking hardware compatibility..."
    
    # Check if running on Raspberry Pi 5
    local model=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
    if [[ $model != *"Raspberry Pi 5"* ]]; then
        warning "Not running on Raspberry Pi 5. Some features may not work."
    else
        success "Raspberry Pi 5 detected"
    fi
    
    # Check memory
    local memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local memory_gb=$((memory_kb / 1024 / 1024))
    if [ $memory_gb -lt 4 ]; then
        warning "Less than 4GB RAM detected. Consider upgrading for better performance."
    else
        success "${memory_gb}GB RAM detected"
    fi
    
    # Check for Penta HAT (PCIe SATA controller)
    if lspci | grep -q -i sata; then
        success "SATA controller detected (Penta HAT likely installed)"
    else
        warning "No SATA controller detected. Penta HAT may not be properly installed."
    fi
}

# System update and preparation
system_update() {
    info "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    info "Installing essential packages..."
    sudo apt install -y \
        curl wget git vim htop tree \
        lsb-release apt-transport-https \
        ca-certificates gnupg2 software-properties-common \
        smartmontools hdparm iotop iftop \
        build-essential python3-pip \
        bc
    
    success "System updated and essential packages installed"
}

# Configure system settings
configure_system() {
    info "Configuring system settings..."
    
    # Enable required device tree overlays
    if ! grep -q "dtparam=pciex1" /boot/firmware/config.txt; then
        info "Adding PCIe support for Penta HAT..."
        sudo tee -a /boot/firmware/config.txt << EOF

# Radaxa Penta HAT support
dtparam=pciex1
dtoverlay=pcie-32bit-dma

# Enable hardware random number generator
dtparam=random=on

# GPU memory split (minimal for headless)
gpu_mem=64
EOF
        success "PCIe support enabled"
    fi
    
    # Increase file limits
    info "Configuring system limits..."
    sudo tee -a /etc/security/limits.conf << EOF
$(whoami) soft nofile 65536
$(whoami) hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF
    
    # Network optimization
    info "Optimizing network settings..."
    sudo tee -a /etc/sysctl.conf << EOF

# Network performance tuning for NAS
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.core.netdev_max_backlog = 5000

# Storage optimization
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
vm.swappiness = 10
EOF
    
    success "System configuration completed"
}

# Install OpenMediaVault
install_omv() {
    info "Installing OpenMediaVault..."
    
    # Download and run OMV installer
    wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
    
    success "OpenMediaVault installation completed"
    warning "System will reboot after OMV installation. Re-run this script after reboot to continue."
}

# Install Docker
install_docker() {
    info "Installing Docker..."
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add user to docker group
    sudo usermod -aG docker $(whoami)
    
    # Install Docker Compose
    sudo apt install -y docker-compose-plugin
    
    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    success "Docker installed successfully"
    warning "You may need to log out and back in for Docker group membership to take effect"
}

# Install Portainer
install_portainer() {
    info "Setting up Portainer configuration..."
    
    # Create Portainer directory
    mkdir -p /home/$(whoami)/docker/portainer
    
    # Note: Portainer docker-compose.yml should be copied from the repository
    # For now, we'll use the simple docker run approach
    
    # Create Portainer volume
    docker volume create portainer_data
    
    # Run Portainer container
    docker run -d \
        -p 8000:8000 \
        -p 9000:9000 \
        --name=portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    
    success "Portainer installed and running on port 9000"
    info "For docker-compose setup, copy docker/portainer/docker-compose.yml from repository"
}

# Setup directory structure
setup_directories() {
    info "Setting up directory structure..."
    
    # Create main directories
    mkdir -p /home/$(whoami)/{scripts,logs,docker}
    mkdir -p /home/$(whoami)/scripts/{backup,maintenance,monitoring}
    
    # Create application directories
    mkdir -p /home/$(whoami)/docker/{plex,immich,portainer}
    
    success "Directory structure created"
}

# Install additional tools
install_tools() {
    info "Installing additional tools..."
    
    # Install rclone for backups
    sudo apt install -y rclone
    
    # Install iperf3 for network testing
    sudo apt install -y iperf3
    
    # Install monitoring tools
    sudo apt install -y nmon dstat
    
    success "Additional tools installed"
}

# Configure firewall
configure_firewall() {
    info "Configuring firewall..."
    
    # Install UFW if not present
    sudo apt install -y ufw
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow essential services
    sudo ufw allow 22/tcp      # SSH
    sudo ufw allow 80/tcp      # OMV Web Interface
    sudo ufw allow 443/tcp     # HTTPS
    sudo ufw allow 9000/tcp    # Portainer
    sudo ufw allow 32400/tcp   # Plex
    sudo ufw allow 2283/tcp    # Immich
    
    # Enable firewall
    sudo ufw --force enable
    
    success "Firewall configured and enabled"
}

# Create initial scripts
create_scripts() {
    info "Creating utility scripts..."
    
    # System health check script
    cat > /home/$(whoami)/scripts/health_check.sh << 'EOF'
#!/bin/bash
# System health check script

echo "=== Pi 5 NAS Health Check ==="
echo "Timestamp: $(date)"
echo "Temperature: $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')"
echo "Throttling: $(vcgencmd get_throttled 2>/dev/null || echo 'N/A')"
echo "Memory Usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Disk Usage:"
df -h | grep -E "(srv|boot|/$)"
echo "Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Docker not running"
EOF
    
    chmod +x /home/$(whoami)/scripts/health_check.sh
    
    # Network test script
    cat > /home/$(whoami)/scripts/network_test.sh << 'EOF'
#!/bin/bash
# Network performance test script

echo "=== Network Performance Test ==="
echo "Interface Status:"
ip addr show eth0 | grep -E "(inet|state)"

echo "Network Speed:"
ethtool eth0 2>/dev/null | grep -E "(Speed|Duplex)" || echo "ethtool not available"

echo "Ping Test:"
ping -c 5 8.8.8.8

if command -v iperf3 > /dev/null; then
    echo "Starting iperf3 server for 30 seconds..."
    echo "Run 'iperf3 -c $(hostname -I | awk '{print $1}') -t 10' from another device"
    timeout 30 iperf3 -s
fi
EOF
    
    chmod +x /home/$(whoami)/scripts/network_test.sh
    
    success "Utility scripts created"
}

# Print summary and next steps
print_summary() {
    echo
    success "=== Installation Summary ==="
    info "Base system configured with:"
    echo "  ✓ System updates and essential packages"
    echo "  ✓ PCIe support for Penta HAT"
    echo "  ✓ Network and storage optimizations"
    echo "  ✓ Docker and Portainer"
    echo "  ✓ Firewall configuration"
    echo "  ✓ Utility scripts"
    
    if systemctl is-active --quiet openmediavault-engined; then
        echo "  ✓ OpenMediaVault (running)"
    else
        echo "  ⚠ OpenMediaVault (installation completed, may need reboot)"
    fi
    
    echo
    info "=== Next Steps ==="
    echo "1. Reboot the system: sudo reboot"
    echo "2. Access OMV web interface: http://$(hostname -I | awk '{print $1}')"
    echo "3. Access Portainer: http://$(hostname -I | awk '{print $1}'):9000"
    echo "4. Configure storage drives in OMV"
    echo "5. Setup SnapRAID for data protection"
    echo "6. Deploy Plex and Immich using provided docker-compose files"
    echo "7. Configure automated backups"
    echo
    info "=== Useful Commands ==="
    echo "Health check: ~/scripts/health_check.sh"
    echo "Network test: ~/scripts/network_test.sh"
    echo "View logs: tail -f $LOG_FILE"
    echo
    warning "Remember to:"
    echo "- Change default OMV password (admin/openmediavault)"
    echo "- Configure SSH keys for secure access"
    echo "- Setup proper drive partitioning and formatting"
    echo "- Configure automated backups"
}

# Main installation function
main() {
    clear
    echo "======================================================"
    echo "   Raspberry Pi 5 NAS Automated Installation"
    echo "======================================================"
    echo
    
    # Check prerequisites
    check_root
    
    # Log start
    log "Starting Pi 5 NAS installation"
    
    # Hardware check
    check_hardware
    
    # System update
    system_update
    
    # System configuration
    configure_system
    
    # Directory setup
    setup_directories
    
    # Install components
    install_docker
    install_portainer
    install_tools
    
    # Security configuration
    configure_firewall
    
    # Create utility scripts
    create_scripts
    
    # Install OMV (this may require reboot)
    if ! systemctl is-active --quiet openmediavault-engined; then
        read -p "Install OpenMediaVault now? This will require a reboot. (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_omv
            log "OMV installation initiated"
            return
        else
            warning "OMV installation skipped. Install manually later."
        fi
    else
        success "OpenMediaVault already installed"
    fi
    
    # Print summary
    print_summary
    
    log "Pi 5 NAS installation completed successfully"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi