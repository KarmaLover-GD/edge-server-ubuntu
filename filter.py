import csv

# --- CONFIG ---
input_file = "Message Logger Filter.csv_20250718_091005.csv"
output_file = "filtered_output.csv"
ids_to_keep = {"d7", "101"}  # Add more IDs here if needed

# --- PROCESS ---
with open(input_file, "r") as infile, open(output_file, "w", newline="") as outfile:
    reader = csv.reader(infile)
    writer = csv.writer(outfile)
    
    # Write header (optional)
    writer.writerow(["timestamp", "id", "data"])
    
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

print(f"Filtered data written to {output_file}")
