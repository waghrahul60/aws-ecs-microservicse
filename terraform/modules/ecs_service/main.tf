###############################################################################
# ECS SERVICES MODULE - main.tf
# Creates: Task Definition, ECS Service with Service Connect, Auto Scaling,
#          ALB Target Group, and CloudWatch Alarms for each microservice
###############################################################################

# ─────────────────────────────────────────────
# CloudWatch Log Group per service
# ─────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "service" {
  name              = local.log_group
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Service = var.service_name
  })
}

# ─────────────────────────────────────────────
# ECS Task Definition
# ─────────────────────────────────────────────
resource "aws_ecs_task_definition" "this" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          name          = var.service_name
          containerPort = var.container_port
          protocol      = "tcp"
          appProtocol   = var.app_protocol
        }
      ]

      environment = var.environment_variables

      secrets = [
        for secret in var.secrets : {
          name      = secret.name
          valueFrom = secret.value_from
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.log_group
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.health_check != null ? {
        command     = var.health_check.command
        interval    = var.health_check.interval
        timeout     = var.health_check.timeout
        retries     = var.health_check.retries
        startPeriod = var.health_check.start_period
      } : null
    }
  ])

  tags = merge(var.tags, {
    Service = var.service_name
  })
}

# ─────────────────────────────────────────────
# ALB Target Group (only for externally exposed services)
# ─────────────────────────────────────────────
resource "aws_lb_target_group" "this" {
  count       = var.create_target_group ? 1 : 0
  name        = "${local.name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  tags = merge(var.tags, {
    Service = var.service_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────
# ECS Service with Service Connect
# ─────────────────────────────────────────────
resource "aws_ecs_service" "this" {
  name                               = local.name_prefix
  cluster                            = var.ecs_cluster_arn
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  health_check_grace_period_seconds  = var.create_target_group ? 60 : null
  enable_execute_command             = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  # Service Connect configuration for inter-service communication
  service_connect_configuration {
    enabled   = true
    namespace = var.service_connect_namespace_arn

    dynamic "service" {
      for_each = var.service_connect_port_name != null ? [1] : []
      content {
        port_name      = var.service_name
        discovery_name = var.service_name

        client_alias {
          port     = var.container_port
          dns_name = var.service_name
        }
      }
    }
  }

  # ALB Target Group attachment (only for externally exposed services)
  dynamic "load_balancer" {
    for_each = var.create_target_group ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  tags = merge(var.tags, {
    Service = var.service_name
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ─────────────────────────────────────────────
# Auto Scaling Target
# ─────────────────────────────────────────────
resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ─────────────────────────────────────────────
# CPU-based Auto Scaling Policy
# ─────────────────────────────────────────────
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.name_prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_scaling_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ─────────────────────────────────────────────
# Memory-based Auto Scaling Policy
# ─────────────────────────────────────────────
resource "aws_appautoscaling_policy" "memory" {
  name               = "${local.name_prefix}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_scaling_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ─────────────────────────────────────────────
# CloudWatch Alarm – High CPU
# ─────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS ${var.service_name} CPU > 80%"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.this.name
  }

  tags = var.tags
}
