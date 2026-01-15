#!/bin/bash
set -e

echo "Installing Terraform..."

# Ensure curl and encryption tools are present
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

# Install HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verify key fingerprint (optional but good practice)
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update apt and install Terraform
sudo apt-get update
sudo apt-get install -y terraform jq

# Verify installation
terraform -version
jq --version

echo "Terraform and prerequisites installed successfully."
