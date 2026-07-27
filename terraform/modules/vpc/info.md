# Module: `vpc`

> Creates the core network foundation: VPC, public subnets, private app subnets (ECS), private data subnets (RDS), Internet Gateway, NAT Gateways, route tables, and optional VPC Flow Logs.

---

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  vpc_cidr                  = "10.20.0.0/16"
  availability_zones        = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs       = ["10.20.1.0/24", "10.20.2.0/24"]
  private_app_subnet_cidrs  = ["10.20.10.0/24", "10.20.11.0/24"]
  private_data_subnet_cidrs = ["10.20.20.0/24", "10.20.21.0/24"]

  # Cost-saving for non-prod: use a single NAT Gateway instead of one per AZ
  single_nat_gateway = true

  # Optional: VPC Flow Logs
  enable_flow_logs         = true
  flow_log_role_arn        = aws_iam_role.flow_logs.arn
  flow_log_destination_arn = aws_cloudwatch_log_group.flow_logs.arn

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name used for naming/tagging |
| `environment` | `string` | ✅ | — | Environment (dev \| staging \| uat \| prod) |
| `vpc_cidr` | `string` | | `"10.0.0.0/16"` | CIDR block for the VPC |
| `availability_zones` | `list(string)` | ✅ | — | AZs to deploy across |
| `public_subnet_cidrs` | `list(string)` | ✅ | — | CIDRs for public subnets (one per AZ) |
| `private_app_subnet_cidrs` | `list(string)` | ✅ | — | CIDRs for private app subnets (ECS) |
| `private_data_subnet_cidrs` | `list(string)` | ✅ | — | CIDRs for private data subnets (RDS) |
| `single_nat_gateway` | `bool` | | `false` | Use a single NAT GW (cost-saving for non-prod) |
| `enable_flow_logs` | `bool` | | `true` | Enable VPC Flow Logs to CloudWatch |
| `flow_log_role_arn` | `string` | | `""` | IAM role ARN for Flow Logs |
| `flow_log_destination_arn` | `string` | | `""` | CloudWatch Log Group ARN for Flow Logs |
| `tags` | `map(string)` | | `{}` | Common tags applied to all resources |

---

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the created VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `public_subnet_ids` | IDs of public subnets |
| `private_app_subnet_ids` | IDs of private application subnets (ECS) |
| `private_data_subnet_ids` | IDs of private data subnets (RDS) |
| `nat_gateway_ids` | IDs of NAT Gateways |
| `nat_gateway_public_ips` | Public IPs of NAT Gateways |
| `internet_gateway_id` | ID of the Internet Gateway |
| `public_route_table_id` | ID of the public route table |

---

## Notes

- **Subnet layout**: Public subnets host the ALB; private-app subnets host ECS Fargate tasks; private-data subnets host RDS (no outbound internet).
- **NAT Gateways**: Defaults to one per AZ for high availability. Set `single_nat_gateway = true` to save costs in dev/staging.
- **Flow Logs**: Enabled by default. Provide `flow_log_role_arn` and `flow_log_destination_arn` when `enable_flow_logs = true`.
- **Downstream dependency**: Almost every other module depends on outputs from this module.
