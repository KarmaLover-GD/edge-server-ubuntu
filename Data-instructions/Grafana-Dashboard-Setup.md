# Grafana Dashboard Setup Guide for CAN Data Visualization

This guide will help you set up Grafana dashboards to visualize your CAN data stored in InfluxDB.

## 📋 Prerequisites

- ✅ InfluxDB running with `edge_data` database
- ✅ CAN data flowing from Node-RED to InfluxDB
- ✅ Grafana accessible at `http://192.168.12.1:3000`
- ✅ Grafana datasource configured for InfluxDB

## 🔍 Step 1: Verify Data in InfluxDB

Before creating dashboards, ensure your data is properly stored:

### Connect to InfluxDB Container
```bash
# Find your container name
docker ps | grep influxdb

# Connect with credentials
docker exec -it CONTAINER_NAME influx -username admin -password admin123
```

### Check Database and Data
```sql
-- List databases
SHOW DATABASES

-- Use your database
USE edge_data

-- Check measurements
SHOW MEASUREMENTS

-- View recent data
SELECT * FROM "can_data" LIMIT 10

-- Count total records
SELECT COUNT(*) FROM "can_data"

-- Check data from last hour
SELECT * FROM "can_data" WHERE time > now() - 1h
```

## 🎯 Step 2: Create Your First Dashboard

### 2.1 Create New Dashboard
1. **Open Grafana**: `http://192.168.12.1:3000`
2. **Login**: `admin` / `admin123`
3. **Click "+" icon** → **"Dashboard"**
4. **Click "Add new panel"**

### 2.2 Configure First Panel (Vehicle Speed)
1. **Panel Type**: Select "Time series"
2. **Data Source**: Choose your InfluxDB datasource
3. **Query**:
   ```sql
   SELECT "value" FROM "can_data" WHERE "label" = 'VehicleSpeed'
   ```
4. **Panel Title**: "Vehicle Speed (km/h)"
5. **Y-Axis**: 
   - Label: "Speed (km/h)"
   - Min: 0
   - Max: 200
6. **Click "Apply"**

### 2.3 Configure Second Panel (Cylinder Pressure)
1. **Click "Add panel"** → **"Add new panel"**
2. **Panel Type**: Select "Time series"
3. **Query**:
   ```sql
   SELECT "value" FROM "can_data" WHERE "label" = 'CylinderPressure'
   ```
4. **Panel Title**: "Cylinder Pressure (MPa)"
5. **Y-Axis**:
   - Label: "Pressure (MPa)"
   - Min: 0
   - Max: 10
6. **Click "Apply"**

## 📊 Step 3: Advanced Dashboard Configuration

### 3.1 Data Table Panel
1. **Add new panel** → **"Table"**
2. **Query**:
   ```sql
   SELECT 
     time,
     "can_id",
     "label",
     "value",
     "unit",
     "raw_value"
   FROM "can_data" 
   ORDER BY time DESC 
   LIMIT 20
   ```
3. **Panel Title**: "Raw CAN Data"
4. **Transform**: 
   - Add "Time" column formatting
   - Set "Value" column to 2 decimal places

### 3.2 Statistics Panel
1. **Add new panel** → **"Stat"**
2. **Query**:
   ```sql
   SELECT COUNT(*) FROM "can_data" WHERE time > now() - 1h
   ```
3. **Panel Title**: "Records (Last Hour)"
4. **Value Options**: 
   - Unit: "short"
   - Color mode: "Background"

### 3.3 Gauge Panel
1. **Add new panel** → **"Gauge"**
2. **Query**:
   ```sql
   SELECT MEAN("value") FROM "can_data" 
   WHERE "label" = 'VehicleSpeed' 
   AND time > now() - 5m
   ```
3. **Panel Title**: "Average Speed (5 min)"
4. **Gauge Options**:
   - Min: 0, Max: 200
   - Thresholds: Green (0-60), Yellow (60-120), Red (120+)

## ⚙️ Step 4: Dashboard Settings

### 4.1 Time Range
1. **Top right corner** → **Time picker**
2. **Set to**: "Last 1 hour" or "Last 6 hours"
3. **Auto-refresh**: Set to 5s or 10s for real-time updates

### 4.2 Variables (Optional)
1. **Dashboard Settings** → **Variables**
2. **Add Variable**:
   - Name: `can_id`
   - Type: "Query"
   - Query: `SHOW TAG VALUES FROM "can_data" WITH KEY = "can_id"`
   - Label: "CAN ID Filter"

### 4.3 Panel Queries with Variables
```sql
-- Use variable in queries
SELECT "value" FROM "can_data" 
WHERE "can_id" = '$can_id' 
AND time > now() - 1h
```

## 🔧 Step 5: Troubleshooting Common Issues

### 5.1 No Data Showing
- **Check time range**: Ensure it includes when you sent data
- **Verify query syntax**: Test query in Explore view first
- **Check data exists**: Use InfluxDB CLI to verify data
- **Refresh dashboard**: Click refresh button or wait for auto-refresh

### 5.2 Wrong Data Values
- **Check units**: Verify Y-axis units match your data
- **Check scaling**: Ensure values aren't being multiplied/divided
- **Verify data types**: Ensure numeric fields are numbers, not strings

### 5.3 Performance Issues
- **Limit query time range**: Use shorter time periods for large datasets
- **Add LIMIT clause**: Restrict number of returned records
- **Use aggregation functions**: `MEAN()`, `MAX()`, `MIN()` for trends

## 📱 Step 6: Mobile-Friendly Dashboard

### 6.1 Responsive Layout
1. **Dashboard Settings** → **General**
2. **Tags**: Add relevant tags for organization
3. **Panel Layout**: Use grid layout for mobile compatibility

### 6.2 Mobile Optimization
1. **Panel sizes**: Ensure panels fit mobile screens
2. **Touch-friendly**: Large enough buttons and controls
3. **Readable text**: Appropriate font sizes for mobile

## 🚀 Step 7: Advanced Features

### 7.1 Annotations
1. **Add annotation**: Mark important events on timeline
2. **Query annotations**: Automatically mark data points
3. **Manual annotations**: Add notes for specific time periods

### 7.2 Alerting
1. **Create alerts**: Set thresholds for critical values
2. **Notification channels**: Email, Slack, or webhook notifications
3. **Alert rules**: Define when alerts should trigger

### 7.3 Export/Import
1. **Export dashboard**: Save as JSON file
2. **Import dashboard**: Share with team members
3. **Version control**: Track dashboard changes

## 📊 Step 8: Sample Dashboard Queries

### Basic Queries
```sql
-- All data from last hour
SELECT * FROM "can_data" WHERE time > now() - 1h

-- Count by label
SELECT COUNT(*) FROM "can_data" GROUP BY "label"

-- Average values by minute
SELECT MEAN("value") FROM "can_data" 
WHERE time > now() - 1h 
GROUP BY time(1m), "label"
```

### Advanced Queries
```sql
-- Moving average (5-point window)
SELECT MOVING_AVERAGE("value", 5) FROM "can_data" 
WHERE "label" = 'VehicleSpeed' 
AND time > now() - 1h

-- Percentile values
SELECT PERCENTILE("value", 95) FROM "can_data" 
WHERE "label" = 'CylinderPressure' 
AND time > now() - 1h

-- Data rate (records per second)
SELECT COUNT(*) FROM "can_data" 
WHERE time > now() - 1h 
GROUP BY time(1s)
```

## ✅ Step 9: Testing Your Dashboard

### 9.1 Send Test Data
```bash
# Send test CAN data via MQTT
mosquitto_pub -h 192.168.12.1 -t "csv/file" -m "0.214010,d7,2800000000000000df11
0.214030,d7,2800000000000000df12
0.216030,101,288800001c000000ae14"
```

### 9.2 Verify Real-time Updates
1. **Watch dashboard panels** for new data points
2. **Check auto-refresh** is working
3. **Verify time range** includes current time

### 9.3 Validate Data Accuracy
1. **Compare with Node-RED logs**
2. **Check InfluxDB directly**
3. **Verify calculations** match expected values

## 🎯 Step 10: Dashboard Best Practices

### 10.1 Organization
- **Logical grouping**: Group related panels together
- **Clear titles**: Descriptive panel and dashboard names
- **Consistent styling**: Use consistent colors and fonts

### 10.2 Performance
- **Efficient queries**: Use appropriate time ranges and limits
- **Caching**: Leverage Grafana's query caching
- **Background refresh**: Set appropriate refresh intervals

### 10.3 User Experience
- **Intuitive layout**: Arrange panels logically
- **Clear labels**: Use descriptive axis and panel labels
- **Responsive design**: Ensure mobile compatibility

## 🔗 Additional Resources

- **Grafana Documentation**: https://grafana.com/docs/
- **InfluxDB Query Language**: https://docs.influxdata.com/influxdb/v1.8/query_language/
- **Node-RED InfluxDB Node**: https://flows.nodered.org/node/node-red-contrib-influxdb

## 📝 Troubleshooting Checklist

- [ ] InfluxDB container running
- [ ] Database `edge_data` exists
- [ ] Data flowing from Node-RED
- [ ] Grafana datasource configured
- [ ] Time range includes data period
- [ ] Query syntax correct
- [ ] Panel types appropriate
- [ ] Auto-refresh enabled
- [ ] Mobile compatibility checked

---

**Note**: This guide assumes you're using InfluxDB 1.x. If using InfluxDB 2.x, some query syntax may differ.
