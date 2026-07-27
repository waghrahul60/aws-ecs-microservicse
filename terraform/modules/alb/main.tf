###############################################################################
# ALB MODULE - main.tf
# Creates: Application Load Balancer (internal), listener rules routing
#          /api/service-a/, /api/service-b/, /api/service-c/ paths to
#          their respective ECS target groups, and HTTPS redirect
###############################################################################

# ─────────────────────────────────────────────
# Application Load Balancer
# ─────────────────────────────────────────────
resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = local.enable_deletion_protection
  enable_http2               = true

  access_logs {
    bucket  = var.access_log_bucket_id
    prefix  = "alb/${local.name_prefix}"
    enabled = local.access_logs_enabled
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb"
  })
}

# ─────────────────────────────────────────────
# HTTPS Listener (port 443)
# ─────────────────────────────────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  # Default: forward to frontend
  default_action {
    type             = "forward"
    target_group_arn = var.frontend_target_group_arn
  }

  tags = var.tags
}

# ─────────────────────────────────────────────
# HTTP → HTTPS Redirect
# ─────────────────────────────────────────────
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# ─────────────────────────────────────────────
# Listener Rules – Route by path prefix
# ─────────────────────────────────────────────
resource "aws_lb_listener_rule" "service_a" {
  count        = var.service_a_target_group_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = var.service_a_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/api/service-a/*"]
    }
  }
}

resource "aws_lb_listener_rule" "service_b" {
  count        = var.service_b_target_group_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = var.service_b_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/api/service-b/*"]
    }
  }
}

resource "aws_lb_listener_rule" "service_c" {
  count        = var.service_c_target_group_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = var.service_c_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/api/service-c/*"]
    }
  }
}
