#!/bin/bash

echo "🔧 Fixing file permissions for Node-RED..."

# Get the current user ID
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "Current user: $USER_ID:$GROUP_ID"

# Fix CSV directory permissions
echo "Fixing CSV directory permissions..."
sudo chown -R $USER_ID:$GROUP_ID ./csv
sudo chmod -R 755 ./csv

# Create the directory if it doesn't exist
mkdir -p ./csv

# Fix Docker volume permissions
echo "Fixing Docker volume permissions..."
sudo chown -R $USER_ID:$GROUP_ID ./docker/csv
sudo chmod -R 755 ./docker/csv

echo "✅ Permissions fixed!"
echo ""
echo "🔄 Now restart your Docker stack:"
echo "cd docker"
echo "docker-compose down"
echo "docker-compose up -d"
echo ""
echo "📝 The changes made:"
echo "  - Added user: 1000:1000 to Node-RED container"
echo "  - Fixed CSV directory permissions"
echo "  - Added InfluxDB credentials to Node-RED config"
echo ""
echo "🎯 After restart, both file writing and InfluxDB storage should work!"
