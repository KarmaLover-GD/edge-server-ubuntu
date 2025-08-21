# Data Processing Documentation

## 📊 Overview

The data processing system handles automotive CAN bus data, providing filtering, analysis, and visualization capabilities. This system is designed for real-time processing of vehicle telemetry data and supports both real-time monitoring and historical analysis.

## 🏗️ Data Flow Architecture

```
CAN Bus Data → MQTT Messages → Node-RED Processing → CSV/InfluxDB → Visualization
     ↓              ↓              ↓              ↓           ↓
  Raw CAN      Message Queue   Filtering &    Storage    Grafana
  Messages     (Mosquitto)     Parsing       (CSV/DB)   Dashboards
```

## 🔧 Core Components

### 1. CAN Data Filtering (`filter.py`)

#### Purpose
- Filters CAN bus messages based on specific message IDs
- Extracts relevant data fields for analysis
- Converts raw CAN data to structured format

#### Configuration
```python
# --- CONFIG ---
input_file = "Message Logger Filter.csv_20250718_091005.csv"
output_file = "filtered_output.csv"
ids_to_keep = {"d7", "101"}  # Add more IDs here if needed
```

#### Data Processing Logic
```python
for row in reader:
    if len(row) < 3:
        continue  # Skip malformed lines
    
    timestamp = row[0]
    msg_id = row[2]
    
    if msg_id in ids_to_keep:
        # Extract all data fields after ID
        data_fields = row[3:]
        # Join into one long hex string (no commas, no spaces)
        hex_data = "".join(data_fields)
        
        writer.writerow([timestamp, msg_id, hex_data])
```

#### Supported Message IDs
- **d7**: Cylinder pressure data
- **101**: Vehicle speed data
- **Custom**: Add additional IDs as needed

#### Output Format
```csv
timestamp,id,data
2024-01-01 10:00:00,d7,0102030405060708
2024-01-01 10:00:01,101,090A0B0C0D0E0F10
```

### 2. Data Visualization (`graph.py`)

#### Purpose
- Creates time-series plots of CAN data
- Supports multiple data types on same graph
- Provides dual y-axis for different units

#### Dependencies
```python
import pandas as pd
import matplotlib.pyplot as plt
```

#### Data Loading
```python
# Load CSV with proper column names
df = pd.read_csv("decoded.csv", header=None, 
                 names=['Timestamp', 'ID', 'Label', 'Value', 'Unit'])

# Convert timestamp to datetime
df['Timestamp'] = pd pd.to_datetime(df['Timestamp'], unit='s')
```

#### Plotting Configuration
```python
# Separate measurements by type
cylinder = df[df['Label'] == 'CylinderPressure']
speed = df[df['Label'] == 'VehicleSpeed']

# Create dual y-axis plot
fig, ax1 = plt.subplots(figsize=(12, 6))

# Primary y-axis (Cylinder Pressure)
ax1.set_xlabel('Time')
ax1.set_ylabel('Cylinder Pressure (Mpa)', color='tab:red')
ax1.plot(cylinder['Timestamp'], cylinder['Value'], 
         color='tab:red', label='CylinderPressure')

# Secondary y-axis (Vehicle Speed)
ax2 = ax1.twinx()
ax2.set_ylabel('Vehicle Speed (km/h)', color='tab:blue')
ax2.plot(speed['Timestamp'], speed['Value'], 
         color='tab:blue', label='VehicleSpeed')
```

#### Supported Data Types
- **Cylinder Pressure**: Measured in MPa
- **Vehicle Speed**: Measured in km/h
- **Custom**: Extensible for additional parameters

## 📁 Data Structure

### Input Data Format
```csv
timestamp,id,data
2024-01-01 10:00:00,d7,0102030405060708
2024-01-01 10:00:01,101,090A0B0C0D0E0F10
```

### Processed Data Format
```csv
Timestamp,ID,Label,Value,Unit
1704096000,d7,CylinderPressure,25.5,Mpa
1704096001,101,VehicleSpeed,65.2,km/h
```

### Data Fields
- **Timestamp**: Unix timestamp or ISO format
- **ID**: CAN message identifier (hex)
- **Label**: Human-readable parameter name
- **Value**: Numeric value
- **Unit**: Measurement unit

## 🚀 Usage Examples

### Basic Filtering
```bash
# Run filter script
cd Data-instructions
python3 filter.py

# Check output
head -5 filtered_output.csv
```

### Data Visualization
```bash
# Run visualization script
cd csv
python3 graph.py

# Install dependencies if needed
pip3 install pandas matplotlib
```

### Custom Message IDs
```python
# Edit filter.py to add new IDs
ids_to_keep = {"d7", "101", "202", "303"}

# Run filter
python3 filter.py
```

## 🔍 Data Analysis

### Message ID Analysis
```python
# Count messages by ID
import pandas as pd

df = pd.read_csv("filtered_output.csv")
message_counts = df['id'].value_counts()
print(message_counts)
```

### Time Series Analysis
```python
# Resample data by time intervals
df['timestamp'] = pd.to_datetime(df['timestamp'])
hourly_data = df.set_index('timestamp').resample('1H').mean()
print(hourly_data)
```

### Statistical Analysis
```python
# Basic statistics
stats = df.groupby('id')['value'].agg(['mean', 'std', 'min', 'max'])
print(stats)
```

## 🛠️ Troubleshooting

### Common Issues

#### File Not Found
```bash
# Check file paths
ls -la Data-instructions/
ls -la csv/

# Verify file names
find . -name "*.csv" -type f
```

#### Permission Errors
```bash
# Fix CSV directory permissions
mkdir -p ./csv
sudo chown -R 1000:1000 ./csv
chmod -R 775 ./csv
```

#### Data Format Issues
```bash
# Check CSV format
head -5 your_data.csv
file your_data.csv

# Validate data structure
python3 -c "
import pandas as pd
df = pd.read_csv('your_data.csv')
print(df.head())
print(df.dtypes)
"
```

#### Visualization Errors
```bash
# Install required packages
pip3 install pandas matplotlib numpy

# Check Python version
python3 --version

# Test matplotlib
python3 -c "import matplotlib.pyplot as plt; print('Matplotlib OK')"
```

### Debug Commands
```bash
# Check data file integrity
wc -l *.csv
file *.csv

# Validate CSV format
python3 -c "
import csv
with open('your_file.csv', 'r') as f:
    reader = csv.reader(f)
    for i, row in enumerate(reader):
        if i < 5:
            print(f'Row {i}: {row}')
        else:
            break
"
```

## 📊 Advanced Features

### Custom Data Processing
```python
# Add custom processing functions
def process_can_data(raw_data):
    """Custom CAN data processing"""
    processed = {}
    
    # Extract specific bytes
    processed['pressure'] = int(raw_data[0:2], 16) / 100.0
    processed['temperature'] = int(raw_data[2:4], 16) / 10.0
    processed['status'] = int(raw_data[4:6], 16)
    
    return processed

# Use in filter script
if msg_id in ids_to_keep:
    hex_data = "".join(data_fields)
    processed = process_can_data(hex_data)
    # Write processed data
```

### Multiple Output Formats
```python
# Export to different formats
import json

# JSON output
with open('output.json', 'w') as f:
    json.dump(processed_data, f, indent=2)

# Excel output
df.to_excel('output.xlsx', index=False)

# SQLite database
import sqlite3
conn = sqlite3.connect('can_data.db')
df.to_sql('can_messages', conn, if_exists='replace')
```

### Real-time Processing
```python
# Watch for new data files
import time
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class DataHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_file and event.src_path.endswith('.csv'):
            process_new_file(event.src_path)

# Set up file monitoring
observer = Observer()
observer.schedule(DataHandler(), path='.', recursive=False)
observer.start()
```

## 🔄 Data Pipeline Automation

### Automated Processing Script
```bash
#!/bin/bash
# auto-process.sh

while true; do
    # Check for new CSV files
    for file in *.csv; do
        if [ -f "$file" ] && [ ! -f "${file}.processed" ]; then
            echo "Processing $file..."
            python3 filter.py
            touch "${file}.processed"
        fi
    done
    
    # Generate updated graphs
    cd csv
    python3 graph.py
    cd ..
    
    sleep 60  # Check every minute
done
```

### Cron Job Setup
```bash
# Add to crontab
crontab -e

# Process data every 5 minutes
*/5 * * * * cd /path/to/project && python3 Data-instructions/filter.py

# Generate graphs every hour
0 * * * * cd /path/to/project/csv && python3 graph.py
```

## 📈 Performance Optimization

### Memory Management
```python
# Process large files in chunks
chunk_size = 10000
for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    process_chunk(chunk)
```

### Parallel Processing
```python
from multiprocessing import Pool

def process_file(filename):
    # Process individual file
    pass

# Process multiple files in parallel
with Pool(4) as pool:
    results = pool.map(process_file, file_list)
```

### Caching
```python
import pickle

# Cache processed data
def load_cached_data():
    try:
        with open('cache.pkl', 'rb') as f:
            return pickle.load(f)
    except FileNotFoundError:
        return None

def save_cached_data(data):
    with open('cache.pkl', 'wb') as f:
        pickle.dump(data, f)
```

## 🔒 Data Security

### Access Control
```bash
# Restrict file access
chmod 640 *.csv
chown root:data-users *.csv

# Encrypt sensitive data
gpg --encrypt --recipient user@example.com data.csv
```

### Backup Strategy
```bash
# Automated backup
#!/bin/bash
BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup data files
cp *.csv $BACKUP_DIR/
cp -r csv/ $BACKUP_DIR/

# Compress backup
tar -czf "${BACKUP_DIR}.tar.gz" $BACKUP_DIR
rm -rf $BACKUP_DIR
```

## 📚 References

- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [Matplotlib Documentation](https://matplotlib.org/)
- [CAN Bus Protocol](https://en.wikipedia.org/wiki/CAN_bus)
- [CSV Processing](https://docs.python.org/3/library/csv.html)
- [Time Series Analysis](https://pandas.pydata.org/docs/user_guide/timeseries.html)

---

**Note**: This data processing system is designed for automotive CAN bus data analysis. Ensure compliance with vehicle data privacy regulations and implement appropriate security measures for sensitive vehicle information.
