###############################################################################
# S3 MODULE - outputs.tf
###############################################################################

output "frontend_bucket_id" {
  description = "Frontend S3 bucket name"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "Frontend S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_regional_domain_name" {
  description = "Regional domain name for CloudFront origin"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "access_log_bucket_id" {
  description = "Access logs bucket name"
  value       = var.create_access_log_bucket ? aws_s3_bucket.access_logs[0].id : null
}

output "access_log_bucket_domain_name" {
  description = "Access logs bucket domain name (for CloudFront logging)"
  value       = var.create_access_log_bucket ? aws_s3_bucket.access_logs[0].bucket_domain_name : null
}
