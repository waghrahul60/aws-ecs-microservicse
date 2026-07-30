###############################################################################
# S3 BUCKET MODULE - main.tf
# Creates: S3 bucket for React SPA static assets with:
#   - Versioning, encryption (SSE-S3 / KMS), lifecycle policies
#   - Public access block, bucket policy for CloudFront OAC
#   - Optional access logging bucket
###############################################################################

# ─────────────────────────────────────────────
# S3 Bucket – React Frontend Static Assets
# ─────────────────────────────────────────────
resource "aws_s3_bucket" "frontend" {
  bucket = local.frontend_bucket_name

  tags = merge(var.tags, {
    Name    = "${local.name_prefix}-frontend"
    Purpose = "React SPA static assets"
  })
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ─────────────────────────────────────────────
# Bucket Policy – CloudFront OAC access only
# ─────────────────────────────────────────────
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

# ─────────────────────────────────────────────
# S3 Bucket – Access Logs (for CloudFront & ALB)
# ─────────────────────────────────────────────
resource "aws_s3_bucket" "access_logs" {
  count  = var.create_access_log_bucket ? 1 : 0
  bucket = local.access_log_bucket_name

  tags = merge(var.tags, {
    Name    = "${local.name_prefix}-access-logs"
    Purpose = "Access logs for CloudFront and ALB"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count  = var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count  = var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  count  = var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }
  }
}
