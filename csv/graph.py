import pandas as pd
import matplotlib.pyplot as plt

# Load CSV with proper column names
df = pd.read_csv("decoded.csv", header=None, names=['Timestamp', 'ID', 'Label', 'Value', 'Unit'])

# Convert timestamp to datetime
df['Timestamp'] = pd.to_datetime(df['Timestamp'], unit='s')

# Separate measurements
cylinder = df[df['Label'] == 'CylinderPressure']
speed = df[df['Label'] == 'VehicleSpeed']

# Plotting
fig, ax1 = plt.subplots(figsize=(12, 6))

# Cylinder Pressure plot
ax1.set_xlabel('Time')
ax1.set_ylabel('Cylinder Pressure (Mpa)', color='tab:red')
ax1.plot(cylinder['Timestamp'], cylinder['Value'], color='tab:red', label='CylinderPressure')
ax1.tick_params(axis='y', labelcolor='tab:red')

# Vehicle Speed plot (secondary y-axis)
ax2 = ax1.twinx()
ax2.set_ylabel('Vehicle Speed (km/h)', color='tab:blue')
ax2.plot(speed['Timestamp'], speed['Value'], color='tab:blue', label='VehicleSpeed')
ax2.tick_params(axis='y', labelcolor='tab:blue')

# Add legends
ax1.legend(loc='upper left')
ax2.legend(loc='upper right')

plt.title('Cylinder Pressure and Vehicle Speed over Time')
plt.grid(True)
plt.tight_layout()
plt.show()
