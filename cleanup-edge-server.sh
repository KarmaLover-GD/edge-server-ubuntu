#!/bin/bash
WIFI_IF=$(nmcli device status | grep wifi | awk '{print $1}')
echo "🧹 Cleaning up Edge Server..."

# === REMOVE HOTSPOT CONNECTION ===
HOTSPOT_NAME="EdgeServerHotspot"
echo "📡 Removing NetworkManager hotspot: $HOTSPOT_NAME"
nmcli con delete "$HOTSPOT_NAME" 2>/dev/null || echo "No hotspot connection to delete"

# === RESTORE NetworkManager ===
echo "✅ Re-enabling NetworkManager control on wlan0..."
nmcli dev set $WIFI_IF managed yes

# === REMOVE DNSMASQ CONFIG ===
if [ -f /etc/dnsmasq.conf.backup ]; then
  echo "🛠️ Restoring original dnsmasq.conf..."
  sudo mv /etc/dnsmasq.conf.backup /etc/dnsmasq.conf
else
  echo "⚠️ dnsmasq.conf.backup not found — skipping restore"
fi

echo "⛔ Stopping and disabling dnsmasq..."
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq

# === REMOVE IPTABLES RULES ===
echo "🔥 Flushing iptables rules..."
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X

echo "🗑️ Removing persistent iptables restore script..."
sudo rm -f /etc/network/if-up.d/iptables-restore
sudo rm -f /etc/iptables.rules

# === REMOVE SYSCTL SETTING ===
echo "🚫 Disabling IP forwarding..."
sudo rm -f /etc/sysctl.d/99-hotspot.conf
sudo sysctl -w net.ipv4.ip_forward=0

# === CLEAN UP DOCKER STACK ===
echo "🐳 Stopping and removing Docker services..."
cd "$(dirname "$0")/docker"
sudo docker-compose down

read -p "🗑️ Do you want to delete Docker volumes? (y/n): " delvol
if [ "$delvol" == "y" ]; then
  sudo docker volume rm $(docker volume ls -q --filter name=nodered)
  sudo docker volume rm $(docker volume ls -q --filter name=influxdb)
  sudo docker volume rm $(docker volume ls -q --filter name=grafana)
fi

echo "✅ Cleanup complete. Your system is restored."
