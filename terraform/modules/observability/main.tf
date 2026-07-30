###############################################################################
# OBSERVABILITY MODULE - main.tf
# Provisions a unified CloudWatch Dashboard (ECS, ALB, RDS, CloudFront),
# SNS Alarm Notification Topic, and Infrastructure CloudWatch Alarms
###############################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ─────────────────────────────────────────────
# SNS Topic for Alarms
# ─────────────────────────────────────────────
resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-alarms-topic"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alarms-topic"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ─────────────────────────────────────────────
# CloudWatch Alarms
# ─────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count               = var.alb_arn_suffix != "" ? 1 : 0
  alarm_name          = "${local.name_prefix}-alb-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5XX errors > 10 in 1 minute"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  count               = var.db_instance_id != "" ? 1 : 0
  alarm_name          = "${local.name_prefix}-rds-low-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120 # 5 GB in bytes
  alarm_description   = "RDS free storage space < 5 GB"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = var.tags
}

# ─────────────────────────────────────────────
# Unified CloudWatch Dashboard
# ─────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, { "stat" = "Average" }],
            [".", "MemoryUtilization", ".", ".", { "stat" = "Average" }]
          ]
          period = 300
          region = var.aws_region
          title  = "ECS Cluster Overall CPU & Memory Utilization (%)"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { "stat" = "Sum" }],
            [".", "TargetResponseTime", ".", ".", { "stat" = "Average" }]
          ]
          period = 60
          region = var.aws_region
          title  = "ALB Request Count & Response Time (sec)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id, { "stat" = "Average" }],
            [".", "DatabaseConnections", ".", ".", { "stat" = "Average" }]
          ]
          period = 300
          region = var.aws_region
          title  = "RDS PostgreSQL CPU (%) & Database Connections"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { "stat" = "Sum" }],
            [".", "5xxErrorRate", ".", ".", ".", ".", { "stat" = "Average" }]
          ]
          period = 300
          region = "us-east-1"
          title  = "CloudFront Distribution Requests & 5xx Error Rate (%)"
        }
      }
    ]
  })
}
