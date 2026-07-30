# Module: `observability`

> Provisions a single-pane CloudWatch Dashboard (ECS, ALB, RDS, CloudFront), SNS Alarm Notification Topic, and CloudWatch Alarms for infrastructure health.

---

## Usage

```hcl
module "observability" {
  source = "../../modules/observability"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  ecs_cluster_name           = module.ecs.cluster_name
  alb_arn_suffix             = module.alb.alb_arn # or suffix
  db_instance_id             = module.rds.db_instance_id
  cloudfront_distribution_id = module.cloudfront.distribution_id

  alarm_email = "devops-alerts@example.com"

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `aws_region` | `string` | ✅ | — | Primary AWS region |
| `ecs_cluster_name` | `string` | | `""` | ECS Cluster name |
| `alb_arn_suffix` | `string` | | `""` | ALB ARN suffix for ELB metrics |
| `db_instance_id` | `string` | | `""` | RDS DB Instance Identifier |
| `cloudfront_distribution_id` | `string` | | `""` | CloudFront Distribution ID |
| `alarm_email` | `string` | | `""` | Email for SNS alarm notifications |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `sns_topic_arn` | SNS Topic ARN for alarms |
| `dashboard_name` | CloudWatch Dashboard name |
| `dashboard_arn` | CloudWatch Dashboard ARN |
