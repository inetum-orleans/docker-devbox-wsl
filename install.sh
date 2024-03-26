# INSTALL DDB ON WSL WITH AN OFFICIAL UBUNTU VERSION

# Check if the script is run as root if not rerun as root
if [ "$(id -u)" != "0" ]; then
   sudo $0
    exit $?
fi

#Update and upgrade packages
apt-get update -y
apt-get upgrade -y

#Install and configuration of Docker
## Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

## By default, the Docker daemon requires root privileges to run. To use Docker without sudo, add your user to the Docker group
usermod -aG docker $USER


## Change permissions of the Docker socket
chmod 666 /var/run/docker.sock

## Expose docker to Windows by 2375 port create as root
mkdir -p /etc/systemd/system/docker.service.d

## Create override.conf file to expose docker to Windows
echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock" > /etc/systemd/system/docker.service.d/override.conf

## Create daemon.json file to set default address pool
echo -e "{\n \"default-address-pools\": [{\"base\":\"10.199.0.0/16\", \"size\":24}]}" > /etc/docker/daemon.json

## Reload the Docker daemon
systemctl daemon-reload
## Restart Docker
systemctl restart docker

# Install and configuration of Docker Compose
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
# Apply executable permissions to the binary
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

# Install DDB
curl -L https://github.com/inetum-orleans/docker-devbox/raw/master/installer | bash

# Add the HOST_IP variable to the .bashrc file
echo 'export HOST_IP=$(ip route show default | awk '\''{print $3}'\'')' >> $HOME/.bashrc
