###############################################################################
# OBSERVABILITY MODULE - outputs.tf
###############################################################################

output "sns_topic_arn" {
  description = "SNS Topic ARN for infrastructure alarms"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "CloudWatch Dashboard ARN"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}
