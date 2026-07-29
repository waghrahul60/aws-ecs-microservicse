###############################################################################
# SECRETS MANAGER MODULE - main.tf
# Creates: Secrets for DB credentials, API keys, and service-to-service tokens
#          SSM Parameter Store entries for non-sensitive config
###############################################################################

# ─────────────────────────────────────────────
# KMS Key for Secrets (shared)
# ─────────────────────────────────────────────
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager – ${var.project} ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-secrets-kms"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# ─────────────────────────────────────────────
# DB Credentials Secret (PostgreSQL master)
# ─────────────────────────────────────────────
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project}/${var.environment}/db/credentials"
  description             = "PostgreSQL master credentials for ${var.project} ${var.environment}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = local.secret_recovery_window

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = 5432
    dbname   = var.db_name
    engine   = "postgres"
  })
}

# ─────────────────────────────────────────────
# Service-specific API Key Secrets
# ─────────────────────────────────────────────
resource "aws_secretsmanager_secret" "service_secrets" {
  for_each = var.service_secrets

  name                    = "${var.project}/${var.environment}/services/${each.key}"
  description             = "Application secrets for ${each.key} service"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = local.secret_recovery_window

  tags = merge(var.tags, {
    Name    = "${local.name_prefix}-${each.key}-secrets"
    Service = each.key
  })
}

resource "aws_secretsmanager_secret_version" "service_secrets" {
  for_each = var.service_secrets

  secret_id     = aws_secretsmanager_secret.service_secrets[each.key].id
  secret_string = jsonencode(each.value)
}



# ─────────────────────────────────────────────
# Secrets Manager Rotation (for DB credentials)
# ─────────────────────────────────────────────
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  count               = var.enable_secret_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
