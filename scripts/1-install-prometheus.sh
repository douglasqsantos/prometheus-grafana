#!/bin/bash
##############################################
## Script to install the Prometheus
## Version: 1.0
##############################################

# Variables
PROMETHEUS_VERSION="2.17.1"
PROMETHEUS_CONF="/etc/prometheus"
PROMETHEUS_LIB="/var/lib/prometheus"
PROMETHEUS_USER="prometheus"
PROMETHEUS_GROUP="prometheus"
PROMETHEUS_PKG_NAME="prometheus-${PROMETHEUS_VERSION}.linux-amd64"
PROMETHEUS_PKG="${PROMETHEUS_PKG_NAME}.tar.gz"

# Checking if the script is running as root user
[ $(id -u) -ne "0" ] && echo "The Script need to be run as root User or Sudo. Aborting!!!" && exit 1

[ -f "/etc/debian_version" ] && PKG="apt-get"
[ -f "/etc/redhat-release" ] && PKG="yum"

## Check binaries
[ -z "$(which wget)" ] && ${PKG} -y install wget
[ -z "$(which wget)" ] && echo "Please install the wget package on your system." && exit 1


# Accessing the directory to store the packages
cd /usr/src

## Remove the old file if it exists
[ -f ${PROMETHEUS_PKG}  ] && rm -f ${PROMETHEUS_PKG} 

## Download the package
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_PKG}

# Check if the prometheus package was downloaded
if [ ! -f ${PROMETHEUS_PKG} ]; then
    echo "Error. The File was not Downloaded. Aborting !!!!"
    exit 1
fi

# Decompress the package
tar -xzvf ${PROMETHEUS_PKG}

# Check if the directory exists
[ ! -d ${PROMETHEUS_PKG_NAME} ] && echo "There is no directory. Aborting!!!" && exit 1

# Acessing the directory that store the project files
cd ${PROMETHEUS_PKG_NAME}/

# If you just want to start prometheus as root
#./prometheus --config.file=prometheus.yml

# Create Prometheus user
useradd --no-create-home --shell /bin/false ${PROMETHEUS_USER} 

# Create the directories
mkdir -p ${PROMETHEUS_CONF}
mkdir -p ${PROMETHEUS_LIB}

# Setting the ownership
chown ${PROMETHEUS_USER}:${PROMETHEUS_GROUP} ${PROMETHEUS_CONF}
chown ${PROMETHEUS_USER}:${PROMETHEUS_GROUP} ${PROMETHEUS_LIB}

# Copying the binaries
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/

# Setting the ownership of the binaries
chown ${PROMETHEUS_USER}:${PROMETHEUS_GROUP} /usr/local/bin/prometheus
chown ${PROMETHEUS_USER}:${PROMETHEUS_GROUP} /usr/local/bin/promtool

# Copying the configuration files
cp -r consoles ${PROMETHEUS_CONF}
cp -r console_libraries ${PROMETHEUS_CONF}
cp prometheus.yml ${PROMETHEUS_CONF}/prometheus.yml

# Setting the ownership of the configuration files
chown -R ${PROMETHEUS_USER}:${PROMETHEUS_GROUP} ${PROMETHEUS_CONF}/consoles
chown -R ${PROMETHEUS_USER}:${PROMETHEUS_GROUP} ${PROMETHEUS_CONF}/console_libraries

# Setting up the Systemd Service
echo "[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=${PROMETHEUS_USER}
Group=${PROMETHEUS_GROUP}
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file ${PROMETHEUS_CONF}/prometheus.yml \
    --storage.tsdb.path ${PROMETHEUS_LIB}/ \
    --web.console.templates=${PROMETHEUS_CONF}/consoles \
    --web.console.libraries=${PROMETHEUS_CONF}/console_libraries

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/prometheus.service

# Reload the systemd daemon
systemctl daemon-reload

# Reload Enabling the Prometheus service
systemctl enable prometheus

# Starting the Prometheus service
systemctl start prometheus

# Show the status
# systemctl status prometheus
