# Ubuntu Edge Server

This project turns an Ubuntu 24.04 machine into a full edge server with:

- 📡 Wi-Fi Hotspot + DHCP + Internet Sharing (via `dnsmasq`)
- 🐳 Docker-based stack:
  - Mosquitto (MQTT broker)
  - Node-RED (logic engine)
  - InfluxDB (time-series storage)
  - Grafana (dashboards)


## 📦 Requirements

- Ubuntu 20.04+ 
- Docker & Docker Compose
- sudo privileges

---

## 🚀 Setup Instructions

## 🚀 Deploy

```bash
chmod +x deploy.sh hotspot/setup-full-hotspot.sh
./deploy.sh


| Service  | Address                                              | Credentials      |
| -------- | ---------------------------------------------------- | ---------------- |
| Node-RED | [http://192.168.12.1:1880](http://192.168.12.1:1880) | N/A              |
| Grafana  | [http://192.168.12.1:3000](http://192.168.12.1:3000) | admin / admin123 |
| InfluxDB | [http://192.168.12.1:8086](http://192.168.12.1:8086) | admin / admin123 |



Send and recieve MQTT message locally : 

 server : 
    mosquitto_sub -h 127.0.0.1 -p 1883 -t test/topic

host  :
    mosquitto_pub -h 127.0.0.1 -p 1883 -t test/topic -m "Hello MQTT!"


from hotsport client: 

server : 
  mosquitto_sub -h 192.168.12.1 -p 1883 -t test/topic
client : 
  mosquitto_pub -h 192.168.12.1 -p 1883 -t test/topic -m "Hello from hotspot client!"


niveaus de QOS en MQTT 1 , 2 3  ?? 


in case of  no authorization to write csv from nodered : 

mkdir -p ./csv
sudo chown -R 1000:1000 ./csv
chmod -R 775 ./csv

in case you cannot zip or save due to authorizations on mosquitto: 
sudo chown -R $USER:$USER docker/mosquitto/data