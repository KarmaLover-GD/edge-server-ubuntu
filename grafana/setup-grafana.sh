#!/bin/bash

echo "🔧 Setting up Grafana dashboard and datasource..."

# Create necessary directories
echo "Creating Grafana directories..."
mkdir -p provisioning/datasources
mkdir -p provisioning/dashboards
mkdir -p dashboards

# Copy configuration files if they exist
if [ -f provisioning/datasources/influxdb.yml ]; then
    echo "Datasource config already exists"
else
    echo "Creating datasource configuration..."
    cat > provisioning/datasources/influxdb.yml << 'EOF'
apiVersion: 1

datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    database: edge_data
    user: admin
    secureJsonData:
      password: admin123
    jsonData:
      httpMethod: POST
      httpHeaders:
        - name: Authorization
          value: Basic YWRtaW46YWRtaW4xMjM=
      version: InfluxQL
      timeInterval: 5s
EOF
fi

if [ -f provisioning/dashboards/dashboard.yml ]; then
    echo "Dashboard config already exists"
else
    echo "Creating dashboard configuration..."
    cat > provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF
fi

if [ -f dashboards/can_data_dashboard.json ]; then
    echo "Dashboard already exists"
else
    echo "Creating CAN data dashboard..."
    cat > dashboards/can_data_dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "CAN Data Dashboard",
    "tags": ["can", "vehicle", "telemetry"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Cylinder Pressure",
        "type": "graph",
        "targets": [
          {
            "query": "SELECT mean(\"value\") FROM \"can_data\" WHERE \"label\" = 'CylinderPressure' AND $timeFilter GROUP BY time($__interval)",
            "rawQuery": true,
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 10,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "vis": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": false,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": 80
                }
              ]
            },
            "unit": "pressurembar"
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "yAxes": [
          {
            "label": "Pressure (MPa)",
            "min": 0
          }
        ]
      },
      {
        "id": 2,
        "title": "Vehicle Speed",
        "type": "graph",
        "targets": [
          {
            "query": "SELECT mean(\"value\") FROM \"can_data\" WHERE \"label\" = 'VehicleSpeed' AND $timeFilter GROUP BY time($__interval)",
            "rawQuery": true,
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 10,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "vis": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "never",
              "spanNulls": false,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  },
                  {
                    "color": "yellow",
                    "value": 80
                  },
                  {
                    "color": "red",
                    "value": 120
                  }
                ]
              }
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "yellow",
                  "value": 80
                },
                {
                  "color": "red",
                  "value": 120
                }
              ]
            },
            "unit": "velocitykmh"
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "yAxes": [
          {
            "label": "Speed (km/h)",
            "min": 0
          }
        ]
      },
      {
        "id": 3,
        "title": "Data Statistics",
        "type": "stat",
        "targets": [
          {
            "query": "SELECT count(\"value\") FROM \"can_data\" WHERE $timeFilter",
            "rawQuery": true,
            "refId": "A"
          },
          {
            "query": "SELECT count(\"value\") FROM \"can_data\" WHERE \"label\" = 'CylinderPressure' AND $timeFilter",
            "rawQuery": true,
            "refId": "B"
          },
          {
            "query": "SELECT count(\"value\") FROM \"can_data\" WHERE \"label\" = 'VehicleSpeed' AND $timeFilter",
            "rawQuery": true,
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            }
          }
        },
        "gridPos": {
          "h": 4,
          "w": 24,
          "x": 0,
          "y": 8
        },
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "textMode": "auto"
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "timepicker": {
      "refresh_intervals": [
        "5s",
        "10s",
        "30s",
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "1d"
      ]
    },
    "templating": {
      "list": []
    },
    "annotations": {
      "list": []
    },
    "refresh": "5s",
    "schemaVersion": 27,
    "version": 1,
    "links": []
  }
}
EOF
fi

echo "✅ Grafana setup complete!"
echo ""
echo "📊 Configuration files created:"
echo "  - Datasource: provisioning/datasources/influxdb.yml"
echo "  - Dashboard config: provisioning/dashboards/dashboard.yml"
echo "  - CAN Dashboard: dashboards/can_data_dashboard.json"
echo ""
echo "🔄 Now restart your Docker stack to apply changes:"
echo "cd ../docker"
echo "docker-compose down"
echo "docker-compose up -d"
echo ""
echo "🌐 After restart, Grafana will automatically:"
echo "  - Connect to InfluxDB database 'edge_data'"
echo "  - Load the CAN Data Dashboard"
echo "  - Display real-time charts for cylinder pressure and vehicle speed"
