// Fixed Decode CAN Data Function for Node-RED
// Handles both CSV strings and parsed object arrays
// Validates rows and formats data safely for InfluxDB

let rows = msg.payload;
let decoded = [];
let influxData = [];

// Debug input
node.log('Input type: ' + typeof rows);
node.log('Input length: ' + (Array.isArray(rows) ? rows.length : 'not array'));
if (Array.isArray(rows) && rows.length > 0) {
    node.log('First row: ' + JSON.stringify(rows[0]));
}

// --- Case 1: Payload is raw CSV string ---
if (typeof rows === 'string') {
    let lines = rows.split('\n').filter(line => line.trim() !== '');

    lines.forEach((line, index) => {
        if (line.includes('timestamp') || line.includes('CANID') || line.includes('CANDATA')) {
            node.log('Skipping header line: ' + line);
            return;
        }

        let parts = line.split(',');
        if (parts.length < 3) return;

        let ts = parseFloat(parts[0]);
        let id = String(parts[1] || '').toLowerCase();
        let data = String(parts[2] || '');

        if (isNaN(ts) || !id || !data || data.length < 8) {
            node.log('Skipping invalid CSV row ' + index + ': ' + line);
            return;
        }

        let bytes = [];
        for (let i = 0; i < data.length; i += 2) {
            let byte = parseInt(data.substr(i, 2), 16);
            if (!isNaN(byte)) bytes.push(byte);
        }
        if (bytes.length < 5) {
            node.log('Skipping row ' + index + ' - insufficient bytes');
            return;
        }

        if (id === "101") {
            let raw = ((bytes[3] << 2) | (bytes[4] >> 6)) & 0x3FF;
            let value = raw * 0.02;
            decoded.push({ Timestamp: ts, CANID: id, Label: "CylinderPressure", Value: value, Unit: "Mpa" });

            // For InfluxDB - SIMPLIFIED format that the node can handle
            influxData.push({
                timestamp: ts * 1000000000,  // Use 'timestamp' field
                can_id: id,
                label: "CylinderPressure",
                unit: "Mpa",
                value: value,
                raw_value: raw
            });
        } else if (id === "d7") {
            let raw = (bytes[2] << 8) | bytes[3];
            let value = raw * 0.01;
            decoded.push({ Timestamp: ts, CANID: id, Label: "VehicleSpeed", Value: value, Unit: "km/h" });

            // For InfluxDB - SIMPLIFIED format that the node can handle
            influxData.push({
                timestamp: ts * 1000000000,  // Use 'timestamp' field
                can_id: id,
                label: "VehicleSpeed",
                unit: "km/h",
                value: value,
                raw_value: raw
            });
        }
    });
}

// --- Case 2: Payload is array of objects (CSV node output) ---
else {
    if (!Array.isArray(rows)) rows = [rows];

    rows.forEach((row, index) => {
        if (typeof row !== 'object' || row === null) {
            node.log('Skipping non-object row ' + index + ': ' + JSON.stringify(row));
            return;
        }

        if (!row.timestamp || !row.CANID || !row.CANDATA) {
            node.log('Skipping empty row ' + index + ': ' + JSON.stringify(row));
            return;
        }

        let ts = parseFloat(row.timestamp);
        let id = String(row.CANID || '').toLowerCase();
        let data = String(row.CANDATA || '');

        if (isNaN(ts) || !id || !data || data.length < 8) {
            node.log('Skipping invalid object row ' + index + ': ' + JSON.stringify(row));
            return;
        }

        let bytes = [];
        for (let i = 0; i < data.length; i += 2) {
            let byte = parseInt(data.substr(i, 2), 16);
            if (!isNaN(byte)) bytes.push(byte);
        }
        if (bytes.length < 5) {
            node.log('Skipping object row ' + index + ' - insufficient bytes');
            return;
        }

        if (id === "101") {
            let raw = ((bytes[3] << 2) | (bytes[4] >> 6)) & 0x3FF;
            let value = raw * 0.02;
            decoded.push({ Timestamp: ts, CANID: id, Label: "CylinderPressure", Value: value, Unit: "Mpa" });

            // For InfluxDB - SIMPLIFIED format that the node can handle
            influxData.push({
                timestamp: ts * 1000000000,  // Use 'timestamp' field
                can_id: id,
                label: "CylinderPressure",
                unit: "Mpa",
                value: value,
                raw_value: raw
            });
        } else if (id === "d7") {
            let raw = (bytes[2] << 8) | bytes[3];
            let value = raw * 0.01;
            decoded.push({ Timestamp: ts, CANID: id, Label: "VehicleSpeed", Value: value, Unit: "km/h" });

            // For InfluxDB - SIMPLIFIED format that the node can handle
            influxData.push({
                timestamp: ts * 1000000000,  // Use 'timestamp' field
                can_id: id,
                label: "VehicleSpeed",
                unit: "km/h",
                value: value,
                raw_value: raw
            });
        }
    });
}

// Outputs
msg.payload = decoded;
msg.topic = "csv_output";

// Debug summary
node.log('Decoded records: ' + decoded.length);
node.log('InfluxDB records: ' + influxData.length);
if (influxData.length > 0) {
    node.log('InfluxDB data sample: ' + JSON.stringify(influxData[0]));
}

return [msg, { payload: influxData }];