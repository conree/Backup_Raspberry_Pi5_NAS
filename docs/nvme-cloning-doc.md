# NVMe Boot Drive Cloning Guide

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