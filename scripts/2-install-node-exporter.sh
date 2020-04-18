#!/bin/bash
##############################################
## Script to install the Node Exporter
## Version: 1.0
##############################################

# Variables
NODE_EXPORTER_VERSION="0.18.1"
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_GROUP="node_exporter"
NODE_EXPORTER_PKG_NAME="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"
NODE_EXPORTER_PKG="${NODE_EXPORTER_PKG_NAME}.tar.gz"

# Checking if the script is running as root user
[ $(id -u) -ne "0" ] && echo "The Script need to be run as root User or Sudo. Aborting!!!" && exit 1

[ -f "/etc/debian_version" ] && PKG="apt-get"
[ -f "/etc/redhat-release" ] && PKG="yum"

## Check binaries
[ -z "$(which wget)" ] && ${PKG} -y install wget
[ -z "$(which wget)" ] && echo "Please install the wget package on your system." && exit 1

# Accessing the directory to store the packages
cd /usr/src

# Remove the old file if it exists
[ -f ${NODE_EXPORTER_PKG}  ] && rm -f ${NODE_EXPORTER_PKG}

## Download the package
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_PKG}

# Check if the prometheus package was downloaded
if [ ! -f ${NODE_EXPORTER_PKG} ]; then
    echo "Error. The File was not Downloaded. Aborting !!!!"
    exit 1
fi

# Decompress the package
tar -xzvf ${NODE_EXPORTER_PKG}

# Check if the directory exists
[ ! -d ${NODE_EXPORTER_PKG_NAME} ] && echo "There is no directory. Aborting!!!" && exit 1

# Acessing the directory that store the project files
cd ${NODE_EXPORTER_PKG_NAME}

# Copying the binary
cp node_exporter /usr/local/bin

# Create Node Exporter user
useradd --no-create-home --shell /bin/false ${NODE_EXPORTER_USER}

# Setting the ownership
chown ${NODE_EXPORTER_USER}:${NODE_EXPORTER_GROUP} /usr/local/bin/node_exporter

# Setting up the Systemd Service
echo "[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_GROUP}
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/node_exporter.service

# Reload the systemd daemon
systemctl daemon-reload

# Reload Enabling the Prometheus service
systemctl start node_exporter

# Starting the Prometheus service
systemctl enable node_exporter

## Configuration base message
echo "Setup complete.
Add the following lines to /etc/prometheus/prometheus.yml:

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      # Change the localhost to your ip address if your Prometheus is in another host
      - targets: ['localhost:9100']
"

