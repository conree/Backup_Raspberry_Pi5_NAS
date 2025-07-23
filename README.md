# Complete Raspberry Pi 5 NAS Setup

> **⚠️ Privacy Notice**: This repository contains example configurations with anonymized data for educational purposes. All usernames, IP addresses, UUIDs, and personal information have been replaced with generic examples. Replace these with your actual values when implementing.

A comprehensive guide for building a production-ready NAS using Raspberry Pi 5, complete with media streaming, photo management, and automated backups.

## 🏗️ Hardware Setup

### Components Used
- **Raspberry Pi 5** (8GB RAM recommended)
- **Radaxa Penta HAT** (5-bay SATA expansion)
- **4x 2TB TeamGroup SSDs** (SATA)
- **M.2 NVMe SSD** (for boot drive via USB adapter)
- **Cat 8 Ethernet cables** (gigabit networking)

### Storage Configuration
- **Boot Drive**: M.2 NVMe SSD (external USB adapter)
- **Data Storage**: 4x 2TB SSDs via Radaxa Penta HAT
- **Protection**: SnapRAID parity + content files
- **Total Usable**: ~6TB with 1x parity protection

## 📊 Performance Results

### Network Performance
- **Local throughput**: 38.9 Gbps (loopback)
- **Internet**: 1GB fiber connection
- **Streaming**: Supports multiple 4K streams

### Storage Performance
- **Individual SSD speed**: 486-520 MB/sec per drive
- **Cached reads**: 4.6-5.7 GB/sec
- **4K streaming**: Smooth, no buffering issues

## 🛠️ Software Stack

### Base System
- **OS**: Raspberry Pi OS (Debian 12 Bookworm)
- **NAS OS**: OpenMediaVault 7 (OMV)
- **Containerization**: Docker + Portainer
- **Storage Protection**: SnapRAID

### Applications
- **Media Server**: Plex Media Server
- **Photo Management**: Immich
- **Backup**: rclone to Google Drive
- **Monitoring**: Built-in OMV tools

## 🚀 Quick Start

### 1. Automated Installation
```bash
# Clone this repository
git clone https://github.com/your-username/YOUR_PI_HOSTNAME-setup.git
cd YOUR_PI_HOSTNAME-setup

# Run automated installation
chmod +x scripts/installation/automated_install.sh
./scripts/installation/automated_install.sh
```

### 2. Manual Installation
Follow the detailed guides in order:
1. [Hardware Setup](docs/hardware-setup.md)
2. [Software Installation](docs/software-installation.md)
3. [NVMe Boot Drive Cloning](docs/nvme-cloning.md)
4. [Advanced Configuration](docs/advanced-configuration.md)

## 🎯 Key Features

### Real-World Problem Solving
- **Plex Streaming Issues**: Fixed chapter thumbnail generation conflicts
- **NVMe Boot Cloning**: Complete guide with PARTUUID and firmware fixes
- **Performance Optimization**: Actual tested configurations
- **Comprehensive Monitoring**: Health checks and alerting

### Production-Ready Features
- **Automated Installation**: One-command setup
- **Security Hardening**: Firewall, SSH keys, container security
- **Backup Solutions**: Automated cloud sync with bandwidth limiting
- **CI/CD Pipeline**: Automated testing and validation

## 📁 Project Structure

```
YOUR_PI_HOSTNAME-setup/
├── README.md
├── docs/
│   ├── hardware-setup.md
│   ├── software-installation.md
│   ├── nvme-cloning.md
│   ├── advanced-configuration.md
│   └── troubleshooting.md
├── scripts/
│   ├── backup/
│   │   └── nas_backup.sh
│   └── installation/
│       └── automated_install.sh
├── docker/
│   ├── plex/
│   │   └── docker-compose.yml
│   └── immich/
│       ├── docker-compose.yml
│       └── .env.example
└── .github/
    └── workflows/
        └── ci.yml
```

## 🔧 Configuration Examples

### Plex Media Server
```bash
# Deploy Plex with optimized settings
cd docker/plex
docker compose up -d

# Access at: http://YOUR_PI_HOSTNAME:32400/web
```

### Immich Photo Management
```bash
# Setup Immich with PostgreSQL
cd docker/immich
cp .env.example .env
# Edit .env with your settings
docker compose up -d

# Access at: http://YOUR_PI_HOSTNAME:2283
```

### Automated Backups
```bash
# Configure rclone with Google Drive
rclone config

# Setup automated backup
cp scripts/backup/nas_backup.sh /home/YOUR_USERNAME/scripts/
chmod +x /home/YOUR_USERNAME/scripts/nas_backup.sh

# Add to crontab (4 AM daily)
echo "0 4 * * * /home/YOUR_USERNAME/scripts/nas_backup.sh" | crontab -
```

## ⚡ Performance Optimizations

### Critical Plex Fix - Scheduled Tasks
**Problem**: "Insufficient bandwidth" errors during streaming
**Solution**: Disable intensive background tasks during prime time

1. Plex Settings → Server → Scheduled Tasks
2. Change maintenance window to 4:00-6:00 AM
3. Disable "Generate chapter thumbnails during maintenance"
4. Disable "Perform extensive media analysis during maintenance"

### NVMe Boot Performance
- **Boot time improvement**: 45-60s → 25-35s
- **Random I/O**: 10-20 MB/s → 100-200 MB/s
- **Application responsiveness**: Significantly improved

## 🔍 Troubleshooting

### Common Issues
- **Streaming Problems**: See [troubleshooting guide](docs/troubleshooting.md#streaming-issues)
- **Storage Detection**: Check [hardware troubleshooting](docs/troubleshooting.md#storage-issues)
- **Boot Issues**: Follow [NVMe cloning guide](docs/nvme-cloning.md#troubleshooting-boot-issues)

### Performance Monitoring
```bash
# Check system health
/home/YOUR_USERNAME/scripts/health_check.sh

# Monitor real-time performance
htop
iotop
iftop -i eth0
```

## 📈 Results & Benefits

### Performance Achievements
- **4K streaming**: Multiple simultaneous streams
- **Photo processing**: Fast Immich performance with face recognition
- **Backup speed**: 50MB/sec sustained uploads
- **Boot time**: <30 seconds from NVMe

### Reliability Features
- **Data protection**: SnapRAID parity + multiple content files
- **Automatic recovery**: Container restart policies
- **Remote backup**: Complete cloud synchronization
- **Monitoring**: Comprehensive logging and health checks

## 🎥 Video Series

Complete video tutorial series available:
- **Series 1**: Hardware Setup and Assembly
- **Series 2**: Software Installation and Configuration  
- **Series 3**: Application Deployment (Plex, Immich)
- **Series 4**: Advanced Configuration and Optimization
- **Series 5**: Troubleshooting Real-World Issues

See [Video Documentation](docs/VIDEO_DOCUMENTATION.md) for scripts and production guides.

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with detailed description

See our [CI/CD pipeline](.github/workflows/ci.yml) for automated testing.

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- OpenMediaVault team for excellent NAS software
- Radaxa for Pi 5 compatible SATA HAT
- Plex and Immich communities for media software
- Raspberry Pi Foundation for the amazing Pi 5

---

**Total Project Cost**: ~$470-500 USD  
**Setup Time**: 4-6 hours with automation  
**Skill Level**: Intermediate  
**Maintenance**: Minimal (automated)