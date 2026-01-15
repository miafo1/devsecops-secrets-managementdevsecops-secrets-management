#!/bin/bash
set -e

echo "Starting Docker fix..."

# 1. Install jq if missing
if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Ensure /etc/docker directory exists
if [ ! -d "/etc/docker" ]; then
    echo "Creating /etc/docker directory..."
    sudo mkdir -p /etc/docker
fi

# 2. Configure daemon.json
echo "Configuring /etc/docker/daemon.json..."
if [ -f /etc/docker/daemon.json ]; then
    if grep -q "userland-proxy" /etc/docker/daemon.json; then
        echo "Configuration already present. Overwriting..."
        sudo jq '. + {"userland-proxy": false}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json.tmp
        sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    else
        echo "Adding userland-proxy: false..."
        sudo jq '. + {"userland-proxy": false}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json.tmp
        sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    fi
else
    echo '{"userland-proxy": false}' | sudo tee /etc/docker/daemon.json
fi

# 3. Print config
echo "Current daemon.json content:"
sudo cat /etc/docker/daemon.json

# 4. Restart Docker
echo "Attempting to restart/reload Docker..."

if command -v systemctl &> /dev/null; then
    echo "Trying systemctl..."
    sudo systemctl reload docker || sudo systemctl restart docker && echo "Success via systemctl" && exit 0
fi

if [ -f /etc/init.d/docker ]; then
    echo "Trying /etc/init.d/docker..."
    sudo /etc/init.d/docker restart && echo "Success via init.d" && exit 0
fi

echo "Trying to reload dockerd config via SIGHUP..."
PID=$(pidof dockerd)
if [ ! -z "$PID" ]; then
    sudo kill -SIGHUP $PID
    echo "Sent SIGHUP to dockerd (PID $PID). Configuration should be reloaded."
else
    echo "Could not find dockerd process. Is Docker running?"
    exit 1
fi

echo "Docker fix applied. Please wait a few seconds and try 'docker-compose up'."
