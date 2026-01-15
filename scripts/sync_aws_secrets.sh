#!/bin/bash
set -e

# Script to sync secrets from AWS Secrets Manager into Vault
# This demonstrates the "Sync" requirement.

# Assumes AWS Credentials are set in env or via profile
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Warning: AWS credentials not found. Sync might fail if not using instance profile."
fi

# Fetch secret ARN from Terraform output or assume name
# For demo, we assume the name pattern or pass it as argument.
SECRET_NAME=${1:-"devsecops-app-secret"}

echo "Fetching secret '$SECRET_NAME' from AWS Secrets Manager..."
AWS_SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query SecretString --output text)

if [ -z "$AWS_SECRET_JSON" ]; then
    echo "Failed to fetch secret from AWS."
    exit 1
fi

echo "Secret fetched from AWS. Injecting into Vault..."

# We assume the AWS secret is JSON. We parse it and put it into Vault.
# For simplicity, we just put the whole blob, or we could parse specific keys.
# Let's assume the AWS secret contains API_KEY.

API_KEY=$(echo "$AWS_SECRET_JSON" | jq -r '.API_KEY')

if [ "$API_KEY" != "null" ]; then
    # We patch the existing Vault secret to update the API_KEY but keep DB_PASSWORD
    curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
        --request PATCH \
        --data "{\"data\": {\"API_KEY\": \"$API_KEY\"}}" \
        $VAULT_ADDR/v1/secret/data/myapp/config
    echo "Synced API_KEY from AWS to Vault."
else
    echo "No API_KEY found in AWS secret."
fi
