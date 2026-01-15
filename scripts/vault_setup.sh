#!/bin/bash
set -e

# Vault address
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo "Waiting for Vault..."
until curl -s $VAULT_ADDR/v1/sys/health > /dev/null; do
    sleep 1
done
echo "Vault is up."

# Enable KV v2 secrets engine at 'secret' path
# In dev mode it might be enabled by default, but let's be sure or handle error
echo "Enabling KV v2 engine..."
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "kv", "options": {"version": "2"}}' \
    $VAULT_ADDR/v1/sys/mounts/secret || echo "KV engine might already be enabled."

# Put initial secrets
echo "Putting initial secrets..."
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": {"DB_PASSWORD": "super-secure-db-password", "API_KEY": "initial-api-key"}}' \
    $VAULT_ADDR/v1/secret/data/myapp/config

echo "Secrets setup complete."
