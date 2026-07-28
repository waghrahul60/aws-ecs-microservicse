###############################################################################
# CLOUDFRONT MODULE - main.tf
# Creates: CloudFront distribution fronting the React app S3 bucket via OAC,
#          with WAF Web ACL association and custom cache policies
###############################################################################

# ─────────────────────────────────────────────
# Origin Access Control (OAC) for S3
# ─────────────────────────────────────────────
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${local.name_prefix}-s3-oac"
  description                       = "OAC for React frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─────────────────────────────────────────────
# Cache Policy – Static Assets (long TTL)
# ─────────────────────────────────────────────
resource "aws_cloudfront_cache_policy" "static_assets" {
  name        = "${local.name_prefix}-static-cache-policy"
  min_ttl     = 86400
  default_ttl = 604800  # 7 days
  max_ttl     = 31536000 # 1 year

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# ─────────────────────────────────────────────
# CloudFront Distribution
# ─────────────────────────────────────────────
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.name_prefix} React Frontend CDN"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = var.domain_aliases
  web_acl_id          = var.waf_web_acl_arn

  # ── Origin: S3 bucket for React static assets ──
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # ── Origin: ALB for API traffic ──
  dynamic "origin" {
    for_each = local.alb_enabled ? [1] : []
    content {
      domain_name = var.alb_dns_name
      origin_id   = local.alb_origin_id

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }

      custom_header {
        name  = "X-Custom-Header"
        value = var.alb_custom_header_value
      }
    }
  }

  # ── Default Cache Behavior: React SPA (S3) ──
  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.static_assets.id
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_router.arn
    }
  }

  # ── Ordered Cache Behavior: API (/api/*) ──
  dynamic "ordered_cache_behavior" {
    for_each = local.alb_enabled ? [1] : []
    content {
      path_pattern           = "/api/*"
      target_origin_id       = local.alb_origin_id
      viewer_protocol_policy = "https-only"
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled managed policy
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
    }
  }

  # ── Custom error responses for SPA routing ──
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    bucket          = var.access_log_bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront/${var.project}-${var.environment}/"
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cloudfront"
  })
}

# ─────────────────────────────────────────────
# CloudFront Function – SPA Router (handles deep links)
# ─────────────────────────────────────────────
resource "aws_cloudfront_function" "spa_router" {
  name    = "${local.name_prefix}-spa-router"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect all non-asset requests to index.html for React SPA routing"
  publish = true

  code = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;
      // Forward requests with file extensions as-is
      if (uri.match(/\.[a-zA-Z0-9]+$/)) {
        return request;
      }
      // Rewrite all other paths to index.html
      request.uri = '/index.html';
      return request;
    }
  EOT
}
