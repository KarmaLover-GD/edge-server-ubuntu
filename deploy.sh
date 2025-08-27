#!/bin/bash

set -e

echo "📶 Setting up Wi-Fi hotspot..."
cd "$(dirname "$0")/hotspot"
chmod +x setup-full-hotspot.sh
sudo ./setup-full-hotspot.sh

cd ../grafana
chmod +x setup-grafana.sh
./setup-grafana.sh

echo "🐳 Deploying Docker containers..."
cd ../docker

# Check Docker
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not installed. Please install Docker and try again."
  exit 1
fi
sudo systemctl restart docker

# Start Docker Compose stack
sudo docker compose up -d

# Wait a bit to ensure services are up
echo "⏳ Waiting for containers to initialize..."
sleep 5

echo "✅ Edge server fully deployed!"
echo "🔗 Node-RED:  http://192.168.12.1:1880"
echo "📊 Grafana:   http://192.168.12.1:3000 (admin/admin123)"


# Open in default browser if possible
if command -v xdg-open &> /dev/null; then
    xdg-open "http://192.168.12.1:1880" >/dev/null 2>&1 &
    xdg-open "http://192.168.12.1:3000" >/dev/null 2>&1 &

elif command -v sensible-browser &> /dev/null; then
    sensible-browser "http://192.168.12.1:1880" &
    sensible-browser "http://192.168.12.1:3000" &
    
else
    echo "⚠️ No browser command found. Please open the URLs manually."
fi
