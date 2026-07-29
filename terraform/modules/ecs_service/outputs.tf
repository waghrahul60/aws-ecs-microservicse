###############################################################################
# ECS SERVICES MODULE - outputs.tf
###############################################################################

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ECS service ARN"
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task definition family name"
  value       = aws_ecs_task_definition.this.family
}

output "target_group_arn" {
  description = "ALB Target Group ARN (if created)"
  value       = var.create_target_group ? aws_lb_target_group.this[0].arn : null
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.service.name
}

output "autoscaling_target_resource_id" {
  description = "Auto Scaling resource ID"
  value       = aws_appautoscaling_target.this.resource_id
}
