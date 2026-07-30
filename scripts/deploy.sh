#!/usr/bin/env bash
###############################################################################
# scripts/deploy.sh
# Usage: ./scripts/deploy.sh <environment> <action> [image_tag]
#
#   environment : dev | staging | uat | prod
#   action      : plan | apply | destroy
#   image_tag   : optional Docker image tag (default: latest)
#
# Example:
#   ./scripts/deploy.sh dev apply v1.2.3
###############################################################################
set -euo pipefail

# ─── Colour helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ─── Argument validation ────────────────────────────────────────────────────
VALID_ENVS=("dev" "staging" "uat" "prod")
VALID_ACTIONS=("plan" "apply" "destroy")

ENV="${1:-}"
ACTION="${2:-}"
IMAGE_TAG="${3:-latest}"

[[ -z "$ENV" ]]    && error "Environment required. Usage: $0 <env> <action> [image_tag]"
[[ -z "$ACTION" ]] && error "Action required. Usage: $0 <env> <action> [image_tag]"

# Validate env
valid_env=false
for e in "${VALID_ENVS[@]}"; do [[ "$e" == "$ENV" ]] && valid_env=true; done
$valid_env || error "Invalid environment '${ENV}'. Must be one of: ${VALID_ENVS[*]}"

# Validate action
valid_action=false
for a in "${VALID_ACTIONS[@]}"; do [[ "$a" == "$ACTION" ]] && valid_action=true; done
$valid_action || error "Invalid action '${ACTION}'. Must be one of: ${VALID_ACTIONS[*]}"

# ─── Guard: require approval for prod destroy ────────────────────────────────
if [[ "$ENV" == "prod" && "$ACTION" == "destroy" ]]; then
  warn "You are about to DESTROY PRODUCTION infrastructure!"
  read -r -p "Type 'yes-destroy-prod' to confirm: " confirmation
  [[ "$confirmation" != "yes-destroy-prod" ]] && error "Aborted."
fi

# ─── Paths ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_DIR="${REPO_ROOT}/terraform/envs/${ENV}"

[[ -d "$ENV_DIR" ]] || error "Environment directory not found: ${ENV_DIR}"

# ─── Prerequisites check ─────────────────────────────────────────────────────
for cmd in terraform aws jq; do
  command -v "$cmd" &>/dev/null || error "Required command not found: ${cmd}"
done

info "Terraform version: $(terraform version -json | jq -r '.terraform_version')"
info "AWS Identity: $(aws sts get-caller-identity --query 'Arn' --output text)"

# ─── Run Terraform ────────────────────────────────────────────────────────────
cd "$ENV_DIR"

info "Initializing Terraform for environment: ${ENV}"
terraform init -upgrade -reconfigure

if [[ "$ACTION" == "plan" ]]; then
  info "Running terraform plan..."
  terraform plan \
    -var="frontend_image_tag=${IMAGE_TAG}" \
    -var="service_a_image_tag=${IMAGE_TAG}" \
    -var="service_b_image_tag=${IMAGE_TAG}" \
    -var="service_c_image_tag=${IMAGE_TAG}" \
    -out="${ENV}.tfplan"
  success "Plan saved to ${ENV}.tfplan"

elif [[ "$ACTION" == "apply" ]]; then
  if [[ -f "${ENV}.tfplan" ]]; then
    info "Applying saved plan ${ENV}.tfplan..."
    terraform apply "${ENV}.tfplan"
  else
    info "Running terraform apply (auto-approve for non-prod)..."
    AUTO_APPROVE=""
    [[ "$ENV" != "prod" ]] && AUTO_APPROVE="-auto-approve"
    terraform apply $AUTO_APPROVE \
      -var="frontend_image_tag=${IMAGE_TAG}" \
      -var="service_a_image_tag=${IMAGE_TAG}" \
      -var="service_b_image_tag=${IMAGE_TAG}" \
      -var="service_c_image_tag=${IMAGE_TAG}"
  fi
  success "Apply complete for environment: ${ENV}"

elif [[ "$ACTION" == "destroy" ]]; then
  warn "Destroying environment: ${ENV}"
  terraform destroy \
    -var="frontend_image_tag=${IMAGE_TAG}" \
    -var="service_a_image_tag=${IMAGE_TAG}" \
    -var="service_b_image_tag=${IMAGE_TAG}" \
    -var="service_c_image_tag=${IMAGE_TAG}"
  success "Destroy complete for environment: ${ENV}"
fi
