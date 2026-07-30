#!/usr/bin/env bash
###############################################################################
# scripts/bootstrap-state.sh
# One-time setup: create the S3 bucket and DynamoDB table for Terraform state
# Run this ONCE before the first terraform init
#
# Usage: ./scripts/bootstrap-state.sh <aws-region> <state-bucket-name>
###############################################################################
set -euo pipefail

REGION="${1:-us-east-1}"
BUCKET="${2:-myapp-terraform-state}"
TABLE="terraform-state-lock"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Bootstrapping Terraform state backend..."
echo "  Region  : ${REGION}"
echo "  Bucket  : ${BUCKET}"
echo "  Table   : ${TABLE}"
echo "  Account : ${ACCOUNT_ID}"
echo ""

# Create S3 bucket
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "✓ S3 bucket already exists: ${BUCKET}"
else
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  echo "✓ Created S3 bucket: ${BUCKET}"
fi

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled
echo "✓ Enabled versioning on ${BUCKET}"

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
echo "✓ Enabled SSE-S3 encryption on ${BUCKET}"

# Block public access
aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "✓ Blocked public access on ${BUCKET}"

# Create DynamoDB table for state locking
if aws dynamodb describe-table --table-name "${TABLE}" --region "${REGION}" 2>/dev/null; then
  echo "✓ DynamoDB table already exists: ${TABLE}"
else
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
  echo "✓ Created DynamoDB table: ${TABLE}"
fi

echo ""
echo "✅ Bootstrap complete!"
echo "   Update your backend config in each env/*/main.tf:"
echo "   bucket = \"${BUCKET}\""
echo "   region = \"${REGION}\""
echo "   dynamodb_table = \"${TABLE}\""
