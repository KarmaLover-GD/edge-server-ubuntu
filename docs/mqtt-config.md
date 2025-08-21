# MQTT Configuration Documentation

## 📡 Overview

MQTT (Message Queuing Telemetry Transport) is the core messaging protocol for the edge server, enabling reliable communication between IoT devices, sensors, and applications. The system uses Mosquitto as the MQTT broker with support for both local and remote connections.

## 🏗️ MQTT Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   IoT Devices   │    │   Wi-Fi Clients │    │   Local Apps    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │     Mosquitto Broker     │
                    │      (Port 1883)         │
                    │                           │
                    │  ┌─────────────────────┐  │
                    │  │   Message Router    │  │
                    │  │                     │  │
                    │  │ • Topic Matching    │  │
                    │  │ • QoS Management    │  │
                    │  │ • Message Store     │  │
                    │  └─────────────────────┘  │
                    └───────────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Subscribers         │
                    │                           │
                    │ • Node-RED               │
                    │ • Data Loggers           │
                    │ • Monitoring Apps        │
                    └───────────────────────────┘
```

## ⚙️ Broker Configuration

### Mosquitto Configuration (`mosquitto.conf`)

#### Basic Settings
```conf
# Enable persistence for message storage
persistence true
persistence_location /mosquitto/data/

# Logging configuration
log_dest file /mosquitto/log/mosquitto.log

# Network listener
listener 1883

# Security settings
allow_anonymous true
```

#### Advanced Configuration Options
```conf
# Connection limits
max_connections 1000
max_inflight_messages 20

# Message persistence
persistence true
persistence_location /mosquitto/data/
autosave_interval 1800

# Logging levels
log_type error
log_type warning
log_type notice
log_type information

# Performance tuning
max_packet_size 268435455
message_size_limit 0
```

### Docker Configuration
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
  restart: unless-stopped
```

## 🔌 MQTT Communication

### Connection Parameters
- **Broker Address**: `192.168.12.1` (hotspot) or `127.0.0.1` (local)
- **Port**: `1883`
- **Protocol**: MQTT v3.1.1
- **Keep Alive**: 60 seconds (default)
- **Clean Session**: true (default)

### Topic Structure
```
vehicle/
├── can/
│   ├── pressure/+/value
│   ├── speed/+/value
│   └── temperature/+/value
├── status/
│   ├── engine/+/state
│   └── battery/+/level
└── alerts/
    ├── critical/+/message
    └── warning/+/message
```

### QoS Levels
- **QoS 0**: At most once (fire and forget)
- **QoS 1**: At least once (acknowledged delivery)
- **QoS 2**: Exactly once (guaranteed delivery)

## 🚀 Usage Examples

### Local Testing

#### Subscribe to Topic
```bash
# Basic subscription
mosquitto_sub -h 127.0.0.1 -p 1883 -t "test/topic"

# Subscribe with QoS 1
mosquitto_sub -h 127.0.0.1 -p 1883 -t "test/topic" -q 1

# Subscribe to multiple topics
mosquitto_sub -h 127.0.0.1 -p 1883 -t "vehicle/+/status" -t "alerts/#"
```

#### Publish Message
```bash
# Basic publish
mosquitto_pub -h 127.0.0.1 -p 1883 -t "test/topic" -m "Hello MQTT!"

# Publish with QoS 1
mosquitto_pub -h 127.0.0.1 -p 1883 -t "test/topic" -m "Hello MQTT!" -q 1

# Publish JSON data
mosquitto_pub -h 127.0.0.1 -p 1883 -t "vehicle/can/pressure" \
  -m '{"value": 25.5, "unit": "MPa", "timestamp": "2024-01-01T10:00:00Z"}'
```

### From Hotspot Clients

#### Client Subscription
```bash
# Subscribe from Wi-Fi client
mosquitto_sub -h 192.168.12.1 -p 1883 -t "vehicle/+/status"

# Subscribe with authentication (if enabled)
mosquitto_sub -h 192.168.12.1 -p 1883 -t "vehicle/+/status" \
  -u "username" -P "password"
```

#### Client Publishing
```bash
# Publish from Wi-Fi client
mosquitto_pub -h 192.168.12.1 -p 1883 -t "vehicle/can/speed" \
  -m '{"speed": 65.2, "unit": "km/h"}'

# Publish sensor data
mosquitto_pub -h 192.168.12.1 -p 1883 -t "sensors/temperature" \
  -m "23.5"
```

## 🔧 Node-RED Integration

### MQTT Input Node
```json
{
  "id": "mqtt-input",
  "type": "mqtt in",
  "name": "CAN Data Input",
  "topic": "vehicle/can/+/value",
  "qos": 1,
  "broker": "mqtt-broker",
  "x": 100,
  "y": 100
}
```

### MQTT Output Node
```json
{
  "id": "mqtt-output",
  "type": "mqtt out",
  "name": "Processed Data Output",
  "topic": "processed/can/data",
  "qos": 1,
  "retain": false,
  "broker": "mqtt-broker",
  "x": 300,
  "y": 100
}
```

### Broker Configuration
```json
{
  "id": "mqtt-broker",
  "type": "mqtt-broker",
  "name": "Local MQTT",
  "broker": "mosquitto",
  "port": 1883,
  "clientid": "nodered-${id}",
  "usetls": false,
  "compatmode": true,
  "keepalive": 60,
  "cleansession": true,
  "birthTopic": "",
  "birthQos": 0,
  "birthPayload": "",
  "closeTopic": "",
  "closeQos": 0,
  "closePayload": "",
  "willTopic": "",
  "willQos": 0,
  "willPayload": ""
}
```

## 📊 Message Patterns

### CAN Data Messages
```json
{
  "topic": "vehicle/can/pressure/engine",
  "payload": {
    "value": 25.5,
    "unit": "MPa",
    "timestamp": "2024-01-01T10:00:00Z",
    "quality": "good",
    "source": "engine_ecu"
  }
}
```

### Status Messages
```json
{
  "topic": "vehicle/status/engine/main",
  "payload": {
    "state": "running",
    "rpm": 2500,
    "temperature": 85.2,
    "oil_pressure": 3.2,
    "timestamp": "2024-01-01T10:00:00Z"
  }
}
```

### Alert Messages
```json
{
  "topic": "vehicle/alerts/critical/engine",
  "payload": {
    "level": "critical",
    "message": "Engine temperature exceeded limit",
    "value": 120.5,
    "limit": 110.0,
    "timestamp": "2024-01-01T10:00:00Z"
  }
}
```

## 🔒 Security Configuration

### Authentication Setup
```conf
# mosquitto.conf
allow_anonymous false
password_file /mosquitto/config/passwd
acl_file /mosquitto/config/acl
```

### User Management
```bash
# Create password file
mosquitto_passwd -c /mosquitto/config/passwd admin
mosquitto_passwd /mosquitto/config/passwd user1

# Create ACL file
cat << EOF > /mosquitto/config/acl
user admin
topic readwrite #

user user1
topic read vehicle/+/status
topic write sensors/+/data
EOF
```

### TLS/SSL Configuration
```conf
# mosquitto.conf
listener 8883
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/config/server.key
cafile /mosquitto/config/certs/ca.crt
```

## 📈 Performance Tuning

### Broker Optimization
```conf
# mosquitto.conf
max_connections 1000
max_inflight_messages 20
max_packet_size 268435455
message_size_limit 0

# Memory management
autosave_interval 1800
persistence true
persistence_location /mosquitto/data/
```

### Client Optimization
```bash
# Optimize client settings
mosquitto_sub -h 192.168.12.1 -p 1883 \
  -t "vehicle/+/status" \
  -q 1 \
  -i "client-$(date +%s)" \
  -k 60 \
  -C 1000
```

## 🛠️ Troubleshooting

### Common Issues

#### Connection Refused
```bash
# Check if broker is running
sudo docker compose ps mosquitto

# Check broker logs
sudo docker compose logs mosquitto

# Verify port is open
netstat -tulpn | grep :1883
```

#### Authentication Failures
```bash
# Check password file
sudo docker exec mosquitto cat /mosquitto/config/passwd

# Verify ACL file
sudo docker exec mosquitto cat /mosquitto/config/acl

# Test with credentials
mosquitto_sub -h 192.168.12.1 -p 1883 \
  -t "test/topic" \
  -u "username" \
  -P "password"
```

#### Message Loss
```bash
# Check QoS settings
# Ensure QoS > 0 for critical messages

# Monitor broker performance
sudo docker stats mosquitto

# Check disk space
df -h /var/lib/docker/volumes/
```

### Debug Commands
```bash
# Enable verbose logging
mosquitto_sub -h 192.168.12.1 -p 1883 \
  -t "test/topic" \
  -d

# Monitor network traffic
sudo tcpdump -i any -n port 1883

# Check broker status
sudo docker exec mosquitto mosquitto_sub -h localhost -t '$SYS/broker/uptime'
```

## 📊 Monitoring and Metrics

### System Topics
```bash
# Subscribe to system topics
mosquitto_sub -h 192.168.12.1 -p 1883 -t '$SYS/#' -d

# Available metrics
$SYS/broker/uptime          # Broker uptime
$SYS/broker/clients/active  # Active clients
$SYS/broker/messages/sent   # Messages sent
$SYS/broker/messages/received # Messages received
$SYS/broker/load/messages/1min # Message rate
```

### Performance Monitoring
```bash
# Monitor message rates
watch -n 1 'mosquitto_sub -h localhost -t "\$SYS/broker/load/messages/1min" -C 1'

# Check client connections
mosquitto_sub -h localhost -t '$SYS/broker/clients/active' -C 1

# Monitor memory usage
mosquitto_sub -h localhost -t '$SYS/broker/memory/current' -C 1
```

## 🔄 Backup and Recovery

### Configuration Backup
```bash
# Backup MQTT configuration
sudo docker exec mosquitto tar czf - /mosquitto/config > mosquitto-config-backup.tar.gz

# Backup persistent data
sudo docker exec mosquitto tar czf - /mosquitto/data > mosquitto-data-backup.tar.gz
```

### Recovery Process
```bash
# Stop broker
sudo docker compose stop mosquitto

# Restore configuration
sudo docker exec mosquitto tar xzf - < mosquitto-config-backup.tar.gz

# Restore data
sudo docker exec mosquitto tar xzf - < mosquitto-data-backup.tar.gz

# Start broker
sudo docker compose start mosquitto
```

## 📚 References

- [MQTT Protocol Specification](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html)
- [Mosquitto Documentation](https://mosquitto.org/documentation/)
- [MQTT Best Practices](https://www.hivemq.com/blog/mqtt-essentials-part-1-introducing-mqtt/)
- [Node-RED MQTT Nodes](https://flows.nodered.org/node/node-red-contrib-mqtt-broker)
- [MQTT Security](https://www.hivemq.com/blog/mqtt-security-fundamentals/)

---

**Note**: This MQTT configuration is designed for development and testing environments. For production deployment, implement proper authentication, encryption, and monitoring to ensure secure and reliable message delivery.
