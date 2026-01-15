#!/bin/bash
set -e

# This script is intended to be the ENTRYPOINT or executed before the app
# It fetches secrets from Vault and exports them as env vars

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
# In a real scenario, we would use AppRole or Kubernetes Auth. 
# For this demo, we pass the token via env var or use a specialized agent.
# We'll assume VAULT_TOKEN is passed to the container for this simple demo,
# or we can use the root token for the 'dev' setup.

echo "Fetching secrets from Vault..."

# We need curl and jq
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it."
    exit 1
fi

# Fetch the secret JSON
# Note: we are using the 'vault' hostname which works inside docker-compose
SECRETS_JSON=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/secret/data/myapp/config)

# Check if we got data
errors=$(echo "$SECRETS_JSON" | jq -r '.errors[]?' 2>/dev/null)
if [ ! -z "$errors" ]; then
    echo "Error fetching secrets: $errors"
    exit 1
fi

# Extract and export variables
# We use export so the child process inherits them
export DB_PASSWORD=$(echo "$SECRETS_JSON" | jq -r '.data.data.DB_PASSWORD')
export API_KEY=$(echo "$SECRETS_JSON" | jq -r '.data.data.API_KEY')

if [ "$DB_PASSWORD" == "null" ] || [ "$API_KEY" == "null" ]; then
    echo "Failed to extract secrets."
    exit 1
fi

echo "Secrets injected successfully (in memory)."

# Execute the passed command
exec "$@"
