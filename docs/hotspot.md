# Wi-Fi Hotspot Documentation

## 📡 Overview

The Wi-Fi hotspot system transforms your Ubuntu machine into a wireless access point that provides internet connectivity to connected devices while maintaining network isolation. This is essential for creating a dedicated network for IoT devices and edge computing applications.

## 🏗️ Architecture

```
Internet (Ethernet/WAN)
         │
         ▼
   [Ethernet Interface]
         │
         ▼
   [IP Forwarding + NAT]
         │
         ▼
   [Wi-Fi Interface]
         │
         ▼
   [DHCP Server (dnsmasq)]
         │
         ▼
   [Wi-Fi Clients]
```

## ⚙️ Configuration

### Network Settings
- **SSID**: `EdgeServerHotspot`
- **Password**: `strongpass123`
- **Network**: `192.168.12.0/24`
- **Gateway**: `192.168.12.1`
- **DHCP Range**: `192.168.12.10` - `192.168.12.50`
- **Subnet Mask**: `255.255.255.0`
- **DNS**: `8.8.8.8`, `8.8.4.4`

### Wi-Fi Interface Detection
The system automatically detects your Wi-Fi interface using:
```bash
WIFI_IF=$(nmcli device status | grep wifi | awk '{print $1}')
```

## 🚀 Setup Process

### 1. Prerequisites Installation
```bash
sudo apt update
sudo apt install -y network-manager dnsmasq iptables
```

### 2. NetworkManager Configuration
```bash
# Disable NetworkManager control on Wi-Fi interface
nmcli dev set "$WIFI_IF" managed no

# Create hotspot connection
nmcli con add type wifi ifname "$WIFI_IF" con-name "EdgeServerHotspot" \
    autoconnect yes ssid "EdgeServerHotspot"

# Configure as access point
nmcli con modify "EdgeServerHotspot" \
    802-11-wireless.mode ap \
    802-11-wireless.band bg \
    ipv4.method manual \
    ipv4.addresses "192.168.12.1/24"

# Set security
nmcli con modify "EdgeServerHotspot" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "strongpass123"
```

### 3. DHCP Server (dnsmasq)
```bash
# Backup original config
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

# Create new config
cat <<EOF | sudo tee /etc/dnsmasq.conf
interface=$WIFI_IF
dhcp-range=192.168.12.10,192.168.12.50,12h
domain-needed
bogus-priv
dhcp-option=3,192.168.12.1
dhcp-option=6,8.8.8.8,8.8.4.4
EOF
```

### 4. IP Forwarding and NAT
```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-hotspot.conf

# Configure iptables for NAT
sudo iptables -t nat -A POSTROUTING -o "$INTERNET_IF" -j MASQUERADE
sudo iptables -A FORWARD -i "$INTERNET_IF" -o "$WIFI_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORPUTING -i "$WIFI_IF" -o "$INTERNET_IF" -j ACCEPT

# Persist rules
sudo iptables-save | sudo tee /etc/iptables.rules
```

## 🔧 Management Commands

### Start Hotspot
```bash
nmcli con up "EdgeServerHotspot"
```

### Stop Hotspot
```bash
nmcli con down "EdgeServerHotspot"
```

### Check Status
```bash
# Connection status
nmcli con show "EdgeServerHotspot"

# Device status
nmcli device status

# DHCP leases
sudo cat /var/lib/misc/dnsmasq.leases
```

### View Connected Clients
```bash
# Using arp
arp -a | grep 192.168.12

# Using dnsmasq leases
sudo cat /var/lib/misc/dnsmasq.leases
```

## 🌐 Internet Sharing

### How It Works
1. **IP Forwarding**: Enables packet forwarding between interfaces
2. **NAT (Network Address Translation)**: Translates private IPs to public IPs
3. **iptables Rules**: Manages packet flow and translation

### NAT Rules Explained
```bash
# POSTROUTING: Translate source addresses when packets leave the server
sudo iptables -t nat -A POSTROUTING -o "$INTERNET_IF" -j MASQUERADE

# FORWARD: Allow established connections back to clients
sudo iptables -A FORWARD -i "$INTERNET_IF" -o "$WIFI_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT

# FORWARD: Allow new connections from clients to internet
sudo iptables -A FORWARD -i "$WIFI_IF" -o "$INTERNET_IF" -j ACCEPT
```

## 🔒 Security Features

### Network Isolation
- Hotspot network is completely isolated from the main network
- Clients can only communicate through the server
- No direct access between hotspot clients and main network

### Firewall Configuration
- Only necessary ports are open
- NAT rules are restrictive by default
- No incoming connections from internet to hotspot

## 🛠️ Troubleshooting

### Common Issues

#### Hotspot Won't Start
```bash
# Check Wi-Fi interface
nmcli device status | grep wifi

# Check NetworkManager logs
journalctl -u NetworkManager -f

# Reset NetworkManager
sudo systemctl restart NetworkManager
```

#### Clients Can't Connect
```bash
# Check DHCP server
sudo systemctl status dnsmasq

# Check dnsmasq logs
journalctl -u dnsmasq -f

# Verify IP range
sudo cat /etc/dnsmasq.conf
```

#### No Internet Access
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Check iptables rules
sudo iptables -t nat -L -v
sudo iptables -L FORWARD -v

# Test connectivity
ping 8.8.8.8
```

#### Permission Denied
```bash
# Ensure script is executable
chmod +x setup-full-hotspot.sh

# Run with sudo
sudo ./setup-full-hotspot.sh
```

### Debug Commands
```bash
# Check all network interfaces
ip addr show

# Check routing table
ip route show

# Check iptables rules
sudo iptables -L -v -n
sudo iptables -t nat -L -v -n

# Monitor network traffic
sudo tcpdump -i any -n
```

## 📊 Monitoring

### Connection Statistics
```bash
# Active connections
ss -tuln

# Bandwidth usage
iftop -i $WIFI_IF

# Connection count
netstat -an | grep :80 | wc -l
```

### Log Files
- **NetworkManager**: `journalctl -u NetworkManager`
- **dnsmasq**: `journalctl -u dnsmasq`
- **System logs**: `journalctl -f`

## 🔄 Maintenance

### Regular Tasks
1. **Update packages**: `sudo apt update && sudo apt upgrade`
2. **Check logs**: Monitor for errors or unusual activity
3. **Verify connectivity**: Test internet access from clients
4. **Clean up**: Remove old DHCP leases if needed

### Backup Configuration
```bash
# Backup hotspot configuration
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup.$(date +%Y%m%d)

# Backup iptables rules
sudo iptables-save > iptables.backup.$(date +%Y%m%d)
```

## 🚀 Advanced Configuration

### Custom SSID and Password
Edit the script variables:
```bash
SSID="YourCustomSSID"
PASSWORD="YourCustomPassword"
```

### Custom IP Range
```bash
HOTSPOT_IP="192.168.100.1"
SUBNET="192.168.100.0"
RANGE_START="192.168.100.10"
RANGE_END="192.168.100.100"
```

### Additional Security
```bash
# MAC address filtering
echo "dhcp-host=AA:BB:CC:DD:EE:FF,192.168.12.100" >> /etc/dnsmasq.conf

# Static IP assignments
echo "dhcp-host=AA:BB:CC:DD:EE:FF,192.168.12.100,client1" >> /etc/dnsmasq.conf
```

## 📚 References

- [NetworkManager Documentation](https://developer.gnome.org/NetworkManager/)
- [dnsmasq Documentation](https://dnsmasq.org/)
- [iptables Tutorial](https://www.netfilter.org/documentation/)
- [Ubuntu Networking Guide](https://ubuntu.com/server/docs/network-configuration)

---

**Note**: This hotspot system is designed for development and testing environments. For production use, consider implementing additional security measures such as WPA2-Enterprise authentication, VLAN isolation, and intrusion detection systems.
