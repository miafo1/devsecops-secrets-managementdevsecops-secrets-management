#!/bin/bash
set -e

echo "Starting Docker fix (Force Reload Mode)..."

# 1. Install jq if missing
if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Ensure /etc/docker directory exists
sudo mkdir -p /etc/docker

# 2. Configure daemon.json
echo "Ensuring userland-proxy is disabled in /etc/docker/daemon.json..."
if [ -f /etc/docker/daemon.json ]; then
    sudo jq '. + {"userland-proxy": false}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json.tmp
    sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
else
    echo '{"userland-proxy": false}' | sudo tee /etc/docker/daemon.json
fi

# 3. Print config
echo "Current daemon.json content:"
sudo cat /etc/docker/daemon.json

# 4. Force Reload dockerd
echo "Forcing configuration reload via SIGHUP to dockerd..."
PID=$(pidof dockerd)

if [ -z "$PID" ]; then
    echo "dockerd process not found! Attempting to find via ps..."
    PID=$(ps aux | grep dockerd | grep -v grep | awk '{print $2}' | head -n 1)
fi

if [ ! -z "$PID" ]; then
    echo "Found dockerd PID: $PID. Sending SIGHUP..."
    sudo kill -SIGHUP $PID
    echo "Signal sent. Waiting 5 seconds for reload..."
    sleep 5
else
    echo "ERROR: Could not find dockerd process to reload."
    echo "Please try: 'sudo killall dockerd' manually if this fails."
    exit 1
fi

echo "Docker fix applied. Please try running 'docker-compose up' now."
