###############################################################################
# SECURITY GROUPS MODULE - outputs.tf
###############################################################################

output "alb_sg_id" {
  description = "Security Group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_sg_id" {
  description = "Security Group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_sg_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}

output "vpc_endpoints_sg_id" {
  description = "Security Group ID for VPC Interface Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}
