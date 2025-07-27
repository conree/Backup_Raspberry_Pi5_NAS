# Raspberry Pi 5 NAS Backup System - Complete Installation Guide 🍓🛡️

> **Complete hardware setup, software installation, and backup system configuration for the Pi 5 NAS**

## 📋 Table of Contents

1. [Hardware Setup](#hardware-setup)
2. [Software Installation](#software-installation) 
3. [NVMe Boot Drive Upgrade](#nvme-boot-drive-upgrade)
4. [Backup System Configuration](#backup-system-configuration)
5. [Testing and Verification](#testing-and-verification)

---

# Hardware Setup

## 📦 Bill of Materials

### Required Components

| Component | Model/Specification | Price Range | Notes |
|-----------|-------------------|-------------|-------|
| **Single Board Computer** | Raspberry Pi 5 (8GB) | $80 | 4GB version works but 8GB recommended |
| **SATA Expansion** | Radaxa Penta HAT | $60-70 | 5-bay SATA interface for Pi 5 |
| **Storage Drives** | 4x 2TB SATA SSDs | $200-300 | TeamGroup, Samsung, or similar |
| **Boot Drive** | M.2 NVMe SSD + USB Adapter | $50-80 | 256GB+ recommended |
| **Power Supply** | Official Pi 5 PSU (5V/5A) | $15 | 27W minimum required |
| **Networking** | Cat 8 Ethernet Cables | $20 | Cat 6 minimum, Cat 8 future-proof |
| **Case** | Compatible Pi 5 Case | $30-50 | Must accommodate Penta HAT |
| **Cooling** | Active cooling solution | $15-25 | Fan + heatsinks recommended |

**Total Cost: ~$470-640 USD**

### Optional Components

| Component | Purpose | Price Range |
|-----------|---------|-------------|
| UPS (Uninterruptible Power Supply) | Power protection | $100-200 |
| Network Switch | Multiple device connections | $50-100 |
| External Backup Drive | Local backup redundancy | $100-150 |

## 🔧 Assembly Instructions

### 1. Prepare the Raspberry Pi 5

#### Initial Inspection
```bash
# Verify Pi 5 model and revision
cat /proc/cpuinfo | grep -E "(Model|Revision)"
```

#### GPIO Header Check
- Ensure 40-pin GPIO header is properly seated
- Check for any bent or damaged pins
- Verify Pi 5 specific pinout compatibility

### 2. Install Radaxa Penta HAT

#### Pre-installation Steps
1. **Power down** the Pi completely
2. **Disconnect all cables** including power
3. **Ground yourself** to prevent static discharge

#### Physical Installation
```bash
# 1. Align the Penta HAT with GPIO header
# 2. Press down firmly and evenly
# 3. Secure with provided standoffs/screws
# 4. Connect SATA power cable to HAT
```

#### Enable PCIe Support
Add to `/boot/firmware/config.txt`:
```bash
# Enable PCIe for Radaxa Penta HAT
dtparam=pciex1
dtoverlay=pcie-32bit-dma

# Optional: Increase PCIe speed (test stability)
# dtparam=pciex1_gen=2
```

### 3. Install Storage Drives

#### SATA SSD Installation
1. **Prepare SSDs**: Remove from anti-static packaging
2. **Connect SATA data cables**: Firmly seat connectors
3. **Connect power**: Use provided SATA power splitters
4. **Secure drives**: Mount in case or external enclosure

#### Verify Detection
```bash
# Check drive detection
lsblk
dmesg | grep -i sata

# Expected output: sda, sdb, sdc, sde devices
# Note: sdd might be reserved for boot drive
```

### 4. Boot Drive Setup

#### M.2 NVMe + USB Adapter
```bash
# 1. Install NVMe SSD in USB 3.0 adapter
# 2. Connect to Pi 5 USB 3.0 port (blue)
# 3. Verify detection
lsusb
lsblk | grep -E "(nvme|sda)"
```

#### Performance Verification
```bash
# Test USB 3.0 speed
sudo hdparm -tT /dev/sda
# Expected: >100 MB/sec sustained reads
```

## 🌡️ Thermal Management

### Cooling Requirements

#### CPU Temperature Monitoring
```bash
# Check current temperature
vcgencmd measure_temp

# Continuous monitoring
watch -n 1 vcgencmd measure_temp
```

#### Cooling Solutions
1. **Active Cooling**: Fan + heatsinks (recommended)
2. **Passive Cooling**: Large heatsinks only
3. **Case Cooling**: Ensure adequate airflow

#### Temperature Targets
- **Idle**: <45°C
- **Load**: <65°C  
- **Critical**: <75°C (throttling begins at 80°C)

### Power Management

#### Power Requirements
```bash
# Monitor power consumption
vcgencmd get_throttled
# 0x0 = no throttling, other values indicate power issues
```

#### Power Supply Specifications
- **Minimum**: 5V/3A (15W)
- **Recommended**: 5V/5A (25W) - Official Pi 5 PSU
- **With full load**: 5V/6A (30W) for safety margin

## 🔌 Connectivity Setup

### Network Configuration

#### Ethernet Connection
```bash
# Verify Gigabit link
ethtool eth0
# Look for: Speed: 1000Mb/s, Duplex: Full

# Test network performance
iperf3 -c [router_ip] -t 30
```

#### Network Optimization
```bash
# Add to /etc/sysctl.conf for performance
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
```

### USB Port Usage

#### USB 3.0 Allocation
- **Port 1**: Boot drive (M.2 NVMe adapter)
- **Port 2**: Available for external backup
- **USB 2.0 ports**: Keyboard, mouse, dongles

#### USB Performance Notes
- USB 3.0 and Gigabit Ethernet **share bandwidth**
- Maximum combined throughput: ~350-400 MB/sec
- Boot from USB 3.0 recommended over microSD

## 🧪 Hardware Testing

### Initial Hardware Verification

#### Complete System Test
```bash
#!/bin/bash
# hardware_test.sh - Comprehensive hardware validation

echo "=== Pi 5 NAS Hardware Test ==="

# Check CPU info
echo "CPU Information:"
cat /proc/cpuinfo | grep -E "(Model|processor)"

# Check memory
echo -e "\nMemory Information:"
free -h

# Check storage devices
echo -e "\nStorage Devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Check network interface
echo -e "\nNetwork Interface:"
ip addr show eth0

# Check temperature
echo -e "\nCPU Temperature:"
vcgencmd measure_temp

# Check throttling status
echo -e "\nThrottling Status:"
vcgencmd get_throttled

# Check Penta HAT detection
echo -e "\nSATA Controllers:"
lspci | grep -i sata

echo -e "\n=== Test Complete ==="
```

#### Storage Performance Test
```bash
#!/bin/bash
# storage_test.sh - Test individual drive performance

for drive in sda sdb sdc sde; do
    if [ -e "/dev/$drive" ]; then
        echo "Testing /dev/$drive:"
        sudo hdparm -tT /dev/$drive
        echo "---"
    fi
done
```

### Burn-in Testing

#### 24-Hour Stress Test
```bash
# Install stress testing tools
sudo apt install stress-ng hdparm

# CPU stress test (run in background)
stress-ng --cpu 4 --timeout 24h &

# Storage stress test for each drive
for drive in sda sdb sdc sde; do
    if [ -e "/dev/$drive" ]; then
        # Read test (safe, non-destructive)
        sudo dd if=/dev/$drive of=/dev/null bs=1M count=1000 &
    fi
done

# Monitor temperatures during test
while true; do
    echo "$(date): $(vcgencmd measure_temp)"
    sleep 60
done
```

## 🔍 Troubleshooting Hardware Issues

### Common Problems

#### Penta HAT Not Detected
```bash
# Check PCIe configuration
dmesg | grep -i pcie
lspci | grep -i sata

# Verify config.txt settings
grep -E "(pciex1|pcie)" /boot/firmware/config.txt
```

#### Drive Detection Issues
```bash
# Check SATA connections
dmesg | grep -i ata
cat /proc/partitions

# Verify power connections
# Ensure SATA power cable properly connected
```

#### Thermal Throttling
```bash
# Check throttling events
vcgencmd get_throttled
# 0x50000 = previously throttled
# 0x50005 = currently throttled

# Improve cooling:
# 1. Add/upgrade fan
# 2. Improve case ventilation
# 3. Check thermal paste application
```

#### Power Supply Issues
```bash
# Check for under-voltage
vcgencmd get_throttled
# 0x50001 = under-voltage detected

# Solutions:
# 1. Use official Pi 5 PSU
# 2. Check cable connections
# 3. Use shorter/thicker USB-C cable
```

### Hardware Compatibility Matrix

| Component Type | Tested Compatible | Notes |
|----------------|------------------|-------|
| **SSD Brands** | Samsung EVO, TeamGroup, Crucial | Avoid QLC NAND for reliability |
| **M.2 Adapters** | UGREEN, Sabrent USB 3.0 | Ensure USB 3.0 support |
| **Cases** | Argon NEO 5, Geekworm P5 | Must accommodate Penta HAT |
| **Power Supplies** | Official Pi 5 PSU, Anker 30W | 5V/5A minimum requirement |
| **Cooling** | Noctua 40mm, Arctic P4 | PWM control preferred |

## 📋 Pre-Software Checklist

Before proceeding to software installation:

- [ ] All drives detected (`lsblk` shows sda, sdb, sdc, sde)
- [ ] Penta HAT recognized (`lspci` shows SATA controller)
- [ ] Network connection stable (Gigabit link established)
- [ ] Temperatures within normal range (<50°C idle)
- [ ] No throttling detected (`vcgencmd get_throttled` = 0x0)
- [ ] Boot drive performs adequately (>100 MB/sec)
- [ ] Power supply stable (no under-voltage warnings)

**Next Step**: Proceed to [Software Installation Guide](software-installation.md)
---

# Software Installation

## 🏁 Pre-Installation Setup

### 1. Raspberry Pi OS Installation

#### Download and Flash
```bash
# Download Raspberry Pi Imager
# Flash "Raspberry Pi OS (64-bit)-Not the desktop version" to microSD
# Enable SSH in advanced options
# Set username: YOUR_USERNAME (or your preference)
# Configure WiFi (optional, Ethernet recommended)
```

#### First Boot Configuration
```bash
# SSH into the Pi
ssh YOUR_USERNAME@[pi-ip-address]

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git vim htop tree lsb-release
```

### 2. System Preparation

#### Enable Required Features
```bash
# Add to /boot/firmware/config.txt
sudo tee -a /boot/firmware/config.txt << EOF

# Radaxa Penta HAT support
dtparam=pciex1
dtoverlay=pcie-32bit-dma

# Enable hardware random number generator
dtparam=random=on

# GPU memory split (minimal for headless)
gpu_mem=64
EOF
```

#### Configure System Limits
```bash
# Increase file limits for NAS usage
sudo tee -a /etc/security/limits.conf << EOF
YOUR_USERNAME soft nofile 65536
YOUR_USERNAME hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF
```

#### Network Optimization
```bash
# Optimize network performance
sudo tee -a /etc/sysctl.conf << EOF
# Network performance tuning
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.core.netdev_max_backlog = 5000
EOF
```

## 🗄️ OpenMediaVault Installation

### Automated Installation
```bash
# Download and run OMV installation script
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash

# Reboot after installation
sudo reboot
```

### Post-Installation Configuration

#### Access Web Interface
```bash
# Default credentials:
# URL: http://[pi-ip-address]
# Username: admin
# Password: openmediavault
```

#### Initial OMV Setup
1. **Change admin password** (System → General Settings → Web Administrator Password)
2. **Set timezone** (System → Date & Time)
3. **Configure network** (Network → Interfaces)
4. **Enable SSH** (Services → SSH)

### Storage Configuration

#### Detect Storage Devices
```bash
# In OMV Web Interface:
# Storage → Disks → Scan for new devices
# Verify all SSDs are detected
```

#### Create File Systems
```bash
# Storage → File Systems → Create
# Select each SSD and format as EXT4
# Label drives: NAS_DRIVE_1, NAS_DRIVE_2, etc.
```

## 🛡️ SnapRAID Setup

### Install SnapRAID Plugin
```bash
# In OMV Web Interface:
# System → Plugins → openmediavault-snapraid
# Install and enable plugin
```

### Configure SnapRAID Array

#### Create Array Configuration
```bash
# Services → SnapRAID → Arrays
# Create new array: "nas_array"
# Add drives:
#   - Data drives: 3x SSDs for content
#   - Parity drive: 1x SSD for protection
```

#### Drive Assignment Example
```bash
# Recommended layout:
# sda (NAS_DRIVE_1) → Data drive (movies)
# sdb (NAS_DRIVE_2) → Data drive (music)  
# sdc (NAS_DRIVE_3) → Data drive (photos/tv)
# sde (NAS_DRIVE_4) → Parity drive
```

#### Configure Content Files
```bash
# Services → SnapRAID → Drives
# Enable content files on each data drive
# Location: /srv/dev-disk-by-uuid-[uuid]/snapraid.content
```

### SnapRAID Schedule Configuration
```bash
# Services → SnapRAID → Scheduled Jobs
# Configure weekly scrub:
#   - Execute: Weekly
#   - Day of week: Sunday
#   - Hour: 3 AM
#   - Percentage: 12%
```

## 🐳 Docker Installation

### Install Docker Engine
```bash
# Download and install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker YOUR_USERNAME

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Logout and login to apply group changes
```

### Install Docker Compose
```bash
# Install Docker Compose
sudo apt install -y docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### Configure Docker Storage
```bash
# Create docker directory on data drive
sudo mkdir -p /srv/dev-disk-by-uuid-[uuid]/docker
sudo chown YOUR_USERNAME:YOUR_USERNAME /srv/dev-disk-by-uuid-[uuid]/docker

# Create symlink to home directory
ln -sf /srv/dev-disk-by-uuid-[uuid]/docker /home/YOUR_USERNAME/docker
```

## 🔧 Portainer Installation

### Deploy Portainer
```bash
# Create volume for Portainer data
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
```

### Access Portainer
```bash
# Web interface: http://[pi-ip-address]:9000
# Create admin user on first access
# Configure local Docker environment
```

## 🎬 Plex Media Server Setup

### Create Directory Structure
```bash
# Create media directories
mkdir -p /home/YOUR_USERNAME/docker/plex/{config,transcode}
mkdir -p /srv/dev-disk-by-uuid-[movies-drive-uuid]/movies
mkdir -p /srv/dev-disk-by-uuid-[tv-drive-uuid]/tvseries
mkdir -p /srv/dev-disk-by-uuid-[music-drive-uuid]/music
```

### Plex Docker Compose
```yaml
# /home/YOUR_USERNAME/docker/plex/docker-compose.yml
version: "3.8"

services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - VERSION=docker
      - PLEX_CLAIM= # Get from https://plex.tv/claim
    volumes:
      - /home/YOUR_USERNAME/docker/plex/config:/config
      - /home/YOUR_USERNAME/docker/plex/transcode:/transcode
      - /srv/dev-disk-by-uuid-[movies-uuid]/movies:/movies:ro
      - /srv/dev-disk-by-uuid-[tv-uuid]/tvseries:/tv:ro
      - /srv/dev-disk-by-uuid-[music-uuid]/music:/music:ro
    restart: unless-stopped
    devices:
      - /dev/dri:/dev/dri # Hardware transcoding (if available)
```

### Deploy Plex
```bash
cd /home/YOUR_USERNAME/docker/plex
docker compose up -d

# Check logs
docker compose logs -f plex
```

### Plex Configuration
```bash
# Access web interface: http://[pi-ip-address]:32400/web
# Complete initial setup wizard
# Add media libraries pointing to mounted volumes
```

## 📸 Immich Photo Management

### Create Immich Directory
```bash
# Create Immich data directory
mkdir -p /home/YOUR_USERNAME/docker/immich
mkdir -p /srv/dev-disk-by-uuid-[photos-uuid]/immich/{upload,library}
```

### Immich Docker Compose
```yaml
# /home/YOUR_USERNAME/docker/immich/docker-compose.yml
version: "3.8"

name: immich

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    command: ['start.sh', 'immich']
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    ports:
      - 2283:3001
    depends_on:
      - redis
      - database
    restart: always

  immich-microservices:
    container_name: immich_microservices
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    command: ['start.sh', 'microservices']
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    depends_on:
      - redis
      - database
    restart: always

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    volumes:
      - model-cache:/cache
    env_file:
      - .env
    restart: always

  redis:
    container_name: immich_redis
    image: redis:6.2-alpine@sha256:51d6c56749a4243096327e3fb964a48ed92254357108449cb6e23999c37773c5
    restart: always

  database:
    container_name: immich_postgres
    image: tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
    volumes:
      - /home/YOUR_USERNAME/docker/immich/postgres:/var/lib/postgresql/data
    restart: always

volumes:
  model-cache:
```

### Immich Environment Configuration
```bash
# /home/YOUR_USERNAME/docker/immich/.env
UPLOAD_LOCATION=/srv/dev-disk-by-uuid-[photos-uuid]/immich/upload
IMMICH_VERSION=release
DB_PASSWORD=your_secure_password
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
```

### Deploy Immich
```bash
cd /home/YOUR_USERNAME/docker/immich
docker compose up -d

# Check status
docker compose ps
```

## 🔄 Backup Solution Setup

### Install rclone
```bash
# Install rclone
sudo apt install -y rclone

# Configure Google Drive
rclone config
# Follow prompts to setup Google Drive remote named "gdrive"
```

### Create Backup Script
```bash
# Create script directory
mkdir -p /home/YOUR_USERNAME/scripts

# Copy improved backup script (see scripts/backup/nas_backup.sh)
# Make executable
chmod +x /home/YOUR_USERNAME/scripts/nas_backup.sh
```

### Configure Cron Job
```bash
# Edit crontab
crontab -e

# Add backup job (4 AM daily)
0 4 * * * /home/YOUR_USERNAME/scripts/nas_backup.sh
```

## ⚙️ System Optimization

### Performance Tuning

#### Memory Optimization
```bash
# Add to /etc/sysctl.conf
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
vm.swappiness = 10
```

#### Storage Optimization
```bash
# Optimize ext4 filesystems
# Add to /etc/fstab for each data drive:
# UUID=[drive-uuid] /srv/dev-disk-by-uuid-[uuid] ext4 defaults,noatime,errors=remount-ro 0 2
```

### Monitoring Setup

#### Install System Monitoring
```bash
# Install htop, iotop, iftop
sudo apt install -y htop iotop iftop nmon

# Create monitoring script
cat > /home/YOUR_USERNAME/scripts/system_monitor.sh << 'EOF'
#!/bin/bash
echo "=== System Status $(date) ==="
echo "Temperature: $(vcgencmd measure_temp)"
echo "Throttling: $(vcgencmd get_throttled)"
echo "Memory Usage:"
free -h
echo "Disk Usage:"
df -h | grep -E "(srv|boot)"
echo "Load Average:"
uptime
EOF

chmod +x /home/YOUR_USERNAME/scripts/system_monitor.sh
```

## 🔐 Security Configuration

### Firewall Setup
```bash
# Install and configure UFW
sudo apt install -y ufw

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow essential services
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # OMV Web Interface
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 9000/tcp  # Portainer
sudo ufw allow 32400/tcp # Plex
sudo ufw allow 2283/tcp  # Immich

# Enable firewall
sudo ufw enable
```

### SSH Security
```bash
# Configure SSH security
sudo tee -a /etc/ssh/sshd_config << EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Restart SSH service
sudo systemctl restart ssh
```

## 🧪 Installation Verification

### System Health Check
```bash
#!/bin/bash
# Run comprehensive system verification

echo "=== Pi 5 NAS Installation Verification ==="

# Check OMV status
echo "OMV Status:"
sudo systemctl status openmediavault-engined

# Check Docker containers
echo -e "\nDocker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check storage mounts
echo -e "\nStorage Mounts:"
df -h | grep srv

# Check SnapRAID status
echo -e "\nSnapRAID Status:"
sudo snapraid status 2>/dev/null || echo "SnapRAID not configured"

# Check network performance
echo -e "\nNetwork Interface:"
ip addr show eth0 | grep "inet\|state"

# Check system resources
echo -e "\nSystem Resources:"
echo "CPU Temp: $(vcgencmd measure_temp)"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"

echo -e "\n=== Verification Complete ==="
```

## 📋 Post-Installation Checklist

- [ ] OMV web interface accessible
- [ ] All storage drives mounted and accessible
- [ ] SnapRAID array configured with parity protection
- [ ] Docker and Portainer running
- [ ] Plex Media Server accessible and configured
- [ ] Immich photo management running
- [ ] Backup script configured and tested
- [ ] Firewall enabled with appropriate rules
- [ ] System monitoring tools installed
- [ ] Performance optimization applied
- [ ] All services start automatically on boot

**Next Steps**: 
- [Clone to NVMe boot drive](nvme-cloning.md)
- [Configure advanced features](advanced-configuration.md)
- [Setup monitoring and alerts](troubleshooting.md#performance-monitoring)
---

# NVMe Boot Drive Upgrade

## 🎯 Overview

This guide covers the critical process of cloning your SD card to an NVMe SSD for significantly improved boot performance and reliability. This process involves several subtle but crucial steps that can cause boot failures if not done correctly.

## ⚠️ Real-World Issues Encountered

### Common Problems and Solutions
- **Boot failure after cloning** - Incorrect PARTUUID references
- **System falls back to SD card** - Wrong cmdline.txt configuration  
- **Slow boot times persist** - Firmware not updated for NVMe priority
- **Drive detection issues** - USB adapter compatibility problems
- **Partition table corruption** - Improper cloning procedures

## 🛠️ Prerequisites

### Hardware Requirements
- **M.2 NVMe SSD** (256GB minimum, 512GB recommended)
- **USB 3.0 to M.2 adapter** (Ensure UASP support)
- **Working Pi 5 NAS** with fully configured SD card
- **Reliable power supply** (failures during cloning can corrupt data)

### Software Requirements
```bash
# Install required tools
sudo apt update
sudo apt install -y rpi-clone parted gdisk lsblk util-linux
```

## 📋 Pre-Cloning Checklist

### 1. Verify System Stability
```bash
# Ensure system is stable before cloning
# Run for 24 hours without issues
/home/YOUR_USERNAME/scripts/health_check.sh

# Check for any filesystem errors
sudo fsck -n /dev/mmcblk0p2

# Verify all services are working
docker ps
sudo systemctl status openmediavault-engined
```

### 2. Clean Up SD Card
```bash
# Remove unnecessary files to speed up cloning
sudo apt autoremove -y
sudo apt autoclean
docker system prune -f

# Clear logs (optional)
sudo journalctl --vacuum-time=7d

# Check final SD card usage
df -h /
```

### 3. Document Current Configuration
```bash
# Save current boot configuration
cp /boot/firmware/cmdline.txt ~/cmdline.txt.backup
cp /boot/firmware/config.txt ~/config.txt.backup

# Save current fstab
cp /etc/fstab ~/fstab.backup

# Note current PARTUUID
sudo blkid /dev/mmcblk0p2 | grep -o 'PARTUUID="[^"]*"'
```

## 🔌 Hardware Setup

### NVMe Adapter Selection
**Tested Compatible Adapters:**
- UGREEN M.2 NVMe to USB 3.0 Adapter
- Sabrent USB 3.0 to M.2 NVMe Tool-Free Enclosure
- StarTech USB 3.1 to M.2 NVMe SSD Enclosure

**Avoid These Issues:**
- USB 2.0 adapters (too slow)
- Adapters without UASP support
- Cheap adapters with overheating issues

### Physical Connection
```bash
# 1. Power down Pi completely
sudo poweroff

# 2. Install NVMe in USB adapter
# 3. Connect to Pi USB 3.0 port (blue port)
# 4. Boot Pi and verify detection

# Check NVMe detection
lsblk | grep -E "(nvme|sda)"
dmesg | tail | grep -i usb

# Expected output: device should appear as /dev/sda
```

## 🔄 Cloning Process

### Method 1: Using rpi-clone (Recommended)
```bash
# Install rpi-clone if not present
git clone https://github.com/billw2/rpi-clone.git
cd rpi-clone
sudo cp rpi-clone /usr/local/sbin

# CRITICAL: Verify target device
lsblk
# Ensure your NVMe is /dev/sda and has no existing partitions

# Clone SD card to NVMe (this takes 30-60 minutes)
sudo rpi-clone sda

# rpi-clone will:
# 1. Partition the NVMe drive
# 2. Format filesystems 
# 3. Copy all data
# 4. Update PARTUUIDs automatically
# 5. Update cmdline.txt and fstab
```

### Method 2: Manual Cloning (Advanced)
```bash
# Only use if rpi-clone fails
# Create partition table
sudo fdisk /dev/sda
# Create: 512MB FAT32 boot + remaining ext4 root

# Format partitions
sudo mkfs.vfat -F 32 /dev/sda1
sudo mkfs.ext4 /dev/sda2

# Mount and copy
sudo mkdir -p /mnt/{boot,root}
sudo mount /dev/sda1 /mnt/boot
sudo mount /dev/sda2 /mnt/root

# Copy boot partition
sudo cp -a /boot/firmware/* /mnt/boot/

# Copy root partition (this takes time)
sudo rsync -avx --progress / /mnt/root/

# Update configuration (see next section)
```

## ⚙️ Critical Configuration Updates

### 1. Update Boot Configuration
```bash
# Get new PARTUUID of NVMe root partition
NEW_PARTUUID=$(sudo blkid /dev/sda2 | grep -o 'PARTUUID="[^"]*"' | cut -d'"' -f2)
echo "New PARTUUID: $NEW_PARTUUID"

# Update cmdline.txt on NVMe boot partition
sudo mount /dev/sda1 /mnt/boot
sudo cp /mnt/boot/cmdline.txt /mnt/boot/cmdline.txt.backup

# Replace old PARTUUID with new one
sudo sed -i "s/PARTUUID=[a-f0-9-]*/PARTUUID=$NEW_PARTUUID/" /mnt/boot/cmdline.txt

# Verify the change
cat /mnt/boot/cmdline.txt
# Should show: root=PARTUUID=[new-uuid] ...
```

### 2. Update fstab on NVMe
```bash
# Mount NVMe root partition
sudo mount /dev/sda2 /mnt/root

# Get UUIDs for both partitions
BOOT_UUID=$(sudo blkid /dev/sda1 | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)
ROOT_UUID=$(sudo blkid /dev/sda2 | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)

# Update fstab
sudo tee /mnt/root/etc/fstab << EOF
proc            /proc           proc    defaults          0       0
UUID=$BOOT_UUID  /boot/firmware  vfat    defaults          0       2
UUID=$ROOT_UUID  /               ext4    defaults,noatime  0       1
# Data drives (update these to match your setup)
UUID=aaaaaaaa-bbbb-cccc-dddd-111111111111 /srv/dev-disk-by-uuid-aaaaaaaa-bbbb-cccc-dddd-111111111111 ext4 defaults,noatime,errors=remount-ro 0 2
UUID=bbbbbbbb-cccc-dddd-eeee-222222222222 /srv/dev-disk-by-uuid-bbbbbbbb-cccc-dddd-eeee-222222222222 ext4 defaults,noatime,errors=remount-ro 0 2
UUID=cccccccc-dddd-eeee-ffff-333333333333 /srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333 ext4 defaults,noatime,errors=remount-ro 0 2
UUID=dddddddd-eeee-ffff-aaaa-444444444444 /srv/dev-disk-by-uuid-dddddddd-eeee-ffff-aaaa-444444444444 ext4 defaults,noatime,errors=remount-ro 0 2
EOF
```

### 3. Firmware Update for NVMe Priority
```bash
# Update Pi firmware for better NVMe support
sudo rpi-eeprom-update -a

# Check current bootloader version
sudo rpi-eeprom-update

# If updates available, install and reboot
sudo reboot
```

## 🧪 Pre-Boot Testing

### Verify Clone Integrity
```bash
# Before removing SD card, verify the clone
# Mount both drives and compare critical files

sudo mkdir -p /mnt/{nvme-boot,nvme-root}
sudo mount /dev/sda1 /mnt/nvme-boot
sudo mount /dev/sda2 /mnt/nvme-root

# Compare boot configurations
diff /boot/firmware/config.txt /mnt/nvme-boot/config.txt
cat /mnt/nvme-boot/cmdline.txt

# Check if critical directories exist
ls -la /mnt/nvme-root/home/YOUR_USERNAME/docker/
ls -la /mnt/nvme-root/srv/
ls -la /mnt/nvme-root/etc/

# Verify Docker volumes survived
sudo docker volume ls

# Unmount before testing boot
sudo umount /mnt/nvme-boot /mnt/nvme-root
```

## 🚀 Boot Testing Process

### Phase 1: Test Boot with SD Card Present
```bash
# 1. Keep SD card inserted
# 2. Reboot system
sudo reboot

# 3. After boot, check which device is root
df -h /
# Should still show /dev/mmcblk0p2 (SD card)

# 4. Verify NVMe is detected and accessible
lsblk | grep sda
sudo mount /dev/sda2 /mnt && ls /mnt && sudo umount /mnt
```

### Phase 2: Boot Priority Configuration
```bash
# Configure boot order to prefer USB/NVMe
# This requires bootloader configuration

# Check current boot order
vcgencmd bootloader_config

# Update boot order (if needed)
# Create bootloader config
sudo tee /tmp/boot.conf << EOF
BOOT_ORDER=0xf41
POWER_OFF_ON_HALT=0
BOOT_UART=0
WAKE_ON_GPIO=1
USB_MSD_PWR_OFF_TIME=0
SD_BOOT_MAX_RETRIES=3
NET_BOOT_MAX_RETRIES=5
EOF

# Apply bootloader config
sudo rpi-eeprom-config --apply /tmp/boot.conf
sudo reboot
```

### Phase 3: Remove SD Card Test
```bash
# 1. Power down completely
sudo poweroff

# 2. Physically remove SD card
# 3. Power on and monitor boot process

# 4. After successful boot, verify system
df -h /
# Should now show /dev/sda2 as root

# 5. Verify all services work
systemctl status openmediavault-engined
docker ps
/home/YOUR_USERNAME/scripts/health_check.sh
```

## 🔧 Troubleshooting Boot Issues

### Issue: System Won't Boot from NVMe
```bash
# 1. Re-insert SD card and boot
# 2. Check NVMe cmdline.txt
sudo mount /dev/sda1 /mnt
cat /mnt/cmdline.txt
# Verify PARTUUID is correct

# 3. Check PARTUUID matches
sudo blkid /dev/sda2
# Compare with cmdline.txt

# 4. Fix if mismatched
NEW_UUID=$(sudo blkid /dev/sda2 | grep -o 'PARTUUID="[^"]*"' | cut -d'"' -f2)
sudo sed -i "s/PARTUUID=[a-f0-9-]*/PARTUUID=$NEW_UUID/" /mnt/cmdline.txt
```

### Issue: Boot Loops or Kernel Panics
```bash
# 1. Boot from SD card
# 2. Check NVMe filesystem
sudo fsck -f /dev/sda2

# 3. Re-clone if corruption found
sudo rpi-clone sda -f
```

### Issue: NVMe Not Detected
```bash
# 1. Check USB adapter compatibility
lsusb -v | grep -A 5 "Mass Storage"

# 2. Try different USB port
# 3. Check power supply capacity
vcgencmd get_throttled

# 4. Update firmware
sudo rpi-eeprom-update -a
```

## 📊 Performance Verification

### Boot Time Comparison
```bash
# Measure boot time after NVMe migration
# SD Card typical: 45-60 seconds
# NVMe typical: 25-35 seconds

# Check current boot time
systemd-analyze time

# Detailed boot analysis
systemd-analyze blame | head -10
```

### Storage Performance Test
```bash
# Test NVMe performance vs SD card
sudo hdparm -tT /dev/sda2
# Expected: 200-400 MB/sec (vs 50-80 MB/sec for SD)

# Test random I/O performance
sudo fio --name=random-write --ioengine=posixaio --rw=randwrite --bs=4k --size=256M --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --filename=/tmp/test
```

## 🛡️ Backup Strategy After Migration

### Create SD Card Emergency Boot
```bash
# Keep a minimal SD card for emergencies
# Clone just the boot partition back to SD

# Create minimal SD card
sudo dd if=/dev/sda1 of=/dev/mmcblk0p1 bs=4M status=progress

# Update cmdline.txt to point back to NVMe
# This allows SD card boot but NVMe root
```

### Regular NVMe Backup
```bash
# Add NVMe backup to your backup script
# Use rclone or rsync to backup critical configs

# Example backup addition
rclone sync /boot/firmware gdrive:NAS_Backup/Boot_Config \
    --bwlimit 10M \
    --log-file=/home/YOUR_USERNAME/logs/backup.log
```

## ✅ Post-Migration Checklist

- [ ] System boots from NVMe without SD card
- [ ] All Docker containers start properly
- [ ] OMV web interface accessible
- [ ] All storage drives mount correctly
- [ ] Network performance unchanged
- [ ] Plex/Immich services functional
- [ ] Backup scripts work correctly
- [ ] Boot time improved (sub-30 seconds)
- [ ] No filesystem errors in logs
- [ ] Emergency SD card prepared

## 🎯 Expected Performance Improvements

**Before (SD Card):**
- Boot time: 45-60 seconds
- Random I/O: 10-20 MB/sec
- Sequential read: 50-80 MB/sec
- App responsiveness: Slow

**After (NVMe):**
- Boot time: 25-35 seconds
- Random I/O: 100-200 MB/sec  
- Sequential read: 200-400 MB/sec
- App responsiveness: Significantly improved

The NVMe migration is one of the most impactful upgrades you can make to the Pi 5 NAS system!