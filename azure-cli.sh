#!/usr/bin/env bash
set -e
echo "Please insert the username Azure :"
read AZ_USERNAME

echo "Please insert the Tenant Azure :"
read AZ_TENANT

echo "Please insert the password Azure :"
read -s AZ_PASSWORD

sudo apt-get update && sudo apt-get install -y curl apt-transport-https lsb-release gnupg

curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update && sudo apt-get install azure-cli

# If the azure username is set
if [ -n "$AZ_USERNAME" ]; then
  az login --service-principal --username $AZ_USERNAME -p "$AZ_PASSWORD" --tenant $AZ_TENANT

  CRONTAB_CONTENT=$(crontab -l 2>/dev/null || true)

  # Test if user crontab contains `az acr login --name ddb-azure`. If not, add it.
  if ! echo "$CRONTAB_CONTENT" | grep -q "az acr login --name ddb-azure"; then
    (echo "$CRONTAB_CONTENT"; echo "0,15,30,45 * * * * az acr login --name ddb-azure") | crontab -
    echo "Azure CLI login command added to crontab."
  fi
fi