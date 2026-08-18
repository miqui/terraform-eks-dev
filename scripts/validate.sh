#!/usr/bin/env bash
# validate.sh — Terraform validation workflow for the dev EKS stack.
# Run this on a host with Terraform CLI installed (NOT the Hermes orchestration host).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_DIR="$PROJECT_ROOT/envs/dev"

echo "=== Terraform fmt -recursive (auto-fix) ==="
terraform fmt -recursive "$PROJECT_ROOT"

echo "=== Terraform fmt -check ==="
terraform fmt -check -recursive "$PROJECT_ROOT"

echo "=== Terraform init -backend=false ==="
cd "$ENV_DIR"
terraform init -backend=false

echo "=== Terraform validate ==="
terraform validate

echo ""
echo "✅ Validation passed."
echo ""
echo "To run a plan against the dev environment:"
echo "  cd $ENV_DIR"
echo "  terraform init -backend-config=bucket=YOUR_STATE_BUCKET"
echo "  terraform plan -var-file=terraform.tfvars"
