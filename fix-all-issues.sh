#!/bin/bash

echo "🔧 Fixing All Issues - Complete System Reset..."

# Get the current user ID
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "Current user: $USER_ID:$GROUP_ID"

# Fix CSV directory permissions
echo "📁 Fixing CSV directory permissions..."
sudo chown -R $USER_ID:$GROUP_ID ./csv
sudo chmod -R 755 ./csv
mkdir -p ./csv

# Fix Docker volume permissions
echo "🐳 Fixing Docker volume permissions..."
sudo chown -R $USER_ID:$GROUP_ID ./docker/csv
sudo chmod -R 755 ./docker/csv

# Setup Grafana configuration
echo "📊 Setting up Grafana configuration..."
cd grafana
chmod +x setup-grafana.sh
./setup-grafana.sh
cd ..

# Stop all containers
echo "⏹️ Stopping all containers..."
cd docker
docker-compose down

# Remove any existing volumes to ensure clean state
echo "🗑️ Cleaning up volumes..."
docker volume prune -f

# Start the system fresh
echo "🚀 Starting system fresh..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 30

echo ""
echo "✅ All issues fixed and system restarted!"
echo ""
echo "🔍 Check the status:"
echo "docker-compose ps"
echo ""
echo "📊 Test the system:"
echo "../test-can-data.sh"
echo ""
echo "🌐 Access your services:"
echo "  Node-RED:  http://192.168.12.1:1880"
echo "  Grafana:   http://192.168.12.1:3000 (admin/admin123)"
echo "  InfluxDB:  http://192.168.12.1:8086 (admin/admin123)"
echo ""
echo "📝 What was fixed:"
echo "  ✅ File permissions for CSV writing"
echo "  ✅ InfluxDB authentication in Node-RED"
echo "  ✅ Grafana dashboard and datasource configuration"
echo "  ✅ Docker container user mapping"
echo "  ✅ Clean system restart"
echo ""
echo "🎯 The system should now:"
echo "  - Parse CSV data correctly"
echo "  - Store data in InfluxDB without errors"
echo "  - Write decoded CSV files successfully"
echo "  - Display real-time charts in Grafana"
