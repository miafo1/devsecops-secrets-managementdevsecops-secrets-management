#!/bin/bash
set -e

echo "=== Docker Diagnostic & Fix Tool ==="

# 1. Check if dockerd is running and see its flags
echo "[INFO] Dockerd Launch Flags:"
ps aux | grep dockerd | grep -v grep || echo "dockerd not running?"

# 2. Check for docker-proxy existence
echo "[INFO] Searching for docker-proxy binary..."
PROXY_PATH=$(find /usr -name docker-proxy -type f 2>/dev/null | head -n 1)

if [ ! -z "$PROXY_PATH" ]; then
    echo "[FOUND] docker-proxy found at: $PROXY_PATH"
    if [ "$PROXY_PATH" != "/usr/bin/docker-proxy" ]; then
        echo "[FIX] Creating symlink to /usr/bin/docker-proxy..."
        sudo ln -sf "$PROXY_PATH" /usr/bin/docker-proxy
        echo "[SUCCESS] Symlink created."
        exit 0
    else
        echo "[INFO] It is already at /usr/bin/docker-proxy. Strange."
    fi
else
    echo "[warn] docker-proxy NOT found in /usr."
fi

# 3. If we are here, we MUST rely on userland-proxy: false.
# But it wasn't working. Maybe CLI args override it?
echo "[INFO] Verifying daemon.json..."
sudo cat /etc/docker/daemon.json

# 4. Aggressive Restart
# If SIGHUP didn't work, we might need to kill it hard and restart.
# WARNING: This might disrupt running containers.
echo "[FIX] Attempting full restart of dockerd..."

PID=$(pidof dockerd)
if [ ! -z "$PID" ]; then
    echo "Killing dockerd (PID $PID)..."
    sudo kill -15 $PID # SIGTERM
    
    # Wait for it to die
    TIMEOUT=0
    while [ -d "/proc/$PID" ]; do
        sleep 1
        TIMEOUT=$((TIMEOUT+1))
        if [ $TIMEOUT -gt 10 ]; then
            echo "Force killing..."
            sudo kill -9 $PID
            break
        fi
    done
    
    # Restart
    # We rely on the init system or supervision to restart it, or we verify if it's dead.
    # In Codespaces, often 'docker' is an entrypoint service.
    # If we killed it, we might need to start it.
    
    echo "Checking if it auto-restarts..."
    sleep 3
    if pidof dockerd > /dev/null; then
        echo "dockerd restarted automatically."
    else
        echo "dockerd did NOT restart. Attempting to start service..."
        sudo /usr/local/share/docker-init.sh 2>/dev/null || sudo dockerd --config-file /etc/docker/daemon.json > /var/log/dockerd.log 2>&1 &
        sleep 5
    fi
else
    echo "dockerd was not running."
fi

echo "[INFO] Restart complete. Checking status..."
pidof dockerd && echo "dockerd is running."

echo "=== Please try 'docker-compose up' again ==="
