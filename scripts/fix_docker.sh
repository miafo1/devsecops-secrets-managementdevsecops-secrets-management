#!/bin/bash
set -e

echo "Starting Docker fix..."

# 1. Install jq if missing (needed for JSON editing)
if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# 2. Configure daemon.json
echo "Configuring /etc/docker/daemon.json..."
if [ -f /etc/docker/daemon.json ]; then
    # Check if already set
    if grep -q "userland-proxy" /etc/docker/daemon.json; then
        echo "Configuration already present. Overwriting to be sure..."
        sudo jq '. + {"userland-proxy": false}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json.tmp
        sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    else
        echo "Adding userland-proxy: false to existing config..."
        sudo jq '. + {"userland-proxy": false}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json.tmp
        sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    fi
else
    echo "Creating new /etc/docker/daemon.json..."
    echo '{"userland-proxy": false}' | sudo tee /etc/docker/daemon.json
fi

# 3. Print config for verification
echo "Current daemon.json content:"
sudo cat /etc/docker/daemon.json

# 4. Attempt to find and link docker-proxy (fallback)
# Some distros put it in /usr/libexec/docker/cli-plugins or other places, 
# but usually it's just missing in this specific image.
# We'll skip searching for now as disabling it is the standard fix.

# 5. Restart Docker
echo "Restarting Docker service..."
sudo service docker restart
# Wait a moment
sleep 3
sudo service docker status

echo "Docker fix applied. Please try running 'docker-compose up' again."
