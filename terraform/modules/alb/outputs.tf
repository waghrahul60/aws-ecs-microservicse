###############################################################################
# ALB MODULE - outputs.tf
###############################################################################

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB canonical hosted zone ID (for Route 53 alias)"
  value       = aws_lb.this.zone_id
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = aws_lb_listener.https.arn
}
