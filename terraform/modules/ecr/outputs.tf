###############################################################################
# ECR MODULE - outputs.tf
###############################################################################

output "ecr_repository_urls" {
  description = "Map of service name to ECR repository URL"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "ecr_repository_arns" {
  description = "Map of service name to ECR repository ARN"
  value       = { for k, v in aws_ecr_repository.services : k => v.arn }
}

output "ecr_repository_names" {
  description = "Map of service name to ECR repository name"
  value       = { for k, v in aws_ecr_repository.services : k => v.name }
}
