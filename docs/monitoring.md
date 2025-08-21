# Monitoring & Dashboards Documentation

## 📊 Overview

The monitoring system provides comprehensive visibility into the edge server's performance, IoT data streams, and system health. It combines Grafana dashboards with InfluxDB time-series data to deliver real-time insights and historical analysis.

## 🏗️ Monitoring Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │    │   InfluxDB      │    │   Grafana       │
│                 │    │   (Time Series) │    │   (Dashboards)  │
│ • MQTT Messages │───▶│ • Data Storage  │───▶│ • Visualization │
│ • System Metrics│    │ • Query Engine  │    │ • Alerts        │
│ • IoT Sensors   │    │ • Retention     │    │ • Reports       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Node-RED      │    │   Data Pipeline │    │   User Interface│
│   (Data Flow)   │    │   (Processing)  │    │   (Web Browser) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🗄️ InfluxDB Configuration

### Database Setup
```sql
-- Create database
CREATE DATABASE edge_data

-- Create retention policy
CREATE RETENTION POLICY "default" ON "edge_data" DURATION 30d REPLICATION 1 DEFAULT

-- Create user
CREATE USER edgeuser WITH PASSWORD 'edgepass'
GRANT ALL ON edge_data TO edgeuser
```

### Data Structure

#### CAN Data Measurement
```sql
-- Measurement: can_data
-- Tags: device_id, message_type, source
-- Fields: value, unit, quality
-- Timestamp: automatic

-- Example data point
can_data,device_id=engine,message_type=pressure,source=ecu value=25.5,unit="MPa",quality="good" 1704096000000000000
```

#### System Metrics Measurement
```sql
-- Measurement: system_metrics
-- Tags: host, service, metric_type
-- Fields: value, unit
-- Timestamp: automatic

-- Example data point
system_metrics,host=edge-server,service=mqtt,metric_type=connections value=15,unit="count" 1704096000000000000
```

#### MQTT Statistics Measurement
```sql
-- Measurement: mqtt_stats
-- Tags: topic, client_id, qos
-- Fields: message_count, bytes_sent, latency
-- Timestamp: automatic

-- Example data point
mqtt_stats,topic="vehicle/can/pressure",client_id="nodered",qos=1 message_count=1000,bytes_sent=50000,latency=5.2 1704096000000000000
```

### Data Retention and Management

#### Retention Policies
```sql
-- Short-term data (high resolution)
CREATE RETENTION POLICY "high_res" ON "edge_data" DURATION 7d REPLICATION 1

-- Medium-term data (hourly aggregation)
CREATE RETENTION POLICY "hourly" ON "edge_data" DURATION 30d REPLICATION 1

-- Long-term data (daily aggregation)
CREATE RETENTION POLICY "daily" ON "edge_data" DURATION 1y REPLICATION 1
```

#### Continuous Queries
```sql
-- Hourly aggregation
CREATE CONTINUOUS QUERY "hourly_agg" ON "edge_data" 
BEGIN
  SELECT mean(value) as avg_value, min(value) as min_value, max(value) as max_value
  FROM can_data
  GROUP BY time(1h), device_id, message_type
END

-- Daily aggregation
CREATE CONTINUOUS QUERY "daily_agg" ON "edge_data" 
BEGIN
  SELECT mean(value) as avg_value, min(value) as min_value, max(value) as max_value
  FROM can_data
  GROUP BY time(1d), device_id, message_type
END
```

## 📈 Grafana Dashboards

### 1. Vehicle Monitoring Dashboard

#### Dashboard Configuration
```json
{
  "dashboard": {
    "id": null,
    "title": "Vehicle Monitoring",
    "tags": ["vehicle", "can", "monitoring"],
    "timezone": "browser",
    "panels": [],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
```

#### Panel Examples

**Engine Pressure Chart**
```json
{
  "id": 1,
  "title": "Engine Pressure",
  "type": "graph",
  "targets": [
    {
      "query": "SELECT mean(value) FROM can_data WHERE message_type = 'pressure' AND device_id = 'engine' GROUP BY time(1m)",
      "rawQuery": true,
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "pressuremPa",
      "min": 0,
      "max": 50
    }
  }
}
```

**Vehicle Speed Gauge**
```json
{
  "id": 2,
  "title": "Vehicle Speed",
  "type": "gauge",
  "targets": [
    {
      "query": "SELECT last(value) FROM can_data WHERE message_type = 'speed' AND device_id = 'vehicle'",
      "rawQuery": true,
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "velocitykmh",
      "min": 0,
      "max": 200
    }
  }
}
```

**System Status Table**
```json
{
  "id": 3,
  "title": "System Status",
  "type": "table",
  "targets": [
    {
      "query": "SELECT last(value), device_id, message_type, quality FROM can_data GROUP BY device_id, message_type",
      "rawQuery": true,
      "refId": "A"
    }
  ]
}
```

### 2. System Performance Dashboard

#### Dashboard Configuration
```json
{
  "dashboard": {
    "id": null,
    "title": "System Performance",
    "tags": ["system", "performance", "monitoring"],
    "timezone": "browser",
    "panels": [],
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "refresh": "10s"
  }
}
```

#### Panel Examples

**MQTT Connection Count**
```json
{
  "id": 1,
  "title": "MQTT Connections",
  "type": "stat",
  "targets": [
    {
      "query": "SELECT last(value) FROM system_metrics WHERE metric_type = 'connections' AND service = 'mqtt'",
      "rawQuery": true,
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "short",
      "color": {
        "mode": "thresholds"
      },
      "thresholds": {
        "steps": [
          {"color": "green", "value": null},
          {"color": "yellow", "value": 50},
          {"color": "red", "value": 100}
        ]
      }
    }
  }
}
```

**Message Rate Chart**
```json
{
  "id": 2,
  "title": "Message Rate (per minute)",
  "type": "graph",
  "targets": [
    {
      "query": "SELECT count(value) FROM can_data WHERE time > now() - 1h GROUP BY time(1m)",
      "rawQuery": true,
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "short",
      "min": 0
    }
  }
}
```

**System Resource Usage**
```json
{
  "id": 3,
  "title": "System Resources",
  "type": "graph",
  "targets": [
    {
      "query": "SELECT mean(value) FROM system_metrics WHERE metric_type IN ('cpu', 'memory', 'disk') GROUP BY time(1m), metric_type",
      "rawQuery": true,
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100
    }
  }
}
```

### 3. Alerting Dashboard

#### Dashboard Configuration
```json
{
  "dashboard": {
    "id": null,
    "title": "System Alerts",
    "tags": ["alerts", "notifications", "monitoring"],
    "timezone": "browser",
    "panels": [],
    "time": {
      "from": "now-24h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

#### Panel Examples

**Active Alerts Table**
```json
{
  "id": 1,
  "title": "Active Alerts",
  "type": "table",
  "targets": [
    {
      "query": "SELECT time, device_id, message_type, value, threshold FROM can_data WHERE value > threshold AND time > now() - 1h ORDER BY time DESC",
      "rawQuery": true,
      "refId": "A"
    }
  ]
}
```

**Alert History Chart**
```json
{
  "id": 2,
  "title": "Alert History",
  "type": "graph",
  "targets": [
    {
      "query": "SELECT count(value) FROM can_data WHERE value > threshold GROUP BY time(1h)",
      "rawQuery": true,
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "short",
      "min": 0
    }
  }
}
```

## 🔍 InfluxDB Queries

### Basic Queries

#### Select Recent Data
```sql
-- Last 100 data points
SELECT * FROM can_data ORDER BY time DESC LIMIT 100

-- Data from last hour
SELECT * FROM can_data WHERE time > now() - 1h

-- Specific device data
SELECT * FROM can_data WHERE device_id = 'engine'
```

#### Aggregation Queries
```sql
-- Average value per minute
SELECT mean(value) FROM can_data 
WHERE time > now() - 1h 
GROUP BY time(1m), device_id

-- Min/Max values per hour
SELECT min(value), max(value), mean(value) 
FROM can_data 
WHERE time > now() - 24h 
GROUP BY time(1h), device_id

-- Count messages per device
SELECT count(value) FROM can_data 
WHERE time > now() - 1h 
GROUP BY device_id
```

### Advanced Queries

#### Time-based Analysis
```sql
-- Compare current vs previous period
SELECT 
  mean(value) as current_avg,
  LAG(mean(value), 1) OVER (ORDER BY time) as previous_avg
FROM can_data 
WHERE time > now() - 2h 
GROUP BY time(1h)

-- Moving average
SELECT 
  time,
  value,
  MEAN(value) OVER (ORDER BY time ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) as moving_avg
FROM can_data 
WHERE device_id = 'engine' 
  AND time > now() - 1h
```

#### Conditional Queries
```sql
-- Values above threshold
SELECT * FROM can_data 
WHERE value > 25.0 
  AND message_type = 'pressure'

-- Quality filtering
SELECT * FROM can_data 
WHERE quality = 'good' 
  AND time > now() - 1h

-- Multiple conditions
SELECT * FROM can_data 
WHERE (device_id = 'engine' OR device_id = 'transmission')
  AND value BETWEEN 20.0 AND 30.0
  AND time > now() - 6h
```

#### Statistical Analysis
```sql
-- Percentile analysis
SELECT 
  percentile(value, 95) as p95,
  percentile(value, 99) as p99,
  stddev(value) as std_dev
FROM can_data 
WHERE time > now() - 24h 
  AND device_id = 'engine'

-- Trend analysis
SELECT 
  time,
  value,
  value - LAG(value, 1) OVER (ORDER BY time) as change
FROM can_data 
WHERE device_id = 'engine' 
  AND time > now() - 1h
```

## 🚨 Alerting Configuration

### Grafana Alert Rules

#### High Pressure Alert
```json
{
  "alert": {
    "name": "High Engine Pressure",
    "message": "Engine pressure exceeded critical threshold",
    "conditions": [
      {
        "type": "query",
        "query": {
          "params": ["A", "5m", "now"]
        },
        "reducer": {
          "type": "avg",
          "params": []
        },
        "evaluator": {
          "type": "gt",
          "params": [25.0]
        }
      }
    ],
    "frequency": "1m",
    "handler": 1,
    "message": "Engine pressure is {{ $value }} MPa, exceeding 25.0 MPa threshold",
    "name": "High Engine Pressure Alert",
    "noDataState": "no_data",
    "notifications": []
  }
}
```

#### System Health Alert
```json
{
  "alert": {
    "name": "System Health Check",
    "message": "System metrics indicate potential issues",
    "conditions": [
      {
        "type": "query",
        "query": {
          "params": ["A", "5m", "now"]
        },
        "reducer": {
          "type": "avg",
          "params": []
        },
        "evaluator": {
          "type": "lt",
          "params": [0.8]
        }
      }
    ],
    "frequency": "5m",
    "handler": 1,
    "message": "System health score is {{ $value }}, below 0.8 threshold",
    "name": "System Health Alert",
    "noDataState": "no_data",
    "notifications": []
  }
}
```

### Notification Channels

#### Email Notification
```json
{
  "type": "email",
  "name": "Email Alerts",
  "settings": {
    "addresses": "admin@example.com,ops@example.com"
  },
  "isDefault": true
}
```

#### Slack Notification
```json
{
  "type": "slack",
  "name": "Slack Alerts",
  "settings": {
    "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "channel": "#alerts",
    "username": "Grafana Alerting"
  }
}
```

#### Webhook Notification
```json
{
  "type": "webhook",
  "name": "Webhook Alerts",
  "settings": {
    "url": "https://api.example.com/alerts",
    "httpMethod": "POST",
    "maxAlerts": 100
  }
}
```

## 📊 Performance Monitoring

### System Metrics Collection

#### CPU Usage
```bash
# Collect CPU metrics
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

# Store in InfluxDB
curl -i -XPOST "http://localhost:8086/write?db=edge_data" \
  --data-binary "system_metrics,host=edge-server,metric_type=cpu value=25.5"
```

#### Memory Usage
```bash
# Collect memory metrics
free | grep Mem | awk '{print $3/$2 * 100.0}'

# Store in InfluxDB
curl -i -XPOST "http://localhost:8086/write?db=edge_data" \
  --data-binary "system_metrics,host=edge-server,metric_type=memory value=67.2"
```

#### Disk Usage
```bash
# Collect disk metrics
df / | tail -1 | awk '{print $5}' | cut -d'%' -f1

# Store in InfluxDB
curl -i -XPOST "http://localhost:8086/write?db=edge_data" \
  --data-binary "system_metrics,host=edge-server,metric_type=disk value=45.8"
```

### MQTT Performance Metrics

#### Connection Monitoring
```bash
# Monitor MQTT connections
mosquitto_sub -h localhost -t '$SYS/broker/clients/active' -C 1

# Store in InfluxDB
curl -i -XPOST "http://localhost:8086/write?db=edge_data" \
  --data-binary "mqtt_stats,metric_type=connections value=15"
```

#### Message Rate Monitoring
```bash
# Monitor message rate
mosquitto_sub -h localhost -t '$SYS/broker/load/messages/1min' -C 1

# Store in InfluxDB
curl -i -XPOST "http://localhost:8086/write?db=edge_data" \
  --data-binary "mqtt_stats,metric_type=message_rate value=1200"
```

## 🔄 Data Export and Backup

### Automated Backups

#### InfluxDB Backup Script
```bash
#!/bin/bash
# backup-influxdb.sh

BACKUP_DIR="/backup/influxdb/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup database
influxd backup -database edge_data -retention default $BACKUP_DIR

# Compress backup
tar -czf "${BACKUP_DIR}.tar.gz" $BACKUP_DIR
rm -rf $BACKUP_DIR

echo "InfluxDB backup completed: ${BACKUP_DIR}.tar.gz"
```

#### Grafana Backup Script
```bash
#!/bin/bash
# backup-grafana.sh

BACKUP_DIR="/backup/grafana/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Export dashboards
curl -s "http://localhost:3000/api/search" | jq -r '.[].url' | while read url; do
  id=$(echo $url | cut -d'/' -f4)
  curl -s "http://localhost:3000/api/dashboards/uid/$id" > "$BACKUP_DIR/dashboard_$id.json"
done

# Export datasources
curl -s "http://localhost:3000/api/datasources" > "$BACKUP_DIR/datasources.json"

# Compress backup
tar -czf "${BACKUP_DIR}.tar.gz" $BACKUP_DIR
rm -rf $BACKUP_DIR

echo "Grafana backup completed: ${BACKUP_DIR}.tar.gz"
```

### Data Export

#### CSV Export
```sql
-- Export specific data to CSV
SELECT time, device_id, message_type, value, unit 
FROM can_data 
WHERE time > '2024-01-01' 
  AND time < '2024-01-02'
INTO OUTFILE '/tmp/can_data_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

#### JSON Export
```bash
# Export data as JSON
curl -G "http://localhost:8086/query" \
  --data-urlencode "db=edge_data" \
  --data-urlencode "q=SELECT * FROM can_data WHERE time > now() - 1h" \
  --data-urlencode "epoch=ms" \
  | jq '.results[0].series[0].values' > can_data_export.json
```

## 🛠️ Troubleshooting

### Common Issues

#### InfluxDB Connection Problems
```bash
# Check service status
sudo docker compose ps influxdb

# Check logs
sudo docker compose logs influxdb

# Test connectivity
curl -G "http://localhost:8086/query" --data-urlencode "q=SHOW DATABASES"
```

#### Grafana Dashboard Issues
```bash
# Check service status
sudo docker compose ps grafana

# Check logs
sudo docker compose logs grafana

# Test connectivity
curl -s "http://localhost:3000/api/health"
```

#### Data Not Appearing
```bash
# Check data in InfluxDB
curl -G "http://localhost:8086/query" \
  --data-urlencode "db=edge_data" \
  --data-urlencode "q=SELECT count(*) FROM can_data"

# Check data source configuration
# Verify InfluxDB connection in Grafana
# Check query syntax and time range
```

### Performance Issues

#### Slow Queries
```sql
-- Add indexes for frequently queried fields
CREATE INDEX idx_device_id ON can_data(device_id)
CREATE INDEX idx_message_type ON can_data(message_type)
CREATE INDEX idx_time ON can_data(time)

-- Use time-based queries efficiently
SELECT * FROM can_data WHERE time > now() - 1h  -- Good
SELECT * FROM can_data WHERE time > '2024-01-01'  -- Less efficient
```

#### High Memory Usage
```bash
# Monitor InfluxDB memory
curl -G "http://localhost:8086/query" \
  --data-urlencode "db=edge_data" \
  --data-urlencode "q=SHOW STATS"

# Optimize retention policies
# Reduce data resolution for older data
# Use continuous queries for aggregation
```

## 📚 References

- [InfluxDB Documentation](https://docs.influxdata.com/influxdb/v1.8/)
- [InfluxQL Reference](https://docs.influxdata.com/influxdb/v1.8/query_language/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/)
- [Time Series Best Practices](https://docs.influxdata.com/influxdb/v1.8/guides/writing_data/)

---

**Note**: This monitoring system is designed for development and testing environments. For production deployment, implement proper security measures, backup strategies, and performance tuning based on your specific requirements and data volumes.
