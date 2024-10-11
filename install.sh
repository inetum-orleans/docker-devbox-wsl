#!/usr/bin/env bash
set -e
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

## Expose docker to Windows by 2375 port create as root
mkdir -p /etc/systemd/system/docker.service.d

## Create override.conf file to expose docker to Windows
### Define the string to check and add
EXPOSE_DOCKER="[Service]\nExecStart=\nExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"
### Define the path to the override.conf file
OVERRIDE_PATH="/etc/systemd/system/docker.service.d/override.conf"

### Check if the file exist or the string exists in the override.conf file
if [ ! -f "$OVERRIDE_PATH" ] || ! grep -Fxq "$EXPOSE_DOCKER" "$OVERRIDE_PATH"
then
    ### If the string does not exist, append it to the file
    echo -e "$EXPOSE_DOCKER" >> "$OVERRIDE_PATH"
fi

## Create daemon.json file to set default address pool
### Define the string to check and add
ADDRESS_POOL="{\n \"default-address-pools\": [{\"base\":\"10.199.0.0/16\", \"size\":24}]\n}"
### Define the path to the daemon.json file
DAEMON_PATH="/etc/docker/daemon.json"

### Check if the file exist or the string exists in the daemon.json file
if [ ! -f "$DAEMON_PATH" ] || ! grep -Fxq "$ADDRESS_POOL" "$DAEMON_PATH"
then
    ### If the string does not exist, append it to the file
    echo -e "$ADDRESS_POOL" >> "$DAEMON_PATH"
fi

## Reload the Docker daemon
systemctl daemon-reload
## Restart Docker
systemctl restart docker

# Check if Docker service is running
for i in {1..30}
do
    if systemctl is-active --quiet docker
    then
        echo "Docker service is running."
        break
    else
        echo "Waiting for Docker service to start... ($i/30)"
        sleep 1
    fi
done

# If Docker service is not running after 30 seconds, exit the script
if ! systemctl is-active --quiet docker
then
    echo "Error: Docker service did not start within 30 seconds."
    exit 1
fi

# Add the HOST_IP variable to the .bashrc file
echo 'export HOST_IP=$(ip route show default | awk '\''{print $3}'\'')' >> /home/$DDB_USER/.bashrc

# Install DDB
su -c 'curl -L https://github.com/inetum-orleans/docker-devbox/raw/master/installer | bash' - $DDB_USER


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
shell:
  aliases:
    dc: docker compose
  global_aliases:
    - dc
EOF

echo 'Please restart your terminal to apply the changes.'