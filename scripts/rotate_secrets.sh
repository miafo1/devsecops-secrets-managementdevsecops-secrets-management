#!/bin/bash
set -e

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

NEW_DB_PASS="rotated-password-$(date +%s)"
NEW_API_KEY="rotated-key-$(date +%s)"

echo "Rotating secrets in Vault..."

curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{\"data\": {\"DB_PASSWORD\": \"$NEW_DB_PASS\", \"API_KEY\": \"$NEW_API_KEY\"}}" \
    $VAULT_ADDR/v1/secret/data/myapp/config

echo "Secrets rotated."
echo "New DB_PASSWORD suffix: ...$(echo $NEW_DB_PASS | tail -c 5)"

# In a real K8s setup, we might delete a pod to trigger restart,
# or send a SIGHUP. For Docker Compose, we might restart the app container.
echo "To apply changes, restart the application container."
