terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- KMS Key for Secrets Encryption ---
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
}

# --- AWS Secrets Manager Secret ---
resource "aws_secretsmanager_secret" "app_secret" {
  name       = "devsecops-app-secret-${random_id.suffix.hex}"
  kms_key_id = aws_kms_key.secrets_key.id
}

resource "aws_secretsmanager_secret_version" "app_secret_val" {
  secret_id     = aws_secretsmanager_secret.app_secret.id
  secret_string = jsonencode({
    API_KEY = "aws-secret-manager-api-key-value"
  })
}

# --- Least Privilege IAM User for App ---
resource "aws_iam_user" "app_user" {
  name = "devsecops-app-user-${random_id.suffix.hex}"
}

resource "aws_iam_access_key" "app_user_key" {
  user = aws_iam_user.app_user.name
}

# --- IAM Policy for Reading Secret ---
resource "aws_iam_policy" "secrets_read_policy" {
  name        = "SecretsReadPolicy-${random_id.suffix.hex}"
  description = "Allow reading specific secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.app_secret.arn
      },
      {
        Effect = "Allow"
        Action = [
            "kms:Decrypt"
        ]
        Resource = aws_kms_key.secrets_key.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_read" {
  user       = aws_iam_user.app_user.name
  policy_arn = aws_iam_policy.secrets_read_policy.arn
}

# --- Outputs ---
output "secret_arn" {
  value = aws_secretsmanager_secret.app_secret.arn
}

output "app_user_access_key" {
  value     = aws_iam_access_key.app_user_key.id
  sensitive = true
}

output "app_user_secret_key" {
  value     = aws_iam_access_key.app_user_key.secret
  sensitive = true
}
