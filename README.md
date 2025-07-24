# Raspberry Pi NAS Backup System 🥧🛡️

> **Complete Raspberry Pi NAS backup solution with automated scripts, Docker configurations, and comprehensive documentation for bulletproof data protection**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Raspberry Pi](https://img.shields.io/badge/-Raspberry%20Pi-C51A4A?style=flat&logo=Raspberry-Pi)](https://www.raspberrypi.org/)

## 🍓 Privacy Notice

⚠️ **This repository contains example configurations with anonymized data for educational purposes. All usernames, IP addresses, UUIDs, and personal information have been replaced with generic examples. Replace these with your actual values when implementing.**

## 🚀 Why This NAS Backup Solution?

**Traditional Pi NAS setups are vulnerable to data loss.** This system provides **production-ready protection** with automated backup strategies:

- 💾 **Drive failures** → Multiple backup destinations protect your data
- 🔥 **System corruption** → Complete Docker configuration backups
- 📱 **Service failures** → Restore Plex, Immich, and other services instantly
- ⚙️ **Config loss** → Automated configuration snapshots

## 🏗️ Complete Pi5 NAS Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    RASPBERRY PI 5 NAS SYSTEM                │
├─────────────────────────────────────────────────────────────┤
│  HARDWARE LAYER                                             │
│  • Raspberry Pi 5 (8GB RAM recommended)                    │
│  • Radaxa Penta HAT (5-bay SATA expansion)                 │
│  • NVMe boot drive + multiple SATA storage drives          │
├─────────────────────────────────────────────────────────────┤
│  SOFTWARE LAYER                                             │
│  • Docker containerized services                            │
│  • Plex Media Server (streaming)                           │
│  • Immich (photo management)                               │
│  • Portainer (container management)                        │
├─────────────────────────────────────────────────────────────┤
│  BACKUP LAYER                                               │
│  • Automated daily backups                                 │
│  • Docker configuration snapshots                          │
│  • Multi-destination redundancy                            │
│  • Cron-based scheduling                                   │
└─────────────────────────────────────────────────────────────┘
```

## ⚡ Key Features

### 🔧 **Hardware Setup**
- **Raspberry Pi 5 optimization** - Complete setup guide
- **Radaxa Penta HAT integration** - 5-bay SATA expansion
- **NVMe boot configuration** - Fast system performance
- **Multi-drive RAID setup** - Storage redundancy

### 🐳 **Docker Services**
- **Plex Media Server** - Complete streaming solution
- **Immich** - Self-hosted photo management
- **Portainer** - Web-based container management
- **Automated deployments** - Docker Compose configurations

### 🛡️ **Backup & Protection**
- **Automated backup scripts** - Daily protection schedule
- **Configuration snapshots** - Docker and system configs
- **Multi-destination backups** - Local and remote redundancy
- **Health monitoring** - System status checks

## 📁 Repository Structure

```
raspberry-pi-nas-backup/
├── README.md                   # This comprehensive guide
├── scripts/
│   ├── backup/
│   │   ├── NAS_Backup_Script.sh           # Main backup automation
│   │   └── backup-script-final.sh         # Enhanced backup script
│   └── installation/
│       ├── Raspberry_Pi_5_NAS_Automated_Installation_Script.sh
│       └── Immich_Environment_Configuration.sh
├── docs/
│   ├── hardware-setup-doc.md              # Hardware assembly guide
│   ├── software-installation-doc.md       # Software setup guide
│   ├── nvme-cloning-doc.md                # NVMe setup and cloning
│   └── Complete Pi 5 NAS Setup - README.md.pdf
└── docker/
    ├── plex/
    │   └── Plex_Docker_Compose_Configuration
    ├── immich/
    │   ├── Immich_Docker_Compose
    │   └── Immich Environment Configuration.yaml
    └── portainer/
        └── Portainer_Docker_Compose_Configuration
```

## 🛠️ Hardware Components

### **Recommended Setup**
- **Raspberry Pi 5** (8GB RAM recommended)
- **Radaxa Penta HAT** (5-bay SATA expansion)
- **NVMe SSD** (128GB+ for boot drive)
- **SATA Drives** (Multiple drives for storage array)
- **Quality Power Supply** (Official Pi 5 PSU recommended)

### **Performance Benefits**
- **Fast NVMe boot** - Improved system responsiveness
- **Multiple SATA drives** - High-capacity storage expansion
- **RAID configurations** - Data redundancy and performance
- **Efficient cooling** - Reliable long-term operation

## 🚀 Quick Start Guide

### 1. **Hardware Assembly**
```bash
# Follow the hardware setup documentation
# docs/hardware-setup-doc.md provides complete assembly guide
```

### 2. **Clone Repository**
```bash
git clone https://github.com/conree/raspberry-pi-nas-backup.git
cd raspberry-pi-nas-backup
```

### 3. **Run Automated Installation**
```bash
# Make installation script executable
chmod +x scripts/installation/Raspberry_Pi_5_NAS_Automated_Installation_Script.sh

# Run with your preferred username
sudo ./scripts/installation/Raspberry_Pi_5_NAS_Automated_Installation_Script.sh
```

### 4. **Configure Services**
```bash
# Set up Docker services
cp docker/plex/Plex_Docker_Compose_Configuration /home/YOUR_USERNAME/docker/plex/docker-compose.yml
cp docker/immich/Immich_Docker_Compose /home/YOUR_USERNAME/docker/immich/docker-compose.yml

# Configure environment variables
cp docker/immich/Immich_Environment_Configuration.yaml /home/YOUR_USERNAME/docker/immich/.env
```

### 5. **Enable Automated Backups**
```bash
# Copy backup script
cp scripts/backup/NAS_Backup_Script.sh /home/YOUR_USERNAME/scripts/
chmod +x /home/YOUR_USERNAME/scripts/NAS_Backup_Script.sh

# Add to crontab for daily execution
echo "0 4 * * * /home/YOUR_USERNAME/scripts/NAS_Backup_Script.sh" | crontab -
```

## 🐳 Docker Services Setup

### **Plex Media Server**
```bash
# Navigate to Plex directory
cd /home/YOUR_USERNAME/docker/plex

# Start Plex service
docker-compose up -d

# Access at: http://YOUR_PI_HOSTNAME:32400/web
```

### **Immich Photo Management**
```bash
# Navigate to Immich directory  
cd /home/YOUR_USERNAME/docker/immich

# Start Immich services
docker-compose up -d

# Access at: http://YOUR_PI_HOSTNAME:2283
```

### **Portainer Management**
```bash
# Navigate to Portainer directory
cd /home/YOUR_USERNAME/docker/portainer

# Start Portainer
docker-compose up -d

# Access at: http://YOUR_PI_HOSTNAME:9000
```

## 🛡️ Backup Features

### **Automated Backup Script**
- **Daily execution** - Cron-scheduled protection
- **Docker configurations** - All service configs backed up
- **System settings** - Important system files included
- **Log management** - Comprehensive backup logging
- **Error handling** - Robust failure detection

### **Backup Destinations**
- **Local storage** - On-device backup copies
- **External drives** - USB/SATA backup destinations
- **Network storage** - Remote backup options
- **Cloud integration** - Optional cloud sync

### **What Gets Backed Up**
- **Docker configurations** - All docker-compose files
- **Service data** - Plex libraries, Immich photos
- **System configurations** - Network, user settings
- **Installation scripts** - Recovery and setup scripts

## 📖 Comprehensive Documentation

### **Setup Guides**
- **[Hardware Setup](docs/hardware-setup-doc.md)** - Physical assembly guide
- **[Software Installation](docs/software-installation-doc.md)** - Complete software setup
- **[NVMe Configuration](docs/nvme-cloning-doc.md)** - Boot drive setup and cloning

### **Service Documentation**
- **Plex Configuration** - Media server optimization
- **Immich Setup** - Photo management configuration
- **Portainer Usage** - Container management guide

## 🔧 Customization Options

### **Modify Backup Schedule**
```bash
# Edit crontab for different timing
crontab -e

# Examples:
# 0 2 * * * = Daily at 2 AM
# 0 4 * * 0 = Weekly on Sunday at 4 AM  
# 0 6 1 * * = Monthly on 1st at 6 AM
```

### **Add Additional Services**
```bash
# Create new docker-compose configuration
mkdir /home/YOUR_USERNAME/docker/new-service
# Add your docker-compose.yml
# Update backup script to include new service
```

### **Configure Storage Arrays**
```bash
# Set up RAID configurations
# Modify mount points in docker configurations
# Update backup destinations
```

## 🧪 Testing & Monitoring

### **System Health Checks**
```bash
# Run system monitor script
/home/YOUR_USERNAME/scripts/system_monitor.sh

# Check Docker service status
docker ps -a

# Monitor storage usage
df -h
```

### **Backup Verification**
```bash
# Test backup script
/home/YOUR_USERNAME/scripts/NAS_Backup_Script.sh --test

# Verify backup integrity
ls -la /backup/destination/

# Check backup logs
tail -f /home/YOUR_USERNAME/logs/backup.log
```

## 📊 Performance Specifications

| Component | Specification | Performance |
|-----------|--------------|-------------|
| **CPU** | Raspberry Pi 5 (Quad-core ARM) | Efficient media serving |
| **RAM** | 8GB (recommended) | Multiple concurrent streams |
| **Storage** | NVMe + SATA array | Fast access + high capacity |
| **Network** | Gigabit Ethernet | Full bandwidth utilization |
| **Services** | Docker containers | Isolated, manageable services |

## 🤝 Contributing

Contributions welcome! This Pi NAS solution has been tested in real-world scenarios.

- **🐛 Hardware Issues**: Report compatibility problems
- **💡 Service Additions**: Suggest new Docker services
- **📝 Documentation**: Improve setup guides
- **🔧 Scripts**: Enhance backup and monitoring

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Raspberry Pi Foundation** - For the incredible Pi 5 hardware
- **Radaxa** - For the excellent Penta HAT expansion
- **Docker Community** - For containerization technology
- **Plex** - For media server software
- **Immich** - For self-hosted photo management
- **Real-world testing** - Proven in production environments

## ⚠️ Important Setup Notes

- **Update all YOUR_USERNAME placeholders** with your actual username
- **Replace YOUR_PI_HOSTNAME** with your Pi's hostname or IP
- **Configure proper network settings** for your environment
- **Test backup and recovery procedures** before relying on them
- **Keep documentation updated** as you customize your setup

---

> **"A well-configured Pi NAS with proper backups is more reliable than many commercial solutions."**  
> This system provides enterprise-grade reliability on Raspberry Pi hardware.

**🥧 Happy Pi NAS Building! 🛡️🚀**
