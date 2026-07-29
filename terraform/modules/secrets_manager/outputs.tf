###############################################################################
# SECRETS MANAGER MODULE - outputs.tf
###############################################################################

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = aws_kms_key.secrets.arn
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.secrets.key_id
}

output "db_credentials_secret_arn" {
  description = "ARN of the DB credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Name of the DB credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "service_secret_arns" {
  description = "Map of service name to Secrets Manager secret ARN"
  value       = { for k, v in aws_secretsmanager_secret.service_secrets : k => v.arn }
}

output "all_secret_arns" {
  description = "Flat list of all secret ARNs (for IAM policies)"
  value = concat(
    [aws_secretsmanager_secret.db_credentials.arn],
    [for v in aws_secretsmanager_secret.service_secrets : v.arn]
  )
}
