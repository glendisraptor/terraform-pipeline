#!/bin/bash

# Validation script for Terraform code
set -e

echo "🔍 Running Terraform validation..."

# Check formatting
echo "📏 Checking Terraform format..."
terraform fmt -check -recursive terraform/

# Validate each environment
for env in dev staging prod; do
    echo "✅ Validating $env environment..."
    cd terraform/envs/$env
    terraform init -backend=false
    terraform validate
    cd ../../..
done

echo "✅ All validation checks passed!"