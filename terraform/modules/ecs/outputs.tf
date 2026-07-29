###############################################################################
# ECS MODULE - outputs.tf
###############################################################################

output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "service_connect_namespace_arn" {
  description = "ARN of the Service Connect private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.app_internal.arn
}

output "service_connect_namespace_id" {
  description = "ID of the Service Connect private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.app_internal.id
}

output "service_connect_namespace_name" {
  description = "Name of the Service Connect private DNS namespace (e.g. app.internal)"
  value       = aws_service_discovery_private_dns_namespace.app_internal.name
}

output "ecs_log_group_name" {
  description = "CloudWatch Log Group name for ECS cluster"
  value       = aws_cloudwatch_log_group.ecs_cluster.name
}
