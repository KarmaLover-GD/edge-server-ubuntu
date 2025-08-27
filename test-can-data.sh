#!/bin/bash

echo "🧪 Testing CAN Data Processing System..."

# Test data with proper CSV format
TEST_DATA="timestamp,CANID,CANDATA
$(date +%s),101,0000000000000000
$(date +%s),d7,0000000000000000
$(date +%s),101,0000000000000000
$(date +%s),d7,0000000000000000"

echo "📤 Sending test data via MQTT..."
echo "$TEST_DATA" | mosquitto_pub -h 192.168.12.1 -t "csv/file" -l

echo "✅ Test data sent!"
echo ""
echo "📊 Check Node-RED debug output for processing status"
echo "🗄️ Check InfluxDB for stored data"
echo "📈 Check Grafana dashboard for visualizations"
echo ""
echo "🔍 To view real-time logs:"
echo "docker logs -f nodered"
