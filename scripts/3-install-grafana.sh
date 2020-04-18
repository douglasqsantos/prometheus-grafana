#!/bin/bash

# Install on Debian or Ubuntu https://grafana.com/docs/grafana/latest/installation/debian/
# Install on RPM-based Linux (CentOS, Fedora, OpenSuse, Red Hat) https://grafana.com/docs/grafana/latest/installation/rpm/


# Checking if the script is running as root user
[ $(id -u) -ne "0" ] && echo "The Script need to be run as root User or Sudo. Aborting!!!" && exit 1


## Installing the Grafana Server
# Check the Server is a Debian Base
if [ -f "/etc/debian_version" ]; then
  # Adding the repository
  echo 'deb https://packages.grafana.com/oss/deb stable main' >> /etc/apt/sources.list

  [ -z "$(which wget)" ] && apt-get -y install wget
  # Adding the repository key
  # curl https://packages.grafana.com/gpg.key | sudo apt-key add -
  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

  # Updating the repositories
  apt-get update

  # Adding the dependencies packages
  apt-get -y install apt-transport-https software-properties-common wget curl

  # Adding the grafana package
  apt-get -y install grafana

# Check the Server is a Red Hat Base
elif [ -f "/etc/redhat-release" ]; then
# Adding the repository
echo "[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
" > /etc/yum.repos.d/grafana.repo

  # Updating the Repositories
  yum check-update -y

  # Installing the Grafana
  yum install grafana -y

else
  echo "The script does not support the OS"
fi

# Reloading the Systemd daemon
systemctl daemon-reload

# Enabling the grafana-server
systemctl enable grafana-server

# Starting the grafana-server
systemctl start grafana-server
