# Node-RED Workflows Documentation

## 🔄 Overview

Node-RED is the visual programming interface that orchestrates data flow between MQTT messages, data processing, storage, and visualization. It provides a drag-and-drop environment for creating IoT workflows without writing code.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MQTT Input    │    │   Data Process  │    │   MQTT Output   │
│   (CAN Data)    │───▶│   (Filter/Parse)│───▶│   (Processed)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CSV Export    │    │   InfluxDB      │    │   Dashboard     │
│   (Data Log)    │    │   (Time Series) │    │   (Real-time)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Core Nodes

### 1. MQTT Nodes

#### MQTT Input Node
- **Purpose**: Subscribe to MQTT topics
- **Configuration**: Topic, QoS, Broker
- **Output**: JSON payload with topic and message

#### MQTT Output Node
- **Purpose**: Publish to MQTT topics
- **Configuration**: Topic, QoS, Retain flag
- **Input**: Any message payload

### 2. Data Processing Nodes

#### Function Node
- **Purpose**: Custom JavaScript processing
- **Input**: Message object
- **Output**: Modified message object

#### Switch Node
- **Purpose**: Route messages based on conditions
- **Input**: Message object
- **Output**: Multiple outputs based on rules

#### Change Node
- **Purpose**: Modify message properties
- **Input**: Message object
- **Output**: Modified message object

### 3. Storage Nodes

#### File Node
- **Purpose**: Read/write files (CSV export)
- **Input**: Message object
- **Output**: File content or confirmation

#### InfluxDB Node
- **Purpose**: Store time-series data
- **Input**: Message object with timestamp
- **Output**: Database confirmation

### 4. Dashboard Nodes

#### Chart Node
- **Purpose**: Real-time data visualization
- **Input**: Time-series data
- **Output**: Interactive chart

#### Gauge Node
- **Purpose**: Current value display
- **Input**: Numeric value
- **Output**: Visual gauge

## 🚀 Workflow Examples

### 1. CAN Data Processing Flow

#### Flow Description
This flow processes incoming CAN bus data, filters relevant messages, and stores them in both CSV and InfluxDB.

#### Node Configuration

**MQTT Input Node**
```json
{
  "id": "can-data-input",
  "type": "mqtt in",
  "name": "CAN Data Input",
  "topic": "vehicle/can/+/value",
  "qos": 1,
  "broker": "mqtt-broker"
}
```

**Function Node (Data Parser)**
```javascript
// Parse CAN data and add timestamp
const msg = {};
msg.timestamp = new Date().toISOString();
msg.topic = msg.topic;
msg.payload = JSON.parse(msg.payload);

// Extract relevant fields
msg.payload.parsed = {
  value: msg.payload.value,
  unit: msg.payload.unit,
  source: msg.topic.split('/')[2],
  quality: 'good'
};

return msg;
```

**Switch Node (Message Router)**
```json
{
  "id": "message-router",
  "type": "switch",
  "name": "Route by Message Type",
  "rules": [
    {
      "t": "eq",
      "v": "vehicle/can/pressure/value",
      "vt": "msg.topic"
    },
    {
      "t": "eq",
      "v": "vehicle/can/speed/value",
      "vt": "msg.topic"
    }
  ]
}
```

**File Node (CSV Export)**
```json
{
  "id": "csv-export",
  "type": "file",
  "name": "Export to CSV",
  "filename": "/csv/can_data.csv",
  "action": "append",
  "format": "csv"
}
```

**InfluxDB Node (Time Series Storage)**
```json
{
  "id": "influxdb-store",
  "type": "influxdb out",
  "name": "Store in InfluxDB",
  "measurement": "can_data",
  "database": "edge_data",
  "precision": "ms"
}
```

#### Complete Flow
```
MQTT Input → Function (Parse) → Switch (Route) → CSV Export
                ↓                      ↓
            InfluxDB Store ←─────── Dashboard
```

### 2. Real-time Monitoring Flow

#### Flow Description
This flow creates real-time dashboards for monitoring vehicle parameters with alerting capabilities.

#### Node Configuration

**MQTT Input Node (Multiple Topics)**
```json
{
  "id": "monitoring-input",
  "type": "mqtt in",
  "name": "Monitoring Input",
  "topic": "vehicle/+/+/value",
  "qos": 1,
  "broker": "mqtt-broker"
}
```

**Function Node (Alert Checker)**
```javascript
const msg = {};
msg.timestamp = new Date().toISOString();
msg.payload = JSON.parse(msg.payload);

// Check for critical values
if (msg.payload.value > msg.payload.critical_threshold) {
  msg.alert = {
    level: 'critical',
    message: `${msg.topic} exceeded critical threshold`,
    value: msg.payload.value,
    threshold: msg.payload.critical_threshold
  };
  
  // Publish alert
  node.send([
    msg,  // Original message
    {     // Alert message
      topic: 'vehicle/alerts/critical',
      payload: msg.alert
    }
  ]);
} else {
  return msg;
}
```

**Dashboard Chart Node**
```json
{
  "id": "real-time-chart",
  "type": "ui_chart",
  "name": "Real-time Chart",
  "group": "Vehicle Monitoring",
  "chartType": "line",
  "legend": "true",
  "xAxis": "time",
  "yAxis": "value"
}
```

**Dashboard Gauge Node**
```json
{
  "id": "current-gauge",
  "type": "ui_gauge",
  "name": "Current Value",
  "group": "Vehicle Monitoring",
  "min": 0,
  "max": 100,
  "units": "units"
}
```

### 3. Data Aggregation Flow

#### Flow Description
This flow aggregates data over time intervals and generates summary reports.

#### Node Configuration

**MQTT Input Node (Aggregated Data)**
```json
{
  "id": "aggregation-input",
  "type": "mqtt in",
  "name": "Aggregation Input",
  "topic": "vehicle/+/+/value",
  "qos": 1,
  "broker": "mqtt-broker"
}
```

**Function Node (Time Bucketing)**
```javascript
const msg = {};
msg.timestamp = new Date().toISOString();
msg.payload = JSON.parse(msg.payload);

// Create time bucket (hourly)
const date = new Date();
date.setMinutes(0, 0, 0);
msg.timeBucket = date.toISOString();

// Extract measurement type
msg.measurement = msg.topic.split('/')[2];

return msg;
```

**Aggregate Node (Statistics)**
```json
{
  "id": "statistics-aggregator",
  "type": "aggregate",
  "name": "Calculate Statistics",
  "groupBy": "timeBucket,measurement",
  "aggregations": [
    {
      "type": "mean",
      "field": "payload.value"
    },
    {
      "type": "min",
      "field": "payload.value"
    },
    {
      "type": "max",
      "field": "payload.value"
    }
  ]
}
```

**File Node (Report Export)**
```json
{
  "id": "report-export",
  "type": "file",
  "name": "Export Report",
  "filename": "/csv/hourly_report.csv",
  "action": "append",
  "format": "csv"
}
```

## 🔧 Advanced Features

### 1. Custom Functions

#### Data Validation Function
```javascript
function validateCANData(msg) {
  // Check required fields
  if (!msg.payload.value || !msg.payload.unit) {
    node.error("Invalid CAN data format", msg);
    return null;
  }
  
  // Validate value range
  if (msg.payload.value < 0 || msg.payload.value > 1000) {
    node.warn("Value out of expected range", msg);
  }
  
  // Add validation timestamp
  msg.payload.validated_at = new Date().toISOString();
  
  return msg;
}

// Usage in function node
return validateCANData(msg);
```

#### Data Transformation Function
```javascript
function transformCANData(msg) {
  const transformed = {};
  
  // Convert units if needed
  if (msg.payload.unit === 'kPa') {
    transformed.value = msg.payload.value / 1000; // Convert to MPa
    transformed.unit = 'MPa';
  } else {
    transformed.value = msg.payload.value;
    transformed.unit = msg.payload.unit;
  }
  
  // Add metadata
  transformed.source = msg.topic;
  transformed.timestamp = msg.timestamp;
  transformed.original_unit = msg.payload.unit;
  
  return {
    payload: transformed,
    topic: msg.topic
  };
}

// Usage in function node
return transformCANData(msg);
```

### 2. Error Handling

#### Try-Catch Pattern
```javascript
try {
  // Parse JSON payload
  const data = JSON.parse(msg.payload);
  
  // Process data
  msg.payload = processData(data);
  
  return msg;
} catch (error) {
  // Log error
  node.error("Failed to process message", error);
  
  // Send to error topic
  return {
    topic: "errors/processing",
    payload: {
      error: error.message,
      original_message: msg.payload,
      timestamp: new Date().toISOString()
    }
  };
}
```

#### Error Recovery
```javascript
// Retry mechanism
if (msg.retryCount === undefined) {
  msg.retryCount = 0;
}

if (msg.retryCount < 3) {
  msg.retryCount++;
  
  // Delay before retry
  setTimeout(() => {
    node.send(msg);
  }, 1000 * msg.retryCount);
  
  return null;
} else {
  // Max retries reached, send to error topic
  return {
    topic: "errors/max_retries",
    payload: {
      original_message: msg.payload,
      retry_count: msg.retryCount,
      timestamp: new Date().toISOString()
    }
  };
}
```

### 3. Performance Optimization

#### Message Batching
```javascript
// Collect messages and send in batches
const batchSize = 100;
const batch = [];

function processMessage(msg) {
  batch.push(msg);
  
  if (batch.length >= batchSize) {
    // Send batch
    node.send(batch);
    batch.length = 0; // Clear batch
  }
}

// Flush remaining messages
function flushBatch() {
  if (batch.length > 0) {
    node.send(batch);
    batch.length = 0;
  }
}

// Set up periodic flush
setInterval(flushBatch, 5000); // Flush every 5 seconds
```

#### Memory Management
```javascript
// Limit message history
const maxHistory = 1000;
let messageHistory = [];

function addToHistory(msg) {
  messageHistory.push({
    timestamp: new Date().getTime(),
    message: msg
  });
  
  // Remove old messages
  if (messageHistory.length > maxHistory) {
    messageHistory = messageHistory.slice(-maxHistory);
  }
}

// Clean up old messages periodically
setInterval(() => {
  const cutoff = Date.now() - (24 * 60 * 60 * 1000); // 24 hours
  messageHistory = messageHistory.filter(item => item.timestamp > cutoff);
}, 60 * 60 * 1000); // Every hour
```

## 📊 Dashboard Configuration

### 1. Dashboard Groups

#### Vehicle Monitoring Group
```json
{
  "id": "vehicle-monitoring",
  "name": "Vehicle Monitoring",
  "tab": "main",
  "order": 1,
  "width": "12",
  "collapse": false
}
```

#### System Status Group
```json
{
  "id": "system-status",
  "name": "System Status",
  "tab": "main",
  "order": 2,
  "width": "6",
  "collapse": false
}
```

### 2. Dashboard Layout

#### Responsive Grid
```json
{
  "id": "main-tab",
  "name": "Main Dashboard",
  "icon": "dashboard",
  "order": 1,
  "disabled": false,
  "hidden": false
}
```

#### Widget Configuration
```json
{
  "id": "pressure-chart",
  "type": "ui_chart",
  "name": "Engine Pressure",
  "group": "vehicle-monitoring",
  "order": 1,
  "width": "8",
  "height": "6",
  "chartType": "line",
  "legend": "true",
  "xAxis": "time",
  "yAxis": "value",
  "datalabels": "false"
}
```

## 🔄 Flow Management

### 1. Import/Export

#### Export Flow
```bash
# Export specific flow
curl -X GET "http://192.168.12.1:1880/flows" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  > flow-export.json

# Export all flows
curl -X GET "http://192.168.12.1:1880/flows" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  > all-flows-export.json
```

#### Import Flow
```bash
# Import flow from file
curl -X POST "http://192.168.12.1:1880/flows" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d @flow-import.json
```

### 2. Version Control

#### Git Integration
```bash
# Initialize git repository
cd /data
git init
git add .
git commit -m "Initial Node-RED flows"

# Create .gitignore
cat << EOF > .gitignore
node_modules/
*.log
.DS_Store
EOF

# Add remote and push
git remote add origin https://github.com/user/nodered-flows.git
git push -u origin main
```

#### Flow Backup Script
```bash
#!/bin/bash
# backup-flows.sh

BACKUP_DIR="/backup/flows/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup flows
curl -s "http://localhost:1880/flows" > $BACKUP_DIR/flows.json

# Backup settings
curl -s "http://localhost:1880/settings" > $BACKUP_DIR/settings.json

# Backup credentials
curl -s "http://localhost:1880/credentials" > $BACKUP_DIR/credentials.json

echo "Flows backed up to: $BACKUP_DIR"
```

## 🛠️ Troubleshooting

### Common Issues

#### Flow Won't Deploy
```bash
# Check Node-RED logs
sudo docker compose logs nodered

# Check flow syntax
# Validate JSON in flow editor

# Restart Node-RED
sudo docker compose restart nodered
```

#### MQTT Connection Issues
```bash
# Test MQTT broker connectivity
mosquitto_sub -h localhost -t "test/topic" -C 1

# Check broker status
sudo docker compose ps mosquitto

# Verify network connectivity
ping mosquitto
```

#### Performance Issues
```bash
# Monitor resource usage
sudo docker stats nodered

# Check message rates
# Monitor MQTT system topics

# Optimize flow design
# Reduce unnecessary processing
```

### Debug Techniques

#### Message Debugging
```javascript
// Add debug output
node.log("Received message:", JSON.stringify(msg, null, 2));

// Use debug node for message inspection
// Add debug node to flow for real-time monitoring
```

#### Flow Validation
```bash
# Validate flow JSON
python3 -m json.tool flow.json

# Check for syntax errors
# Verify node configurations
```

## 📚 References

- [Node-RED Documentation](https://nodered.org/docs/)
- [Node-RED API Reference](https://nodered.org/docs/api/)
- [Node-RED Dashboard](https://flows.nodered.org/node/node-red-dashboard)
- [Node-RED MQTT Nodes](https://flows.nodered.org/node/node-red-contrib-mqtt-broker)
- [Node-RED InfluxDB](https://flows.nodered.org/node/node-red-contrib-influxdb)

---

**Note**: This Node-RED workflow documentation provides examples for automotive CAN data processing. Customize flows based on your specific data format and requirements. Always test flows in development before deploying to production.
