#!/bin/bash
set -e

echo "Starting Docker Daemon..."

# Try standard service command first
if command -v service &> /dev/null; then
    echo "Using 'service' command..."
    sudo service docker start || echo "Service start failed, trying direct..."
fi

# Fallback or check if running
if ! pidof dockerd > /dev/null; then
    echo "Dockerd not running. Attempting direct launch..."
    # Launch in background, redirecting logs
    sudo dockerd --config-file /etc/docker/daemon.json > /tmp/dockerd.log 2>&1 &
    
    echo "Waiting for Docker to initialize..."
    for i in {1..10}; do
        if [ -S /var/run/docker.sock ]; then
            echo "Docker socket found."
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

# Ensure permissions
if [ -S /var/run/docker.sock ]; then
    echo "Setting socket permissions..."
    sudo chmod 666 /var/run/docker.sock
    echo "Docker is up and ready."
    docker info | grep "Server Version"
else
    echo "ERROR: Docker socket /var/run/docker.sock not found. Start failed."
    echo "Check /tmp/dockerd.log for details."
    exit 1
fi
