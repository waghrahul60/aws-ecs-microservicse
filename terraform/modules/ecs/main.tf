###############################################################################
# ECS MODULE - main.tf
# Creates: ECS Cluster with Service Connect namespace (app.internal)
###############################################################################

# ─────────────────────────────────────────────
# ECS Cluster (Fargate)
# ─────────────────────────────────────────────
resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cluster"
  })
}

# ─────────────────────────────────────────────
# Cluster Capacity Providers (Fargate + Fargate Spot)
# ─────────────────────────────────────────────
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ─────────────────────────────────────────────
# Service Discovery Private DNS Namespace (app.internal)
# Used by AWS Service Connect for inter-service communication
# ─────────────────────────────────────────────
resource "aws_service_discovery_private_dns_namespace" "app_internal" {
  name        = var.service_connect_namespace
  description = "Private DNS namespace for inter-microservice communication via Service Connect"
  vpc         = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${var.service_connect_namespace}"
  })
}

# ─────────────────────────────────────────────
# CloudWatch Log Group for ECS Cluster
# ─────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ecs-logs"
  })
}
