# Docker Services Documentation

## 🐳 Overview

The edge server runs a complete Docker stack providing MQTT messaging, data processing, storage, and visualization capabilities. All services are orchestrated using Docker Compose for easy deployment and management.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Wi-Fi Clients │    │   IoT Devices   │    │   Local Apps    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Docker Network       │
                    │                           │
                    │  ┌─────────────────────┐  │
                    │  │     Mosquitto      │  │
                    │  │   (MQTT Broker)    │  │
                    │  │      Port 1883     │  │
                    │  └─────────┬───────────┘  │
                    │            │              │
                    │  ┌─────────▼───────────┐  │
                    │  │      Node-RED      │  │
                    │  │   (Logic Engine)   │  │
                    │  │      Port 1880     │  │
                    │  └─────────┬───────────┘  │
                    │            │              │
                    │  ┌─────────▼───────────┐  │
                    │  │      InfluxDB      │  │
                    │  │   (Time Series)    │  │
                    │  │      Port 8086     │  │
                    │  └─────────┬───────────┘  │
                    │            │              │
                    │  ┌─────────▼───────────┐  │
                    │  │      Grafana       │  │
                    │  │   (Dashboards)     │  │
                    │  │      Port 3000     │  │
                    │  └─────────────────────┘  │
                    └───────────────────────────┘
```

## 📋 Service Overview

| Service   | Image              | Port | Purpose                    | Dependencies |
|-----------|--------------------|------|----------------------------|--------------|
| Mosquitto | eclipse-mosquitto  | 1883 | MQTT message broker        | None         |
| Node-RED  | nodered/node-red   | 1880 | Visual programming         | MQTT, InfluxDB |
| InfluxDB  | influxdb:1.8       | 8086 | Time-series database       | None         |
| Grafana   | grafana/grafana    | 3000 | Data visualization         | InfluxDB     |

## 🔧 Service Details

### 1. Mosquitto (MQTT Broker)

#### Purpose
- Handles MQTT message routing between publishers and subscribers
- Provides reliable message delivery with QoS levels
- Supports both local and remote connections

#### Configuration
```yaml
mqtt:
  image: eclipse-mosquitto
  container_name: mosquitto
  ports:
    - "1883:1883"
  volumes:
    - ./mosquitto/config:/mosquitto/config
    - ./mosquitto/data:/mosquitto/data
    - ./mosquitto/log:/mosquitto/log
```

#### Mosquitto Configuration (`mosquitto.conf`)
```conf
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
listener 1883
allow_anonymous true
```

#### Features
- **Persistence**: Messages and subscriptions saved to disk
- **Logging**: Detailed logs stored in `/mosquitto/log/`
- **Anonymous Access**: No authentication required (configurable)
- **QoS Support**: All MQTT QoS levels (0, 1, 2)

### 2. Node-RED

#### Purpose
- Visual programming interface for IoT workflows
- Processes MQTT messages and data streams
- Exports data to CSV and InfluxDB
- Provides web-based dashboard capabilities

#### Configuration
```yaml
nodered:
  image: nodered/node-red
  container_name: nodered
  ports:
    - "1880:1880"
  volumes:
    - nodered_data:/data
    - csv_data:/csv
  depends_on:
    - mqtt
    - influxdb
```

#### Features
- **MQTT Nodes**: Subscribe to and publish MQTT messages
- **Data Processing**: Filter, transform, and analyze data
- **CSV Export**: Write data to CSV files for analysis
- **InfluxDB Integration**: Store time-series data
- **Web Dashboard**: Create custom dashboards
- **Flow Management**: Import/export workflows

#### Data Volumes
- **nodered_data**: Persistent storage for flows and settings
- **csv_data**: Shared volume for CSV file access

### 3. InfluxDB

#### Purpose
- Time-series database optimized for IoT metrics
- Stores timestamped data with high write performance
- Provides SQL-like query language (InfluxQL)

#### Configuration
```yaml
influxdb:
  image: influxdb:1.8
  container_name: influxdb
  ports:
    - "8086:8086"
  volumes:
    - influxdb_data:/var/lib/influxdb
  environment:
    - INFLUXDB_DB=edge_data
    - INFLUXDB_HTTP_AUTH_ENABLED=true
    - INFLUXDB_ADMIN_USER=admin
    - INFLUXDB_ADMIN_PASSWORD=admin123
    - INFLUXDB_USER=edgeuser
    - INFLUXDB_USER_PASSWORD=edgepass
```

#### Database Structure
- **Database**: `edge_data`
- **Admin User**: `admin` / `admin123`
- **Regular User**: `edgeuser` / `edgepass`
- **Authentication**: Enabled by default

#### Data Model
```sql
-- Example measurement structure
measurement: can_data
tags: device_id, message_type
fields: value, unit, quality
timestamp: automatic
```

### 4. Grafana

#### Purpose
- Web-based visualization and analytics platform
- Creates interactive dashboards from time-series data
- Provides alerting and notification capabilities

#### Configuration
```yaml
grafana:
  image: grafana/grafana
  container_name: grafana
  ports:
    - "3000:3000"
  volumes:
    - grafana_data:/var/lib/grafana
  depends_on:
    - influxdb
  environment:
    - GF_SECURITY_ADMIN_USER=admin
    - GF_SECURITY_ADMIN_PASSWORD=admin123
```

#### Features
- **Dashboard Creation**: Drag-and-drop interface
- **Data Sources**: InfluxDB integration
- **Query Editor**: InfluxQL support
- **Alerting**: Threshold-based notifications
- **User Management**: Role-based access control

## 🚀 Deployment

### Prerequisites
```bash
# Install Docker
sudo apt update
sudo apt install -y docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

### Deploy Services
```bash
# Navigate to docker directory
cd docker

# Start all services
sudo docker compose up -d

# Check service status
sudo docker compose ps

# View logs
sudo docker compose logs -f
```

### Service Management
```bash
# Start specific service
sudo docker compose up -d [service_name]

# Stop specific service
sudo docker compose stop [service_name]

# Restart specific service
sudo docker compose restart [service_name]

# View service logs
sudo docker compose logs [service_name]

# Scale service
sudo docker compose up -d --scale [service_name]=2
```

## 📊 Monitoring and Logs

### Service Status
```bash
# Check all containers
sudo docker compose ps

# Check resource usage
sudo docker stats

# Check container health
sudo docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

### Log Access
```bash
# All services
sudo docker compose logs -f

# Specific service
sudo docker compose logs -f [service_name]

# Last N lines
sudo docker compose logs --tail=100 [service_name]

# Since timestamp
sudo docker compose logs --since="2024-01-01T00:00:00" [service_name]
```

### Volume Management
```bash
# List volumes
sudo docker volume ls

# Inspect volume
sudo docker volume inspect [volume_name]

# Backup volume data
sudo docker run --rm -v [volume_name]:/data -v $(pwd):/backup alpine tar czf /backup/[volume_name].tar.gz -C /data .

# Restore volume data
sudo docker run --rm -v [volume_name]:/data -v $(pwd):/backup alpine tar xzf /backup/[volume_name].tar.gz -C /data
```

## 🔒 Security Configuration

### Default Credentials
- **InfluxDB Admin**: `admin` / `admin123`
- **InfluxDB User**: `edgeuser` / `edgepass`
- **Grafana Admin**: `admin` / `admin123`

### Security Recommendations
```bash
# Change default passwords
# Edit docker-compose.yml and update environment variables

# Enable TLS for MQTT (production)
# Add SSL certificates and update mosquitto.conf

# Restrict network access
# Use internal Docker networks instead of port exposure

# Regular security updates
sudo docker compose pull
sudo docker compose up -d
```

## 🛠️ Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check available ports
sudo netstat -tulpn | grep :1883

# Check disk space
df -h

# Check Docker logs
sudo journalctl -u docker -f
```

#### Connection Issues
```bash
# Test service connectivity
curl http://localhost:1880  # Node-RED
curl http://localhost:3000  # Grafana
curl http://localhost:8086  # InfluxDB

# Check container networking
sudo docker network ls
sudo docker network inspect docker_default
```

#### Data Persistence Issues
```bash
# Check volume permissions
sudo docker run --rm -v [volume_name]:/data alpine ls -la /data

# Fix volume permissions
sudo chown -R 1000:1000 /var/lib/docker/volumes/[volume_name]/_data

# Verify volume mounting
sudo docker inspect [container_name] | grep -A 10 "Mounts"
```

### Performance Tuning
```bash
# Increase memory limits
sudo docker compose up -d --scale [service_name]=2

# Monitor resource usage
sudo docker stats --no-stream

# Optimize InfluxDB
# Edit influxdb.conf for memory and retention settings

# Optimize Grafana
# Configure caching and query optimization
```

## 🔄 Backup and Recovery

### Backup Strategy
```bash
# Create backup script
cat << 'EOF' > backup-services.sh
#!/bin/bash
BACKUP_DIR="/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup volumes
sudo docker run --rm -v nodered_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/nodered_data.tar.gz -C /data .
sudo docker run --rm -v influxdb_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/influxdb_data.tar.gz -C /data .
sudo docker run --rm -v grafana_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/grafana_data.tar.gz -C /data .

# Backup configurations
cp -r mosquitto/config $BACKUP_DIR/
cp docker-compose.yml $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x backup-services.sh
```

### Recovery Process
```bash
# Stop services
sudo docker compose down

# Restore volumes
sudo docker run --rm -v nodered_data:/data -v $BACKUP_DIR:/backup alpine tar xzf /backup/nodered_data.tar.gz -C /data
sudo docker run --rm -v influxdb_data:/data -v $BACKUP_DIR:/backup alpine tar xzf /backup/influxdb_data.tar.gz -C /data
sudo docker run --rm -v grafana_data:/data -v $BACKUP_DIR:/backup alpine tar xzf /backup/grafana_data.tar.gz -C /data

# Restore configurations
cp -r $BACKUP_DIR/config/* mosquitto/config/
cp $BACKUP_DIR/docker-compose.yml .

# Start services
sudo docker compose up -d
```

## 📚 References

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Mosquitto Documentation](https://mosquitto.org/documentation/)
- [Node-RED Documentation](https://nodered.org/docs/)
- [InfluxDB Documentation](https://docs.influxdata.com/influxdb/v1.8/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Note**: This Docker stack is configured for development and testing. For production deployment, consider implementing proper security measures, monitoring, and backup strategies.
