###############################################################################
# WAF MODULE - main.tf
# Creates: AWS WAF v2 Web ACL (us-east-1 for CloudFront) with managed rules:
#   - AWS Managed Core Rule Set
#   - Known Bad Inputs
#   - SQL Injection (AWSManagedRulesSQLiRuleSet)
#   - IP Rate Limiting
###############################################################################

# Note: WAF Web ACL for CloudFront MUST be created in us-east-1
# Use a provider alias "aws.us_east_1" when calling this module

resource "aws_wafv2_web_acl" "this" {
  provider    = aws.us_east_1
  name        = "${local.name_prefix}-waf-acl"
  description = "WAF Web ACL for ${var.project} ${var.environment} CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # ── Rule 1: AWS Managed Core Rule Set ──
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 2: Known Bad Inputs ──
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 3: SQL Injection ──
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-sql-injection"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 4: IP Rate Limiting ──
  rule {
    name     = "IPRateLimit"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_per_ip
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-waf"
  })
}

# ─────────────────────────────────────────────
# WAF Logging Configuration
# ─────────────────────────────────────────────
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  provider                = aws.us_east_1
  log_destination_configs = [var.waf_log_destination_arn]
  resource_arn            = aws_wafv2_web_acl.this.arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = "DROP"
      condition {
        action_condition {
          action = "ALLOW"
        }
      }
      requirement = "MEETS_ALL"
    }
  }
}
