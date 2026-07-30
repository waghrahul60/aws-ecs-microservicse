# Module: `route53`

> Manages Route 53 public hosted zones, A/AAAA Alias records for CloudFront and ALB, and ACM certificate requests with automated DNS validation.

---

## Usage

```hcl
module "route53" {
  source = "../../modules/route53"

  project     = var.project
  environment = var.environment

  domain_name = "example.com"
  create_zone = false # Lookup existing zone

  domain_aliases            = ["staging.myapp.example.com"]
  cloudfront_domain_name    = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.distribution_hosted_zone_id

  alb_dns_name        = module.alb.alb_dns_name
  alb_hosted_zone_id = module.alb.alb_zone_id
  alb_domain_name     = "alb-staging.myapp.example.com"

  create_acm_certificate = true

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `domain_name` | `string` | ✅ | — | Primary domain name (e.g. `example.com`) |
| `create_zone` | `bool` | | `false` | Create a new zone vs lookup existing |
| `domain_aliases` | `list(string)` | | `[]` | Domain aliases pointing to CloudFront |
| `cloudfront_domain_name` | `string` | | `""` | CloudFront domain name |
| `cloudfront_hosted_zone_id` | `string` | | `"Z2FDTNDATAQYW2"` | CloudFront canonical zone ID |
| `alb_dns_name` | `string` | | `""` | ALB DNS name |
| `alb_hosted_zone_id` | `string` | | `""` | ALB canonical hosted zone ID |
| `alb_domain_name` | `string` | | `""` | Direct domain name for ALB |
| `create_acm_certificate` | `bool` | | `false` | Request & DNS-validate ACM certificate |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `zone_id` | Route 53 hosted zone ID |
| `zone_name` | Route 53 hosted zone name |
| `name_servers` | List of authoritative name servers |
| `acm_certificate_arn` | Validated ACM certificate ARN |
