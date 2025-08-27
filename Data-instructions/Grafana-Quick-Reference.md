# Grafana Quick Reference Card

## 🚀 Quick Start (5 minutes)

### 1. Create Dashboard
- **Grafana URL**: `http://192.168.12.1:3000`
- **Login**: `admin` / `admin123`
- **Click**: `+` → `Dashboard` → `Add new panel`

### 2. First Panel (Vehicle Speed)
```
Panel Type: Time series
Query: SELECT "value" FROM "can_data" WHERE "label" = 'VehicleSpeed'
Title: "Vehicle Speed (km/h)"
Y-Axis: 0 to 200 km/h
```

### 3. Second Panel (Cylinder Pressure)
```
Panel Type: Time series
Query: SELECT "value" FROM "can_data" WHERE "label" = 'CylinderPressure'
Title: "Cylinder Pressure (MPa)"
Y-Axis: 0 to 10 MPa
```

### 4. Save & Test
- **Click**: "Save dashboard"
- **Name**: "CAN Data Dashboard"
- **Send test data** (see below)

## 📊 Essential Queries

### Basic Data View
```sql
-- All recent data
SELECT * FROM "can_data" WHERE time > now() - 1h

-- Count records
SELECT COUNT(*) FROM "can_data"

-- Data by type
SELECT "value" FROM "can_data" WHERE "label" = 'VehicleSpeed'
SELECT "value" FROM "can_data" WHERE "label" = 'CylinderPressure'
```

### Aggregated Views
```sql
-- Average per minute
SELECT MEAN("value") FROM "can_data" 
WHERE time > now() - 1h 
GROUP BY time(1m), "label"

-- Max/Min values
SELECT MAX("value"), MIN("value") FROM "can_data" 
WHERE time > now() - 1h 
GROUP BY "label"
```

## 🔧 Common Panel Types

| Panel Type | Use Case | Example Query |
|------------|----------|---------------|
| **Time series** | Line graphs | `SELECT "value" FROM "can_data" WHERE "label" = 'VehicleSpeed'` |
| **Table** | Raw data view | `SELECT * FROM "can_data" ORDER BY time DESC LIMIT 20` |
| **Stat** | Single values | `SELECT COUNT(*) FROM "can_data" WHERE time > now() - 1h` |
| **Gauge** | Current status | `SELECT MEAN("value") FROM "can_data" WHERE "label" = 'VehicleSpeed' AND time > now() - 5m` |

## ⚡ Quick Fixes

### No Data Showing?
1. **Check time range**: Set to "Last 1 hour"
2. **Test query**: Use Explore view first
3. **Send test data**: See below

### Wrong Values?
1. **Check Y-axis**: Verify min/max values
2. **Check units**: Ensure correct units displayed
3. **Verify data**: Check InfluxDB directly

### Performance Issues?
1. **Limit time range**: Use shorter periods
2. **Add LIMIT**: `LIMIT 1000`
3. **Use aggregation**: `MEAN()`, `MAX()`, `MIN()`

## 🧪 Test Data Commands

### Send Test Data
```bash
# Quick test
mosquitto_pub -h 192.168.12.1 -t "csv/file" -m "0.214010,d7,2800000000000000df11"

# Multiple records
mosquitto_pub -h 192.168.12.1 -t "csv/file" -m "0.214010,d7,2800000000000000df11
0.214030,d7,2800000000000000df12
0.216030,101,288800001c000000ae14"
```

### Verify Data
```bash
# Check InfluxDB
docker exec -it CONTAINER_NAME influx -username admin -password admin123
use edge_data
SELECT COUNT(*) FROM "can_data"
```

## 📱 Dashboard Settings

### Time & Refresh
- **Time Range**: "Last 1 hour" (for testing)
- **Auto-refresh**: 5s or 10s
- **Timezone**: Local

### Layout
- **Grid**: 12 columns
- **Panel sizes**: 6x4 for time series, 4x4 for stats
- **Mobile**: Responsive layout

## 🎯 Success Checklist

- [ ] Dashboard created
- [ ] Panels showing data
- [ ] Time range correct
- [ ] Auto-refresh working
- [ ] Data updating in real-time
- [ ] Values look correct
- [ ] Mobile view works

## 🆘 Emergency Commands

### Restart Everything
```bash
cd ~/edge-server-ubuntu/docker
docker compose down
docker compose up -d
```

### Check Status
```bash
docker ps
docker logs CONTAINER_NAME
```

### Reset Grafana
```bash
# Clear Grafana data (WARNING: loses dashboards)
docker volume rm edge-server-ubuntu_grafana_data
```

---

**Need Help?** Check the full guide: `Grafana-Dashboard-Setup.md`
