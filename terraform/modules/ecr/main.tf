###############################################################################
# ECR MODULE - main.tf
# Creates: ECR Repositories per microservice with scan-on-push, KMS encryption,
#          and lifecycle policy rules to clean up old image tags
###############################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ─────────────────────────────────────────────
# ECR Repositories (one per service)
# ─────────────────────────────────────────────
resource "aws_ecr_repository" "services" {
  for_each             = toset(var.service_names)
  name                 = "${var.project}/${var.environment}/${each.key}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  dynamic "encryption_configuration" {
    for_each = var.ecr_kms_key_arn != "" ? [1] : []
    content {
      encryption_type = "KMS"
      kms_key         = var.ecr_kms_key_arn
    }
  }

  tags = merge(var.tags, {
    Service = each.key
  })
}

# ─────────────────────────────────────────────
# ECR Lifecycle Policy (per service)
# ─────────────────────────────────────────────
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = toset(var.service_names)
  repository = aws_ecr_repository.services[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_tagged_image_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_tagged_image_count
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images older than ${var.untagged_image_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = { type = "expire" }
      }
    ]
  })
}
