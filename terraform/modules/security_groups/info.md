# Module: `security_groups`

> Creates all Security Groups for the stack: ALB, ECS tasks, RDS, and VPC Interface Endpoints. Rules are pre-wired so traffic flows correctly through each tier. Enforces security compliance by restricting `0.0.0.0/0` on ingress rules.

---

## Usage

```hcl
module "security_groups" {
  source = "../../modules/security_groups"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id

  private_app_subnet_cidrs = var.private_app_subnet_cidrs

  # Specify allowed ingress CIDR blocks for the ALB (0.0.0.0/0 is prohibited)
  alb_ingress_cidr_blocks = ["10.0.0.0/8"]

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `vpc_id` | `string` | ✅ | — | VPC ID where security groups are created |
| `private_app_subnet_cidrs` | `list(string)` | ✅ | — | CIDR blocks of private app subnets (for VPC endpoint ingress) |
| `alb_ingress_cidr_blocks` | `list(string)` | | `["10.0.0.0/8"]` | Allowed ingress CIDR blocks for ALB. **Note:** `0.0.0.0/0` and `::/0` are prohibited by validation rules. |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Security Restrictions & Validation

- **`0.0.0.0/0` Restriction**: The `alb_ingress_cidr_blocks` variable contains a Terraform validation rule:
  ```hcl
  validation {
    condition = alltrue([
      for cidr in var.alb_ingress_cidr_blocks : !contains(["0.0.0.0/0", "::/0"], cidr)
    ])
    error_message = "Security Policy Violation: Ingress from '0.0.0.0/0' or '::/0' is prohibited. Specify explicit CIDR blocks."
  }
  ```
  Attempting to pass `0.0.0.0/0` or `::/0` will fail Terraform validation at `plan` / `apply` time.

---

## Outputs

| Name | Description |
|------|-------------|
| `alb_sg_id` | Security Group ID for the ALB |
| `ecs_tasks_sg_id` | Security Group ID for ECS tasks |
| `rds_sg_id` | Security Group ID for RDS |
| `vpc_endpoints_sg_id` | Security Group ID for VPC Interface Endpoints |

---

## Traffic Rules (Summary)

| Security Group | Allows In | Allows Out |
|----------------|-----------|------------|
| **alb** | 80 (HTTP), 443 (HTTPS) from `var.alb_ingress_cidr_blocks` | All → ECS tasks |
| **ecs_tasks** | All from ALB SG, all internal (Service Connect) | All → internet (via NAT) |
| **rds** | Port 5432 from ECS tasks SG only | None |
| **vpc_endpoints** | 443 from private app subnet CIDRs | None |

---

## Notes

- This module should be called **after** `vpc` and **before** `alb`, `ecs`, `ecs_service`, and `rds`.
- The four output IDs are the primary inputs needed by downstream modules.
- All inter-SG rules reference Security Group IDs (not CIDRs) to avoid hardcoding ranges.
