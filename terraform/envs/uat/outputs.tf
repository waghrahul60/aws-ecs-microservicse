###############################################################################
# UAT ENVIRONMENT - outputs.tf
###############################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution URL"
  value       = module.cloudfront.distribution_domain_name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = module.ecs.cluster_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for each service"
  value       = module.ecr.ecr_repository_urls
}

output "dashboard_arn" {
  description = "CloudWatch Dashboard ARN"
  value       = module.observability.dashboard_arn
}

output "sns_alarms_topic_arn" {
  description = "SNS Alarms Topic ARN"
  value       = module.observability.sns_topic_arn
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.route53.zone_id
}
