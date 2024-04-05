#!/usr/bin/env bash
# INSTALL DDB ON WSL WITH AN OFFICIAL UBUNTU VERSION

# Check if the script is run as root if not rerun as root
if [ "$(id -u)" != "0" ]; then
    sudo $0
    exit $?
fi
DDB_USER=${DDB_USER:-$SUDO_USER}

if [ -z "$DDB_USER" ]; then
    echo "DDB_USER is not defined or could not be detected from SUDO_USER. Set the DDB_USER variable, or run this script as your target user (must be in sudoer)."
    exit 1
fi

#Update and upgrade packages
apt-get update -y
apt-get upgrade -y

#Install and configuration of Docker
## Add Docker's official GPG key:
apt-get install ca-certificates curl make -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

## By default, the Docker daemon requires root privileges to run. To use Docker without sudo, add your user to the Docker group
usermod -aG docker $DDB_USER

## Change permissions of the Docker socket
chmod 666 /var/run/docker.sock

## Expose docker to Windows by 2375 port create as root
mkdir -p /etc/systemd/system/docker.service.d

## Create override.conf file to expose docker to Windows
echo "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock" > /etc/systemd/system/docker.service.d/override.conf

## Create daemon.json file to set default address pool
echo "{\n \"default-address-pools\": [{\"base\":\"10.199.0.0/16\", \"size\":24}]}" > /etc/docker/daemon.json

## Reload the Docker daemon
systemctl daemon-reload
## Restart Docker
systemctl restart docker

# Install and configuration of Docker Compose
DOCKER_CONFIG=${DOCKER_CONFIG:-/home/$DDB_USER/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
# Apply executable permissions to the binary
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

# Install DDB
su -c 'curl -L https://github.com/inetum-orleans/docker-devbox/raw/master/installer | bash' - $DDB_USER

# Add the HOST_IP variable to the .bashrc file
echo 'export HOST_IP=$(ip route show default | awk '\''{print $3}'\'')' >> /home/$DDB_USER/.bashrc

# Configure the global ddb.yml file
cat <<EOF > "/home/$DDB_USER/.docker-devbox/ddb.yaml"
# =======================================================================
# Generated file by inetum-orleans/docker-devbox-wsl on $(date +"%Y/%m/%d")
# Do not modify. To override, create a ddb.local.yaml file.
# =======================================================================
docker:
  ip: ${LOCAL_IP}
  debug:
    host: '\$HOST_IP'
EOF

# Configure the global ddb.local.yml file
cat <<EOF > "/home/$DDB_USER/.docker-devbox/ddb.local.yaml"
certs:
  cfssl:
    server:
      host: inetum-cfssl.azurewebsites.net
      port: 443
      ssl: true
      verify_cert: true
shell:
  aliases:
    dc: docker compose
  global_aliases:
    - dc
EOF

# Reload the .bashrc file
source /home/$DDB_USER/.bashrc