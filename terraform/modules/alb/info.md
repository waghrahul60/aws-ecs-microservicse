# Module: `alb`

> Creates an internet-facing Application Load Balancer with an HTTPS listener (TLS 1.3), HTTP→HTTPS redirect, and path-based routing rules for each microservice (`/api/service-a/*`, `/api/service-b/*`, `/api/service-c/*`). Default action forwards to the React frontend target group.

---

## Usage

```hcl
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment

  alb_sg_id         = module.security_groups.alb_sg_id
  public_subnet_ids = module.vpc.public_subnet_ids

  acm_certificate_arn = var.alb_acm_certificate_arn  # Primary region cert

  # Target group ARNs from ecs_service modules
  frontend_target_group_arn  = module.ecs_frontend.target_group_arn
  service_a_target_group_arn = module.ecs_service_a.target_group_arn
  service_b_target_group_arn = module.ecs_service_b.target_group_arn
  service_c_target_group_arn = module.ecs_service_c.target_group_arn

  # Optional: S3 access logging
  access_log_bucket_id = module.s3.access_log_bucket_id

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `alb_sg_id` | `string` | ✅ | — | ALB security group ID |
| `public_subnet_ids` | `list(string)` | ✅ | — | Public subnet IDs for ALB |
| `acm_certificate_arn` | `string` | ✅ | — | ACM certificate ARN for HTTPS listener |
| `frontend_target_group_arn` | `string` | ✅ | — | Target group ARN for React frontend |
| `service_a_target_group_arn` | `string` | | `""` | Target group ARN for Microservice A |
| `service_b_target_group_arn` | `string` | | `""` | Target group ARN for Microservice B |
| `service_c_target_group_arn` | `string` | | `""` | Target group ARN for Microservice C |
| `access_log_bucket_id` | `string` | | `""` | S3 bucket name for ALB access logs |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `alb_arn` | ALB ARN |
| `alb_dns_name` | ALB DNS name (pass to CloudFront module) |
| `alb_zone_id` | ALB canonical hosted zone ID (for Route 53 alias) |
| `https_listener_arn` | HTTPS listener ARN |

---

## Listener Rule Priority

| Priority | Path Pattern | Target |
|----------|-------------|--------|
| 10 | `/api/service-a/*` | `service_a_target_group_arn` |
| 20 | `/api/service-b/*` | `service_b_target_group_arn` |
| 30 | `/api/service-c/*` | `service_c_target_group_arn` |
| Default | `*` | `frontend_target_group_arn` |

---

## Notes

- Service routing rules are only created when the corresponding `*_target_group_arn` is non-empty.
- SSL policy `ELBSecurityPolicy-TLS13-1-2-2021-06` enforces TLS 1.3/1.2 with strong ciphers.
- Pass `alb_dns_name` to the `cloudfront` module as the API origin.
- Access logs are only enabled when `access_log_bucket_id` is set and the S3 bucket has the correct ELB delivery policy.
