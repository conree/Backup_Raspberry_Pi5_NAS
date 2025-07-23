# Hardware Setup Guide

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