# Deployment & Maintenance Guide

## 🚀 Complete Deployment Guide

### Prerequisites

#### System Requirements
- **OS**: Ubuntu 20.04 LTS or later
- **Architecture**: x86_64 or ARM64
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: Minimum 20GB, Recommended 50GB+
- **Network**: Wi-Fi interface + Ethernet connection
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later

#### Hardware Recommendations
- **Processor**: Intel i3/AMD Ryzen 3 or better
- **Wi-Fi**: 802.11ac or 802.11ax support
- **Ethernet**: Gigabit Ethernet port
- **Storage**: SSD for better performance
- **Power**: Stable power supply (UPS recommended)

### Initial System Setup

#### 1. Update System
```bash
# Update package lists
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git vim htop net-tools
```

#### 2. Install Docker
```bash
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install Docker dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
docker compose version
```

#### 3. Install Additional Tools
```bash
# Install MQTT client tools
sudo apt install -y mosquitto-clients

# Install Python packages for data processing
sudo apt install -y python3 python3-pip python3-pandas python3-matplotlib

# Install monitoring tools
sudo apt install -y htop iotop nethogs
```

### Project Setup

#### 1. Clone Repository
```bash
# Clone the project
git clone https://github.com/your-username/edge-server-ubuntu.git
cd edge-server-ubuntu

# Set proper permissions
chmod +x deploy.sh cleanup-edge-server.sh
chmod +x hotspot/setup-full-hotspot.sh
```

#### 2. Configure Environment
```bash
# Create environment file
cat << EOF > .env
# Edge Server Configuration
EDGE_SERVER_IP=192.168.12.1
EDGE_SERVER_SUBNET=192.168.12.0/24
HOTSPOT_SSID=EdgeServerHotspot
HOTSPOT_PASSWORD=strongpass123

# Docker Services
NODERED_PORT=1880
GRAFANA_PORT=3000
INFLUXDB_PORT=8086
MOSQUITTO_PORT=1883

# Database Credentials
INFLUXDB_ADMIN_USER=admin
INFLUXDB_ADMIN_PASSWORD=admin123
INFLUXDB_USER=edgeuser
INFLUXDB_USER_PASSWORD=edgepass

# Grafana Credentials
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin123
EOF

# Source environment variables
source .env
```

#### 3. Pre-deployment Checks
```bash
# Check system resources
echo "=== System Resources ==="
free -h
df -h
nproc

# Check network interfaces
echo "=== Network Interfaces ==="
ip addr show
iwconfig

# Check Docker status
echo "=== Docker Status ==="
sudo systemctl status docker
docker --version
docker compose version

# Check available ports
echo "=== Port Availability ==="
sudo netstat -tulpn | grep -E ':(1880|3000|8086|1883)'
```

### Deployment Process

#### 1. Automated Deployment
```bash
# Run the main deployment script
./deploy.sh
```

#### 2. Manual Deployment Steps

**Step 1: Setup Wi-Fi Hotspot**
```bash
cd hotspot
sudo ./setup-full-hotspot.sh
cd ..
```

**Step 2: Deploy Docker Services**
```bash
cd docker
sudo docker compose up -d
cd ..
```

**Step 3: Verify Services**
```bash
# Check all containers are running
sudo docker compose ps

# Check service logs
sudo docker compose logs -f
```

#### 3. Post-deployment Verification
```bash
# Test Wi-Fi hotspot
echo "Testing Wi-Fi hotspot..."
ping -c 3 192.168.12.1

# Test MQTT connectivity
echo "Testing MQTT connectivity..."
mosquitto_sub -h 192.168.12.1 -p 1883 -t "test/topic" -C 1 &
mosquitto_pub -h 192.168.12.1 -p 1883 -t "test/topic" -m "Hello Edge Server!"

# Test web services
echo "Testing web services..."
curl -s http://192.168.12.1:1880 | head -5
curl -s http://192.168.12.1:3000 | head -5
curl -s http://192.168.12.1:8086 | head -5
```

### Configuration Management

#### 1. MQTT Configuration
```bash
# Edit Mosquitto configuration
sudo nano docker/mosquitto/config/mosquitto.conf

# Example advanced configuration
cat << EOF | sudo tee docker/mosquitto/config/mosquitto.conf
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_type error
log_type warning
log_type notice
log_type information

listener 1883
allow_anonymous true

max_connections 1000
max_inflight_messages 20
max_packet_size 268435455
message_size_limit 0

autosave_interval 1800
EOF

# Restart MQTT service
sudo docker compose restart mqtt
```

#### 2. Node-RED Configuration
```bash
# Access Node-RED configuration
# Open http://192.168.12.1:1880 in browser

# Import sample flows
# Use the provided Node-RED configuration files
cp "Nodered Conf/nodered.json" docker/nodered_data/
cp "Nodered Conf/nodered-parser.json" docker/nodered_data/
```

#### 3. InfluxDB Configuration
```bash
# Access InfluxDB CLI
sudo docker exec -it influxdb influx

# Create database and users
CREATE DATABASE edge_data
CREATE USER admin WITH PASSWORD 'admin123' WITH ALL PRIVILEGES
CREATE USER edgeuser WITH PASSWORD 'edgepass'
GRANT ALL ON edge_data TO edgeuser

# Create retention policies
CREATE RETENTION POLICY "high_res" ON "edge_data" DURATION 7d REPLICATION 1
CREATE RETENTION POLICY "hourly" ON "edge_data" DURATION 30d REPLICATION 1
CREATE RETENTION POLICY "daily" ON "edge_data" DURATION 1y REPLICATION 1

# Exit InfluxDB
exit
```

#### 4. Grafana Configuration
```bash
# Access Grafana
# Open http://192.168.12.1:3000 in browser
# Login with admin/admin123

# Add InfluxDB data source
# URL: http://influxdb:8086
# Database: edge_data
# User: edgeuser
# Password: edgepass

# Import sample dashboards
# Use the provided dashboard configurations
```

### Data Processing Setup

#### 1. Python Environment
```bash
# Install Python dependencies
pip3 install pandas matplotlib numpy

# Test Python installation
python3 -c "import pandas, matplotlib; print('Dependencies installed successfully')"
```

#### 2. Data Processing Scripts
```bash
# Test data filtering
cd Data-instructions
python3 filter.py

# Test data visualization
cd ../csv
python3 graph.py
```

#### 3. Automated Data Processing
```bash
# Create cron job for automated processing
crontab -e

# Add the following lines:
# Process data every 5 minutes
*/5 * * * * cd /path/to/edge-server-ubuntu && python3 Data-instructions/filter.py

# Generate graphs every hour
0 * * * * cd /path/to/edge-server-ubuntu/csv && python3 graph.py

# Backup data daily at 2 AM
0 2 * * * cd /path/to/edge-server-ubuntu && ./backup-data.sh
```

### Monitoring and Maintenance

#### 1. System Monitoring Scripts

**System Health Check**
```bash
#!/bin/bash
# system-health-check.sh

echo "=== Edge Server Health Check ==="
echo "Date: $(date)"
echo

# Check Docker services
echo "Docker Services:"
sudo docker compose ps
echo

# Check system resources
echo "System Resources:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{print $3/$2 * 100.0}')%"
echo "Disk Usage: $(df / | tail -1 | awk '{print $5}')"
echo

# Check network connectivity
echo "Network Status:"
ping -c 1 8.8.8.8 > /dev/null && echo "Internet: Connected" || echo "Internet: Disconnected"
ping -c 1 192.168.12.1 > /dev/null && echo "Hotspot: Active" || echo "Hotspot: Inactive"
echo

# Check service endpoints
echo "Service Endpoints:"
curl -s -o /dev/null -w "Node-RED: %{http_code}\n" http://192.168.12.1:1880
curl -s -o /dev/null -w "Grafana: %{http_code}\n" http://192.168.12.1:3000
curl -s -o /dev/null -w "InfluxDB: %{http_code}\n" http://192.168.12.1:8086
echo

echo "Health check completed at $(date)"
```

**Performance Monitoring**
```bash
#!/bin/bash
# performance-monitor.sh

LOG_FILE="/var/log/edge-server-performance.log"

# Collect performance metrics
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
mqtt_connections=$(mosquitto_sub -h localhost -t '$SYS/broker/clients/active' -C 1 2>/dev/null || echo "N/A")

# Log metrics
echo "$timestamp,CPU:$cpu_usage%,Memory:$memory_usage%,Disk:$disk_usage%,MQTT:$mqtt_connections" >> $LOG_FILE

# Check thresholds and alert
if (( $(echo "$cpu_usage > 80" | bc -l) )); then
    echo "WARNING: High CPU usage: $cpu_usage%" | logger
fi

if (( $(echo "$memory_usage > 85" | bc -l) )); then
    echo "WARNING: High memory usage: $memory_usage%" | logger
fi

if (( $(echo "$disk_usage > 90" | bc -l) )); then
    echo "WARNING: High disk usage: $disk_usage%" | logger
fi
```

#### 2. Automated Maintenance

**Daily Maintenance Script**
```bash
#!/bin/bash
# daily-maintenance.sh

echo "Starting daily maintenance at $(date)"

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Clean Docker system
echo "Cleaning Docker system..."
sudo docker system prune -f
sudo docker volume prune -f

# Rotate log files
echo "Rotating log files..."
sudo logrotate /etc/logrotate.conf

# Check disk space
echo "Checking disk space..."
df -h

# Backup important data
echo "Creating data backup..."
./backup-data.sh

echo "Daily maintenance completed at $(date)"
```

**Weekly Maintenance Script**
```bash
#!/bin/bash
# weekly-maintenance.sh

echo "Starting weekly maintenance at $(date)"

# Full system backup
echo "Creating full system backup..."
./backup-system.sh

# Database maintenance
echo "Performing database maintenance..."
sudo docker exec influxdb influx -execute "SHOW MEASUREMENTS" -database edge_data

# Security updates
echo "Checking for security updates..."
sudo unattended-upgrades --dry-run

# Performance analysis
echo "Analyzing system performance..."
./analyze-performance.sh

echo "Weekly maintenance completed at $(date)"
```

### Backup and Recovery

#### 1. Data Backup Strategy

**Automated Backup Script**
```bash
#!/bin/bash
# backup-data.sh

BACKUP_DIR="/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Starting data backup to $BACKUP_DIR"

# Backup CSV data
echo "Backing up CSV data..."
cp -r csv/ $BACKUP_DIR/

# Backup InfluxDB data
echo "Backing up InfluxDB data..."
sudo docker exec influxdb influxd backup -database edge_data -retention default /tmp/backup
sudo docker cp influxdb:/tmp/backup $BACKUP_DIR/influxdb_backup

# Backup Node-RED flows
echo "Backing up Node-RED flows..."
curl -s "http://localhost:1880/flows" > $BACKUP_DIR/nodered_flows.json

# Backup Grafana dashboards
echo "Backing up Grafana dashboards..."
curl -s "http://localhost:3000/api/search" | jq -r '.[].url' | while read url; do
    id=$(echo $url | cut -d'/' -f4)
    curl -s "http://localhost:3000/api/dashboards/uid/$id" > "$BACKUP_DIR/grafana_dashboard_$id.json"
done

# Compress backup
tar -czf "${BACKUP_DIR}.tar.gz" $BACKUP_DIR
rm -rf $BACKUP_DIR

echo "Data backup completed: ${BACKUP_DIR}.tar.gz"
```

**System Backup Script**
```bash
#!/bin/bash
# backup-system.sh

BACKUP_DIR="/backup/system/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Starting system backup to $BACKUP_DIR"

# Backup configuration files
echo "Backing up configuration files..."
sudo cp -r /etc/network/ $BACKUP_DIR/
sudo cp -r /etc/dnsmasq.conf* $BACKUP_DIR/
sudo cp -r /etc/iptables.rules $BACKUP_DIR/ 2>/dev/null || echo "No iptables rules found"

# Backup Docker configurations
echo "Backing up Docker configurations..."
cp -r docker/ $BACKUP_DIR/

# Backup scripts
echo "Backing up scripts..."
cp *.sh $BACKUP_DIR/
cp -r docs/ $BACKUP_DIR/

# Backup environment file
cp .env $BACKUP_DIR/ 2>/dev/null || echo "No .env file found"

# Compress backup
tar -czf "${BACKUP_DIR}.tar.gz" $BACKUP_DIR
rm -rf $BACKUP_DIR

echo "System backup completed: ${BACKUP_DIR}.tar.gz"
```

#### 2. Recovery Procedures

**Data Recovery**
```bash
#!/bin/bash
# recover-data.sh

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE=$1
RECOVERY_DIR="/tmp/recovery_$(date +%Y%m%d_%H%M%S)"

echo "Starting data recovery from $BACKUP_FILE"

# Extract backup
mkdir -p $RECOVERY_DIR
tar -xzf $BACKUP_FILE -C $RECOVERY_DIR

# Stop services
echo "Stopping services..."
sudo docker compose down

# Restore data
echo "Restoring data..."
cp -r $RECOVERY_DIR/csv/ ./
sudo docker run --rm -v influxdb_data:/data -v $RECOVERY_DIR/influxdb_backup:/backup alpine tar xzf /backup -C /data

# Restore Node-RED flows
echo "Restoring Node-RED flows..."
curl -X POST "http://localhost:1880/flows" \
  -H "Content-Type: application/json" \
  -d @$RECOVERY_DIR/nodered_flows.json

# Start services
echo "Starting services..."
sudo docker compose up -d

# Cleanup
rm -rf $RECOVERY_DIR

echo "Data recovery completed"
```

**System Recovery**
```bash
#!/bin/bash
# recover-system.sh

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE=$1
RECOVERY_DIR="/tmp/system_recovery_$(date +%Y%m%d_%H%M%S)"

echo "Starting system recovery from $BACKUP_FILE"

# Extract backup
mkdir -p $RECOVERY_DIR
tar -xzf $BACKUP_FILE -C $RECOVERY_DIR

# Stop services
echo "Stopping services..."
sudo docker compose down

# Restore configurations
echo "Restoring system configurations..."
sudo cp -r $RECOVERY_DIR/network/ /etc/
sudo cp -r $RECOVERY_DIR/dnsmasq.conf* /etc/
sudo cp -r $RECOVERY_DIR/iptables.rules /etc/ 2>/dev/null || echo "No iptables rules to restore"

# Restore Docker configurations
echo "Restoring Docker configurations..."
cp -r $RECOVERY_DIR/docker/ ./

# Restore scripts
echo "Restoring scripts..."
cp $RECOVERY_DIR/*.sh ./
chmod +x *.sh

# Restart network services
echo "Restarting network services..."
sudo systemctl restart dnsmasq
sudo systemctl restart NetworkManager

# Start services
echo "Starting services..."
sudo docker compose up -d

# Cleanup
rm -rf $RECOVERY_DIR

echo "System recovery completed"
```

### Troubleshooting Guide

#### Common Issues and Solutions

**1. Wi-Fi Hotspot Issues**
```bash
# Problem: Hotspot won't start
# Solution: Check Wi-Fi interface and restart NetworkManager
sudo systemctl restart NetworkManager
nmcli device status

# Problem: Clients can't connect
# Solution: Check DHCP server and firewall
sudo systemctl status dnsmasq
sudo iptables -L FORWARD -v

# Problem: No internet access
# Solution: Check IP forwarding and NAT
cat /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -L -v
```

**2. Docker Service Issues**
```bash
# Problem: Services won't start
# Solution: Check Docker daemon and logs
sudo systemctl status docker
sudo docker compose logs

# Problem: Port conflicts
# Solution: Check port usage and stop conflicting services
sudo netstat -tulpn | grep :1883
sudo lsof -i :1883

# Problem: Permission denied
# Solution: Fix file permissions
sudo chown -R $USER:$USER docker/
chmod -R 755 docker/
```

**3. Data Processing Issues**
```bash
# Problem: Python scripts fail
# Solution: Install dependencies and check Python version
pip3 install pandas matplotlib numpy
python3 --version

# Problem: CSV files not accessible
# Solution: Fix directory permissions
sudo chown -R 1000:1000 csv/
chmod -R 775 csv/

# Problem: Data not appearing in dashboards
# Solution: Check data flow and database connectivity
curl -G "http://localhost:8086/query" --data-urlencode "q=SHOW DATABASES"
```

**4. Performance Issues**
```bash
# Problem: High CPU usage
# Solution: Monitor processes and optimize
htop
sudo docker stats

# Problem: High memory usage
# Solution: Check memory usage and optimize services
free -h
sudo docker stats

# Problem: Slow response times
# Solution: Check network and optimize queries
ping -c 10 192.168.12.1
sudo docker logs influxdb | tail -20
```

### Security Considerations

#### 1. Network Security
```bash
# Configure firewall rules
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 1883/tcp  # MQTT
sudo ufw allow 1880/tcp  # Node-RED
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 8086/tcp  # InfluxDB

# Monitor network traffic
sudo tcpdump -i any -n port 1883
```

#### 2. Service Security
```bash
# Change default passwords
# Edit .env file and update credentials

# Enable MQTT authentication
# Edit mosquitto.conf and add user management

# Restrict service access
# Use internal Docker networks instead of port exposure
```

#### 3. Data Security
```bash
# Encrypt sensitive data
gpg --encrypt --recipient user@example.com sensitive_file.csv

# Regular security updates
sudo unattended-upgrades --enable

# Monitor system logs
sudo journalctl -f
```

### Performance Optimization

#### 1. System Optimization
```bash
# Optimize disk I/O
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

# Optimize network
echo 'net.core.rmem_max=16777216' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max=16777216' | sudo tee -a /etc/sysctl.conf

# Apply changes
sudo sysctl -p
```

#### 2. Docker Optimization
```bash
# Optimize Docker daemon
sudo tee /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Restart Docker
sudo systemctl restart docker
```

#### 3. Database Optimization
```sql
-- Optimize InfluxDB queries
-- Use time-based queries efficiently
-- Implement proper retention policies
-- Use continuous queries for aggregation
```

### Monitoring and Alerting

#### 1. System Monitoring
```bash
# Set up monitoring cron jobs
crontab -e

# Add monitoring jobs
*/5 * * * * /path/to/edge-server-ubuntu/system-health-check.sh
*/15 * * * * /path/to/edge-server-ubuntu/performance-monitor.sh
0 2 * * * /path/to/edge-server-ubuntu/daily-maintenance.sh
0 3 * * 0 /path/to/edge-server-ubuntu/weekly-maintenance.sh
```

#### 2. Alert Configuration
```bash
# Configure email alerts
sudo apt install -y mailutils
sudo nano /etc/postfix/main.cf

# Configure log monitoring
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Documentation and Support

#### 1. System Documentation
```bash
# Generate system documentation
echo "=== Edge Server Documentation ===" > system-docs.txt
echo "Generated: $(date)" >> system-docs.txt
echo >> system-docs.txt

# System information
echo "System Information:" >> system-docs.txt
uname -a >> system-docs.txt
echo >> system-docs.txt

# Network configuration
echo "Network Configuration:" >> system-docs.txt
ip addr show >> system-docs.txt
echo >> system-docs.txt

# Service status
echo "Service Status:" >> system-docs.txt
sudo docker compose ps >> system-docs.txt
echo >> system-docs.txt

echo "Documentation generated: system-docs.txt"
```

#### 2. Support Resources
- **Project Repository**: GitHub repository with issues and discussions
- **Documentation**: Complete documentation in `/docs/` directory
- **Logs**: System and service logs for troubleshooting
- **Community**: MQTT, Node-RED, and IoT communities for support

---

**Note**: This deployment guide provides comprehensive instructions for setting up and maintaining the edge server. Always test configurations in a development environment before deploying to production. Keep regular backups and monitor system performance to ensure reliable operation.
