# Edge Server Ubuntu - Complete Documentation

## 📋 Project Overview

This project transforms an Ubuntu machine into a comprehensive edge server with Wi-Fi hotspot capabilities, IoT data processing, and real-time monitoring. The system is designed for automotive CAN bus data analysis and general IoT applications.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Wi-Fi Client  │    │   Wi-Fi Client  │    │   Wi-Fi Client  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    Edge Server Ubuntu     │
                    │                           │
                    │  ┌─────────────────────┐  │
                    │  │   Wi-Fi Hotspot    │  │
                    │  │   (192.168.12.1)   │  │
                    │  └─────────┬───────────┘  │
                    │            │              │
                    │  ┌─────────▼───────────┐  │
                    │  │   Docker Stack     │  │
                    │  │                     │  │
                    │  │ • Mosquitto (MQTT) │  │
                    │  │ • Node-RED         │  │
                    │  │ • InfluxDB         │  │
                    │  │ • Grafana          │  │
                    │  └─────────────────────┘  │
                    └───────────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    Internet Connection    │
                    │    (Ethernet/WAN)        │
                    └───────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu 20.04 or later
- Docker and Docker Compose installed
- sudo privileges
- Wi-Fi interface
- Internet connection (for initial setup)

### One-Command Deployment
```bash
chmod +x deploy.sh hotspot/setup-full-hotspot.sh
./deploy.sh
```

### Access Services
| Service  | URL                                    | Credentials      |
|----------|----------------------------------------|------------------|
| Node-RED | http://192.168.12.1:1880              | N/A              |
| Grafana  | http://192.168.12.1:3000              | admin/admin123   |
| InfluxDB | http://192.168.12.1:8086              | admin/admin123   |
| Portainer| http://192.168.12.1:9000              | N/A              |

## 📁 Project Structure

```
edge-server-ubuntu/
├── 📖 README.md                    # This file - main documentation
├── 🚀 deploy.sh                    # Main deployment script
├── 🧹 cleanup-edge-server.sh       # Cleanup and restoration script
├── 📡 hotspot/                     # Wi-Fi hotspot configuration
│   └── setup-full-hotspot.sh      # Hotspot setup script
├── 🐳 docker/                      # Docker services configuration
│   ├── docker-compose.yml         # Service orchestration
│   └── mosquitto/                 # MQTT broker configuration
├── 📊 Data-instructions/           # Data processing and analysis
│   ├── README.md                  # Data processing guide
│   ├── filter.py                  # CAN data filtering script
│   └── data.csv                   # Sample data
├── 📈 csv/                         # Data visualization
│   ├── graph.py                   # Data plotting script
│   └── decoded.csv                # Processed data
└── 🔧 Nodered Conf/               # Node-RED configurations
    ├── nodered.json               # Node-RED settings
    └── nodered-parser.json        # Parser configuration
```

## 🔧 Core Components

### 1. **Wi-Fi Hotspot System**
- **Purpose**: Creates a wireless network for IoT devices
- **Network**: 192.168.12.0/24 with DHCP
- **SSID**: EdgeServerHotspot
- **Password**: strongpass123
- **Internet Sharing**: Yes (NAT from Ethernet)

### 2. **MQTT Broker (Mosquitto)**
- **Purpose**: Message queuing for IoT communication
- **Port**: 1883
- **Authentication**: Anonymous (configurable)
- **Persistence**: Yes (data stored in Docker volume)

### 3. **Node-RED**
- **Purpose**: Visual programming for IoT workflows
- **Port**: 1880
- **Features**: MQTT nodes, data processing, CSV export
- **Data Access**: Can read/write to CSV directory

### 4. **InfluxDB**
- **Purpose**: Time-series database for IoT metrics
- **Port**: 8086
- **Database**: edge_data
- **Credentials**: admin/admin123, edgeuser/edgepass

### 5. **Grafana**
- **Purpose**: Data visualization and dashboards
- **Port**: 3000
- **Credentials**: admin/admin123
- **Data Source**: InfluxDB

## 📊 Data Processing Pipeline

```
CAN Bus Data → MQTT → Node-RED → CSV/InfluxDB → Grafana
     ↓              ↓         ↓         ↓         ↓
  Raw CAN      Message    Filtering   Storage   Visualization
  Messages     Queue      & Parsing   & Query   & Alerts
```

## 🔌 MQTT Communication

### Local Testing
```bash
# Subscribe to topic
mosquitto_sub -h 127.0.0.1 -p 1883 -t test/topic

# Publish message
mosquitto_pub -h 127.0.0.1 -p 1883 -t test/topic -m "Hello MQTT!"
```

### From Hotspot Clients
```bash
# Subscribe from client
mosquitto_sub -h 192.168.12.1 -p 1883 -t test/topic

# Publish from client
mosquitto_pub -h 192.168.12.1 -p 1883 -t test/topic -m "Hello from client!"
```

## 🛠️ Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Fix CSV directory permissions
mkdir -p ./csv
sudo chown -R 1000:1000 ./csv
chmod -R 775 ./csv

# Fix Mosquitto data permissions
sudo chown -R $USER:$USER docker/mosquitto/data
```

#### Service Access Issues
- Ensure Docker containers are running: `sudo docker compose ps`
- Check service logs: `sudo docker compose logs [service_name]`
- Verify network connectivity: `ping 192.168.12.1`

### Cleanup and Restoration
```bash
./cleanup-edge-server.sh
```

## 📚 Detailed Documentation

- **[Wi-Fi Hotspot Documentation](docs/hotspot.md)** - Complete hotspot setup and configuration
- **[Docker Services Documentation](docs/docker-services.md)** - Detailed service configuration and management
- **[Data Processing Guide](docs/data-processing.md)** - CAN data analysis and visualization
- **[MQTT Configuration](docs/mqtt-config.md)** - MQTT broker setup and usage
- **[Node-RED Workflows](docs/nodered-workflows.md)** - Flow design and automation
- **[Monitoring & Dashboards](docs/monitoring.md)** - Grafana setup and InfluxDB queries

## 🔒 Security Considerations

- **Default Credentials**: Change default passwords in production
- **Network Isolation**: Hotspot is isolated from main network
- **MQTT Security**: Consider enabling authentication for production use
- **Firewall**: iptables rules configured for NAT only

## 🚀 Advanced Features

- **Internet Sharing**: Clients can access internet through server
- **Data Persistence**: All data stored in Docker volumes
- **Auto-restart**: Services restart automatically on system reboot
- **Hotspot Management**: Easy enable/disable of Wi-Fi hotspot

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the detailed component documentation
3. Check service logs for error messages
4. Ensure all prerequisites are met

---

**Last Updated**: $(date)
**Version**: 1.0.0
**Compatibility**: Ubuntu 20.04+, Docker 20.10+
