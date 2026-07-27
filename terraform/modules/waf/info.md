# Module: `waf`

> Creates a WAFv2 Web ACL (CLOUDFRONT scope) with AWS Managed Rules (Core Rule Set, Known Bad Inputs, IP Reputation List) and an IP-based rate limiting rule. Must be deployed in `us-east-1` for CloudFront.

---

## Usage

> ⚠️ **Important:** WAF for CloudFront **must** be provisioned in `us-east-1`. Use an aliased AWS provider.

```hcl
module "waf" {
  source = "../../modules/waf"

  providers = {
    aws = aws.us_east_1
  }

  project     = var.project
  environment = var.environment

  rate_limit_per_ip = 2000  # requests per 5-minute window per IP

  # Optional: stream WAF logs to Kinesis Firehose or CloudWatch Logs
  waf_log_destination_arn = "arn:aws:firehose:us-east-1:ACCOUNT_ID:deliverystream/waf-logs"

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `rate_limit_per_ip` | `number` | | `2000` | Max requests per 5-minute window per IP |
| `waf_log_destination_arn` | `string` | | `""` | Log destination ARN (Firehose or CloudWatch Logs) |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_arn` | ARN of the WAF Web ACL (pass to CloudFront module) |
| `web_acl_id` | ID of the WAF Web ACL |
| `web_acl_capacity` | Capacity consumed by the WAF rules |

---

## Managed Rules Included

| Rule Group | Purpose |
|------------|---------|
| `AWSManagedRulesCommonRuleSet` | OWASP Top 10 protections |
| `AWSManagedRulesKnownBadInputsRuleSet` | Known malicious payloads |
| `AWSManagedRulesAmazonIpReputationList` | AWS IP threat intelligence |

---

## Notes

- The `web_acl_arn` output is passed directly to the `cloudfront` module's `waf_web_acl_arn` variable.
- Set `waf_log_destination_arn` to enable logging. Leave empty to disable.
- Rate limit default of `2000` req/5 min is a sensible starting point; tune for your traffic patterns.
- Requires an `aws.us_east_1` provider alias in the calling environment.
