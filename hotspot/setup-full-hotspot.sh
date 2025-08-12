#!/bin/bash

# === Auto-detect Wi-Fi interface ===
WIFI_IF=$(nmcli device status | grep wifi | awk '{print $1}')

if [ -z "$WIFI_IF" ]; then
  echo "❌ No Wi-Fi interface found. Exiting."
  exit 1
fi

# === Configuration ===
SSID="EdgeServerHotspot"
PASSWORD="strongpass123"
INTERNET_IF=$(nmcli device status | grep connected | grep ethernet | awk '{print $1}')
HOTSPOT_IP="192.168.12.1"
SUBNET="192.168.12.0"
RANGE_START="192.168.12.10"
RANGE_END="192.168.12.50"
NETMASK="255.255.255.0"

echo "📡 Using Wi-Fi interface: $WIFI_IF"
echo "🌍 Sharing internet from: $INTERNET_IF"

# === Install required tools ===
sudo apt update
sudo apt install -y network-manager dnsmasq iptables

# === Disable any existing dnsmasq ===
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq

# === Configure NetworkManager hotspot ===
nmcli dev set "$WIFI_IF" managed no
nmcli con delete "$SSID" 2>/dev/null

echo "🔧 Creating hotspot connection..."
nmcli con add type wifi ifname "$WIFI_IF" con-name "$SSID" autoconnect yes ssid "$SSID"
nmcli con modify "$SSID" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method manual ipv4.addresses "$HOTSPOT_IP/24"
nmcli con modify "$SSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PASSWORD"
nmcli con modify "$SSID" connection.interface-name "$WIFI_IF"

# === Enable the hotspot ===
echo "🚀 Starting hotspot..."
nmcli con up "$SSID"

# === Configure dnsmasq ===
echo "⚙️ Configuring dnsmasq..."
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null

cat <<EOF | sudo tee /etc/dnsmasq.conf
interface=$WIFI_IF
dhcp-range=$RANGE_START,$RANGE_END,12h
domain-needed
bogus-priv
dhcp-option=3,$HOTSPOT_IP
dhcp-option=6,8.8.8.8,8.8.4.4
EOF

# === Start dnsmasq ===
sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq

# === Enable IP forwarding ===
echo "🔀 Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-hotspot.conf

# === Configure NAT with iptables ===
echo "🌐 Setting up NAT for internet sharing..."
sudo iptables -t nat -A POSTROUTING -o "$INTERNET_IF" -j MASQUERADE
sudo iptables -A FORWARD -i "$INTERNET_IF" -o "$WIFI_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i "$WIFI_IF" -o "$INTERNET_IF" -j ACCEPT

# === Persist iptables rules ===
echo "💾 Saving iptables rules..."
sudo iptables-save | sudo tee /etc/iptables.rules > /dev/null
echo -e "#!/bin/sh\niptables-restore < /etc/iptables.rules" | sudo tee /etc/network/if-up.d/iptables-restore
sudo chmod +x /etc/network/if-up.d/iptables-restore

sudo nmcli dev set $WIFI_IF managed yes
# === Done ===
echo "✅ Hotspot created successfully!"
echo "🔗 SSID: $SSID"
echo "🔐 Password: $PASSWORD"
echo "📡 Wi-Fi Interface: $WIFI_IF"
echo "🌍 Internet Shared From: $INTERNET_IF"
echo "🧠 DHCP Range: $RANGE_START - $RANGE_END"
