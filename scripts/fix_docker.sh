#!/bin/bash
set -e

echo "Applying Docker fix for 'docker-proxy: no such file' error..."

# Create or update daemon.json to disable userland-proxy
if [ -f /etc/docker/daemon.json ]; then
    # Merge using jq (assuming it's installed now)
    sudo jq '. + {"userland-proxy": false}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json.tmp
    sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
else
    echo '{"userland-proxy": false}' | sudo tee /etc/docker/daemon.json
fi

echo "Restarting Docker service..."
sudo service docker restart

echo "Docker restarted. Please try running docker-compose up again."
