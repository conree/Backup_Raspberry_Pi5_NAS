# Software Installation Guide

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