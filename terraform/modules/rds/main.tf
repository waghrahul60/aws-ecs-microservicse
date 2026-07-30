###############################################################################
# RDS MODULE - main.tf
# Creates: PostgreSQL RDS instance with Multi-AZ standby, subnet group,
#          parameter group, and enhanced monitoring
###############################################################################

# ─────────────────────────────────────────────
# DB Subnet Group (data tier private subnets)
# ─────────────────────────────────────────────
resource "aws_db_subnet_group" "this" {
  name        = "${local.name_prefix}-db-subnet-group"
  subnet_ids  = var.private_data_subnet_ids
  description = "RDS subnet group for ${var.project} ${var.environment}"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

# ─────────────────────────────────────────────
# DB Parameter Group (PostgreSQL tuning)
# ─────────────────────────────────────────────
resource "aws_db_parameter_group" "this" {
  name        = "${local.name_prefix}-pg-params"
  family      = "postgres${var.postgres_major_version}"
  description = "Custom parameter group for ${var.project} ${var.environment}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-pg-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────
# Enhanced Monitoring IAM Role
# ─────────────────────────────────────────────
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ─────────────────────────────────────────────
# KMS Key for RDS encryption at rest
# ─────────────────────────────────────────────
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption – ${var.project} ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-kms"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ─────────────────────────────────────────────
# PostgreSQL RDS Instance (Multi-AZ)
# ─────────────────────────────────────────────
resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-postgres"

  # Engine
  engine               = "postgres"
  engine_version       = var.postgres_engine_version
  instance_class       = var.db_instance_class
  parameter_group_name = aws_db_parameter_group.this.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  # Credentials (fetched from Secrets Manager via data source in calling module)
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false
  port                   = 5432

  # High Availability
  multi_az = var.multi_az

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot     = true
  delete_automated_backups  = false
  skip_final_snapshot       = local.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_id

  # Monitoring
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Misc
  auto_minor_version_upgrade = true
  deletion_protection        = local.deletion_protection

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-postgres"
  })

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]
}

# ─────────────────────────────────────────────
# CloudWatch Alarms for RDS
# ─────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization > 80%"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${local.name_prefix}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "RDS free storage < 10 GB"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  tags = var.tags
}
