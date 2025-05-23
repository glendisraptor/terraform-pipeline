# Complete Terraform Code Examples - Minimal S3 Setup

## 📁 File Structure
```
terraform/
├── envs/
│   ├── dev/
│   │   └── main.tf
│   ├── staging/
│   │   └── main.tf
│   └── prod/
│       └── main.tf
└── modules/
    └── s3/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔧 S3 Module Files

### `terraform/modules/s3/main.tf`
```hcl
# S3 Bucket with environment-based naming
resource "aws_s3_bucket" "main" {
  bucket = "${var.environment}-${var.bucket_name}"

  tags = {
    Name        = "${var.environment}-${var.bucket_name}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access (security best practice)
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### `terraform/modules/s3/variables.tf`
```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "bucket_name" {
  description = "Base name for the S3 bucket (will be prefixed with environment)"
  type        = string

  validation {
    condition     = length(var.bucket_name) > 0 && length(var.bucket_name) <= 50
    error_message = "Bucket name must be between 1 and 50 characters."
  }
}
```

### `terraform/modules/s3/outputs.tf`
```hcl
output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}
```

## 🌍 Environment Configuration Files

### `terraform/envs/dev/main.tf`
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "your-terraform-state-bucket"  # Replace with your state bucket
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    
    # Enable state locking
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = local.environment
      ManagedBy   = "Terraform"
      Team        = "platform-team"
    }
  }
}

locals {
  environment = "dev"  # Only line that changes per environment
}

# Application data bucket
module "app_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-data"
}

# Logs bucket
module "logs_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-logs"
}

# Static assets bucket
module "assets_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-assets"
}
```

### `terraform/envs/staging/main.tf`
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "your-terraform-state-bucket"  # Replace with your state bucket
    key    = "staging/terraform.tfstate"    # Only this line changes
    region = "us-east-1"
    
    # Enable state locking
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = local.environment
      ManagedBy   = "Terraform"
      Team        = "platform-team"
    }
  }
}

locals {
  environment = "staging"  # Only this line changes
}

# Application data bucket
module "app_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-data"
}

# Logs bucket
module "logs_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-logs"
}

# Static assets bucket
module "assets_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-assets"
}
```

### `terraform/envs/prod/main.tf`
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "your-terraform-state-bucket"  # Replace with your state bucket
    key    = "prod/terraform.tfstate"       # Only this line changes
    region = "us-east-1"
    
    # Enable state locking
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = local.environment
      ManagedBy   = "Terraform"
      Team        = "platform-team"
    }
  }
}

locals {
  environment = "prod"  # Only this line changes
}

# Application data bucket
module "app_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-data"
}

# Logs bucket
module "logs_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-logs"
}

# Static assets bucket
module "assets_bucket" {
  source = "../../modules/s3"
  
  environment = local.environment
  bucket_name = "myapp-assets"
}
```

## 🚀 GitHub Actions Workflow

### `.github/workflows/terraform-pipeline.yml`
```yaml
name: Terraform Multi-Environment Pipeline

on:
  # Automatic deployment triggers
  push:
    branches: [dev, staging]
    paths: ['terraform/**']
  
  # Manual deployment
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'dev'
        type: choice
        options: [dev, staging, prod]
      action:
        description: 'Terraform action'
        required: true
        default: 'plan'
        type: choice
        options: [plan, apply, destroy]

  # PR validation
  pull_request:
    branches: [dev, staging, main]
    paths: ['terraform/**']

env:
  TF_IN_AUTOMATION: true
  AWS_REGION: us-east-1

jobs:
  setup:
    name: Setup & Environment Detection
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.env.outputs.environment }}
      tf_path: ${{ steps.env.outputs.tf_path }}
      should_deploy: ${{ steps.env.outputs.should_deploy }}
    steps:
      - name: Determine Environment
        id: env
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            ENV="${{ github.event.inputs.environment }}"
            echo "should_deploy=true" >> $GITHUB_OUTPUT
          elif [[ "${{ github.event_name }}" == "pull_request" ]]; then
            if [[ "${{ github.base_ref }}" == "main" ]]; then
              ENV="prod"
            elif [[ "${{ github.base_ref }}" == "staging" ]]; then
              ENV="staging"
            else
              ENV="dev"
            fi
            echo "should_deploy=false" >> $GITHUB_OUTPUT
          else
            # Push event
            if [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
              ENV="staging"
              echo "should_deploy=true" >> $GITHUB_OUTPUT
            elif [[ "${{ github.ref }}" == "refs/heads/dev" ]]; then
              ENV="dev"
              echo "should_deploy=true" >> $GITHUB_OUTPUT
            fi
          fi
          
          echo "environment=$ENV" >> $GITHUB_OUTPUT
          echo "tf_path=terraform/envs/$ENV" >> $GITHUB_OUTPUT
          echo "🎯 Target environment: $ENV"

  validate:
    name: Validate & Security Scan
    runs-on: ubuntu-latest
    needs: setup
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.6

      - name: Terraform Format Check
        run: |
          terraform fmt -check -recursive terraform/
          echo "✅ Terraform format check passed"

      - name: Terraform Init & Validate
        run: |
          terraform init -backend=false
          terraform validate
          echo "✅ Terraform validation passed"
        working-directory: ${{ needs.setup.outputs.tf_path }}

  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    needs: [setup, validate]
    environment: ${{ needs.setup.outputs.environment }}-plan
    outputs:
      plan_exitcode: ${{ steps.plan.outputs.exitcode }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.6

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: ${{ needs.setup.outputs.tf_path }}

      - name: Terraform Plan
        id: plan
        run: |
          if [[ "${{ github.event.inputs.action }}" == "destroy" ]]; then
            terraform plan -destroy -detailed-exitcode -no-color -out=tfplan
          else
            terraform plan -detailed-exitcode -no-color -out=tfplan
          fi
        working-directory: ${{ needs.setup.outputs.tf_path }}
        continue-on-error: true

      - name: Check Plan Results
        run: |
          case "${{ steps.plan.outputs.exitcode }}" in
            0) echo "✅ No changes needed" ;;
            1) echo "❌ Plan failed" && exit 1 ;;
            2) echo "📋 Changes detected" ;;
          esac

      - name: Upload Plan
        if: steps.plan.outputs.exitcode == 2
        uses: actions/upload-artifact@v3
        with:
          name: tfplan-${{ needs.setup.outputs.environment }}-${{ github.sha }}
          path: ${{ needs.setup.outputs.tf_path }}/tfplan

      - name: Comment PR
        if: github.event_name == 'pull_request' && steps.plan.outputs.exitcode == 2
        uses: actions/github-script@v7
        with:
          script: |
            const output = `## 📋 Terraform Plan - \`${{ needs.setup.outputs.environment }}\`
            
            **Status:** Changes detected
            **Branch:** \`${{ github.head_ref }}\`
            
            <details><summary>View Plan Details</summary>
            
            Plan completed successfully. Review the full output in the [Actions tab](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}).
            
            </details>`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });

  deploy:
    name: Deploy Infrastructure
    runs-on: ubuntu-latest
    needs: [setup, validate, plan]
    if: |
      needs.setup.outputs.should_deploy == 'true' && 
      (needs.plan.outputs.plan_exitcode == '2' || github.event.inputs.action == 'destroy')
    environment: ${{ needs.setup.outputs.environment }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.6

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init
        working-directory: ${{ needs.setup.outputs.tf_path }}

      - name: Download Plan
        if: github.event.inputs.action != 'destroy'
        uses: actions/download-artifact@v3
        with:
          name: tfplan-${{ needs.setup.outputs.environment }}-${{ github.sha }}
          path: ${{ needs.setup.outputs.tf_path }}

      - name: Terraform Apply
        if: github.event.inputs.action != 'destroy'
        run: |
          terraform apply -no-color tfplan
          echo "✅ Terraform apply completed"
        working-directory: ${{ needs.setup.outputs.tf_path }}

      - name: Terraform Destroy
        if: github.event.inputs.action == 'destroy'
        run: |
          terraform destroy -auto-approve -no-color
          echo "✅ Terraform destroy completed"
        working-directory: ${{ needs.setup.outputs.tf_path }}

      - name: Show Outputs
        if: github.event.inputs.action != 'destroy'
        run: |
          echo "📤 Terraform Outputs:"
          terraform output
        working-directory: ${{ needs.setup.outputs.tf_path }}
        continue-on-error: true
```

## 🛠️ Setup Scripts

### `scripts/setup-backend.sh`
```bash
#!/bin/bash

# Setup script for Terraform backend resources
set -e

BUCKET_NAME="your-terraform-state-bucket"
TABLE_NAME="terraform-state-locks"
REGION="us-east-1"

echo "🚀 Setting up Terraform backend resources..."

# Create S3 bucket for state storage
echo "📦 Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable versioning
echo "🔄 Enabling S3 bucket versioning..."
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Enable encryption
echo "🔐 Enabling S3 bucket encryption..."
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Block public access
echo "🛡️  Blocking public access..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

echo "✅ Backend setup complete!"
echo "📝 Update your terraform backend configuration with:"
echo "   bucket = \"$BUCKET_NAME\""
echo "   dynamodb_table = \"$TABLE_NAME\""
echo "   region = \"$REGION\""
```

### `scripts/validate-terraform.sh`
```bash
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
```

## 📋 Quick Start Guide

### 1. Create the file structure:
```bash
mkdir -p terraform/{envs/{dev,staging,prod},modules/s3}
mkdir -p .github/workflows
mkdir -p scripts
```

### 2. Copy all the code files above into their respective locations

### 3. Update the state bucket name:
```bash
# Replace "your-terraform-state-bucket" with your actual bucket name in:
# - All terraform/envs/*/main.tf files
# - scripts/setup-backend.sh
```

### 4. Run the setup script:
```bash
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh
```

### 5. Set up GitHub secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 6. Test the setup:
```bash
cd terraform/envs/dev
terraform init
terraform plan
```

## 🎯 What You'll Get

After deployment, you'll have these S3 buckets created:

**Development:**
- `dev-myapp-data`
- `dev-myapp-logs`
- `dev-myapp-assets`

**Staging:**
- `staging-myapp-data`
- `staging-myapp-logs`
- `staging-myapp-assets`

**Production:**
- `prod-myapp-data`
- `prod-myapp-logs`
- `prod-myapp-assets`

All buckets will have:
- ✅ Versioning enabled
- ✅ AES-256 encryption
- ✅ Public access blocked
- ✅ Environment-based naming
- ✅ Proper tagging

<!-- DONE -->