// Complete Fixed Decode CAN Data Function for Node-RED
// This function handles both CSV string data and object data formats
// and properly formats data for InfluxDB storage

let rows = msg.payload;
let decoded = [];
let influxData = [];

// Debug the input
node.log('Input type: ' + typeof rows);
node.log('Input length: ' + (Array.isArray(rows) ? rows.length : 'not array'));
node.log('First row: ' + JSON.stringify(rows[0]));

// Handle CSV data - it comes as individual strings, not objects
if (typeof rows === 'string') {
    // Split the CSV string into lines and parse each line
    let lines = rows.split('\n').filter(line => line.trim() !== '');
    
    lines.forEach((line, index) => {
        // Skip header line
        if (line.includes('timestamp') || line.includes('CANID') || line.includes('CANDATA')) {
            node.log('Skipping header line: ' + line);
            return;
        }
        
        // Parse CSV line manually
        let parts = line.split(',');
        if (parts.length >= 3) {
            let ts = parseFloat(parts[0]);
            let id = String(parts[1] || '').toLowerCase();
            let data = String(parts[2] || '');
            
            node.log('Processing row ' + index + ': ts=' + ts + ', id=' + id + ', data=' + data);
            
            // Validate timestamp and data
            if (isNaN(ts) || !data || data.length < 8) {
                node.log('Skipping row ' + index + ' - invalid data: ts=' + ts + ', data=' + data);
                return;
            }

            let bytes = [];
            for (let i = 0; i < data.length; i += 2) {
                let byte = parseInt(data.substr(i, 2), 16);
                if (!isNaN(byte)) {
                    bytes.push(byte);
                }
            }
            
            // Ensure we have enough bytes
            if (bytes.length < 5) {
                node.log('Skipping row ' + index + ' - insufficient bytes: ' + bytes.length);
                return;
            }

            if (id === "101") {
                let raw = ((bytes[3] << 2) | (bytes[4] >> 6)) & 0x3FF;
                let value = raw * 0.02;
                
                // For CSV output
                decoded.push({Timestamp: ts, CANID: id, Label: "CylinderPressure", Value: value, Unit: "Mpa"});
                
                // For InfluxDB - use the proper format with measurement, tags, and fields
                influxData.push({
                    measurement: "can_data",
                    tags: {
                        can_id: id,
                        label: "CylinderPressure",
                        unit: "Mpa"
                    },
                    fields: {
                        value: value,
                        raw_value: raw
                    },
                    timestamp: ts * 1000000000
                });
                
                node.log('Processed CylinderPressure: value=' + value + ', raw=' + raw);
            }
            else if (id === "d7") {
                let raw = (bytes[2] << 8) | bytes[3];
                let value = raw * 0.01;
                
                // For CSV output
                decoded.push({Timestamp: ts, CANID: id, Label: "VehicleSpeed", Value: value, Unit: "km/h"});
                
                // For InfluxDB - use the proper format with measurement, tags, and fields
                influxData.push({
                    measurement: "can_data",
                    tags: {
                        can_id: id,
                        label: "VehicleSpeed",
                        unit: "km/h"
                    },
                    fields: {
                        value: value,
                        raw_value: raw
                    },
                    timestamp: ts * 1000000000
                });
                
                node.log('Processed VehicleSpeed: value=' + value + ', raw=' + raw);
            }
        }
    });
} else {
    // Handle array format if it comes as objects
    if (!Array.isArray(rows)) {
        rows = [rows];
    }
    
    rows.forEach((row, index) => {
        if (typeof row === 'object' && row !== null) {
            let ts = parseFloat(row.timestamp);
            let id = String(row.CANID || '').toLowerCase();
            let data = String(row.CANDATA || '');
            
            node.log('Processing object row ' + index + ': ts=' + ts + ', id=' + id + ', data=' + data);
            
            // Validate timestamp and data
            if (isNaN(ts) || !data || data.length < 8) {
                node.log('Skipping object row ' + index + ' - invalid data: ts=' + ts + ', data=' + data);
                return;
            }

            let bytes = [];
            for (let i = 0; i < data.length; i += 2) {
                let byte = parseInt(data.substr(i, 2), 16);
                if (!isNaN(byte)) {
                    bytes.push(byte);
                }
            }
            
            // Ensure we have enough bytes
            if (bytes.length < 5) {
                node.log('Skipping object row ' + index + ' - insufficient bytes: ' + bytes.length);
                return;
            }

            if (id === "101") {
                let raw = ((bytes[3] << 2) | (bytes[4] >> 6)) & 0x3FF;
                let value = raw * 0.02;
                
                // For CSV output
                decoded.push({Timestamp: ts, CANID: id, Label: "CylinderPressure", Value: value, Unit: "Mpa"});
                
                // For InfluxDB - use the proper format with measurement, tags, and fields
                influxData.push({
                    measurement: "can_data",
                    tags: {
                        can_id: id,
                        label: "CylinderPressure",
                        unit: "Mpa"
                    },
                    fields: {
                        value: value,
                        raw_value: raw
                    },
                    timestamp: ts * 1000000000
                });
                
                node.log('Processed object CylinderPressure: value=' + value + ', raw=' + raw);
            }
            else if (id === "d7") {
                let raw = (bytes[2] << 8) | bytes[3];
                let value = raw * 0.01;
                
                // For CSV output
                decoded.push({Timestamp: ts, CANID: id, Label: "VehicleSpeed", Value: value, Unit: "km/h"});
                
                // For InfluxDB - use the proper format with measurement, tags, and fields
                influxData.push({
                    measurement: "can_data",
                    tags: {
                        can_id: id,
                        label: "VehicleSpeed",
                        unit: "km/h"
                    },
                    fields: {
                        value: value,
                        raw_value: raw
                    },
                    timestamp: ts * 1000000000
                });
                
                node.log('Processed object VehicleSpeed: value=' + value + ', raw=' + raw);
            }
        } else {
            node.log('Skipping invalid object row ' + index + ': ' + JSON.stringify(row));
        }
    });
}

// Create separate messages for different outputs
msg.payload = decoded;
msg.topic = "csv_output";

// Create InfluxDB message
let influxMsg = {
    payload: influxData,
    topic: "influxdb_data"
};

// Debug output
node.log('Decoded records: ' + decoded.length);
node.log('InfluxDB records: ' + influxData.length);
if (influxData.length > 0) {
    node.log('InfluxDB data sample: ' + JSON.stringify(influxData[0]));
}

return [msg, influxMsg];
