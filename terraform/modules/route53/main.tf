###############################################################################
# ROUTE53 MODULE - main.tf
# Manages Route 53 hosted zone lookup/creation, DNS alias records for
# CloudFront distribution and ALB, and ACM certificate validation records
###############################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ─────────────────────────────────────────────
# Route 53 Hosted Zone (Data Lookup or Resource)
# ─────────────────────────────────────────────
data "aws_route53_zone" "this" {
  count        = var.create_zone ? 0 : 1
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-hosted-zone"
  })
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.this[0].zone_id
}

# ─────────────────────────────────────────────
# Route 53 Alias Record – CloudFront Distribution (Apex / Subdomains)
# ─────────────────────────────────────────────
resource "aws_route53_record" "cloudfront_a" {
  for_each = var.cloudfront_domain_name != "" ? toset(var.domain_aliases) : []

  zone_id = local.zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_aaaa" {
  for_each = var.cloudfront_domain_name != "" ? toset(var.domain_aliases) : []

  zone_id = local.zone_id
  name    = each.key
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# ─────────────────────────────────────────────
# Route 53 Alias Record – ALB Direct (Internal/API subdomains)
# ─────────────────────────────────────────────
resource "aws_route53_record" "alb" {
  count = (var.alb_dns_name != "" && var.alb_domain_name != "") ? 1 : 0

  zone_id = local.zone_id
  name    = var.alb_domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }
}

# ─────────────────────────────────────────────
# ACM Certificate Request & Route 53 DNS Validation
# ─────────────────────────────────────────────
resource "aws_acm_certificate" "this" {
  count             = var.create_acm_certificate ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = var.domain_aliases

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-acm-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.create_acm_certificate ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  count                   = var.create_acm_certificate ? 1 : 0
  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
