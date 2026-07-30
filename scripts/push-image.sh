#!/usr/bin/env bash
###############################################################################
# scripts/push-image.sh
# Build and push a Docker image to ECR for a given service
#
# Usage: ./scripts/push-image.sh <environment> <service-name> <image-tag> [dockerfile-path]
#
# Example:
#   ./scripts/push-image.sh dev service-a v1.2.3 ../backend/service-a
###############################################################################
set -euo pipefail

ENV="${1:-}"
SERVICE="${2:-}"
TAG="${3:-latest}"
DOCKERFILE_PATH="${4:-.}"

[[ -z "$ENV" || -z "$SERVICE" ]] && {
  echo "Usage: $0 <environment> <service-name> <image-tag> [dockerfile-path]"
  exit 1
}

REGION=$(aws configure get region || echo "us-east-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_NAME="myapp/${ENV}/${SERVICE}"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

echo "📦 Building and pushing: ${SERVICE}:${TAG}"
echo "   ECR: ${ECR_URL}"

# Authenticate to ECR
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Build
docker build -t "${SERVICE}:${TAG}" "${DOCKERFILE_PATH}"

# Tag
docker tag "${SERVICE}:${TAG}" "${ECR_URL}:${TAG}"
docker tag "${SERVICE}:${TAG}" "${ECR_URL}:latest"

# Push
docker push "${ECR_URL}:${TAG}"
docker push "${ECR_URL}:latest"

echo "✅ Pushed ${ECR_URL}:${TAG}"
