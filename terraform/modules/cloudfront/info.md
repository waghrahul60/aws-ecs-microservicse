# Module: `cloudfront`

> Creates a CloudFront distribution that serves the React SPA from S3 (via OAC) and optionally routes `/api/*` traffic to an ALB origin. Includes a SPA Router CloudFront Function, custom cache policies, WAF association, geo restrictions, and access logging.

---

## Usage

```hcl
module "cloudfront" {
  source = "../../modules/cloudfront"

  project     = var.project
  environment = var.environment

  # S3 origin for React frontend
  s3_bucket_regional_domain_name = module.s3.frontend_bucket_regional_domain_name

  # ALB origin for API traffic (leave empty to disable)
  alb_dns_name            = module.alb.alb_dns_name
  alb_custom_header_value = var.alb_custom_header_value  # sensitive

  # WAF (must be us-east-1 WAF Web ACL ARN)
  waf_web_acl_arn = module.waf.web_acl_arn

  # ACM Certificate (must be in us-east-1)
  acm_certificate_arn = var.cloudfront_acm_certificate_arn

  domain_aliases = var.domain_aliases  # e.g. ["staging.myapp.example.com"]
  price_class    = "PriceClass_100"

  # Optional: geo restrictions
  geo_restriction_type      = "none"
  geo_restriction_locations = []

  # Optional: access logging
  access_log_bucket_domain_name = module.s3.access_log_bucket_domain_name

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `s3_bucket_regional_domain_name` | `string` | ✅ | — | S3 regional domain for React frontend origin |
| `alb_dns_name` | `string` | | `""` | ALB DNS name for API origin (omit to disable) |
| `alb_custom_header_value` | `string` | | `""` | Secret `X-Custom-Header` value sent to ALB |
| `waf_web_acl_arn` | `string` | | `""` | WAF Web ACL ARN (must be us-east-1) |
| `acm_certificate_arn` | `string` | ✅ | — | ACM certificate ARN (must be us-east-1) |
| `domain_aliases` | `list(string)` | | `[]` | Custom domain aliases |
| `price_class` | `string` | | `"PriceClass_100"` | CloudFront price class |
| `geo_restriction_type` | `string` | | `"none"` | `none` \| `whitelist` \| `blacklist` |
| `geo_restriction_locations` | `list(string)` | | `[]` | Country codes for geo restriction |
| `access_log_bucket_domain_name` | `string` | | `""` | S3 bucket domain for CloudFront access logs |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `distribution_id` | CloudFront distribution ID |
| `distribution_arn` | CloudFront distribution ARN |
| `distribution_domain_name` | CloudFront domain name (e.g. `d1234abcd.cloudfront.net`) |
| `distribution_hosted_zone_id` | Hosted zone ID for Route 53 alias records |
| `oac_id` | Origin Access Control ID |
| `spa_function_arn` | ARN of the SPA Router CloudFront Function |

---

## Routing Behaviour

| Path | Origin | Caching |
|------|--------|---------|
| `/` and non-asset paths | S3 (index.html via CF Function) | Long TTL static cache policy |
| `*.js`, `*.css`, `*.png`, etc. | S3 | Long TTL static cache policy |
| `/api/*` | ALB (when `alb_dns_name` is set) | CachingDisabled managed policy |

---

## Notes

- **SPA Router Function**: Rewrites all non-file-extension requests to `/index.html` so React Router deep links work.
- **OAC**: The S3 bucket policy must allow the CloudFront distribution ARN. This is handled by the `s3` module.
- **ALB Custom Header**: CloudFront sends `X-Custom-Header` to the ALB; your WAF on the ALB should validate this to block direct ALB access.
- `distribution_arn` is required by the `s3` module to configure the OAC bucket policy.
