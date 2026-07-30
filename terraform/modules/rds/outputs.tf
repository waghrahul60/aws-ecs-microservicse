###############################################################################
# RDS MODULE - outputs.tf
###############################################################################

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_host" {
  description = "RDS hostname"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "kms_key_arn" {
  description = "KMS key ARN used for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.rds.key_id
}
