# Terraform Multi-Environment Setup with GitHub Actions

## 📋 Table of Contents
1. [Overview](#overview)
2. [Folder Structure](#folder-structure)
3. [Terraform Code Examples](#terraform-code-examples)
4. [GitHub Actions Setup](#github-actions-setup)
5. [Repository Configuration](#repository-configuration)
6. [Best Practices](#best-practices)
7. [Deployment Workflow](#deployment-workflow)
8. [Troubleshooting](#troubleshooting)

## Overview

This guide provides a complete setup for managing Terraform infrastructure across multiple environments (dev, staging, prod) using GitHub Actions with manual deployment controls and comprehensive validation.

### Key Features
- ✅ Multi-environment support (dev/staging/prod)
- ✅ Manual deployment with branch/environment selection
- ✅ Automated validation and security scanning
- ✅ Plan review and approval workflows
- ✅ State isolation per environment
- ✅ Resource naming with environment prefixes

## Folder Structure

```
your-repo/
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml
├── terraform/
│   ├── envs/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── backend.tf
│   │   │   ├── variables.tf
│   │   │   └── terraform.tfvars
│   │   ├── staging/
│   │   │   ├── main.tf
│   │   │   ├── backend.tf
│   │   │   ├── variables.tf
│   │   │   └── terraform.tfvars
│   │   └── prod/
│   │       ├── main.tf
│   │       ├── backend.tf
│   │       ├── variables.tf
│   │       └── terraform.tfvars
│   └── modules/
│       └── s3/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── docs/
│   └── terraform-setup.md
└── README.md
```

## Terraform Code Examples

### Module: S3 Bucket (`terraform/modules/s3/`)

#### `main.tf`
```hcl
# S3 Bucket with environment-based naming
resource "aws_s3_bucket" "main" {
  bucket = "${var.environment}-${var.bucket_name}"

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-${var.bucket_name}"
    Environment = var.environment
  })
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "main_lifecycle"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_noncurrent_expiration_days
    }
  }
}
```

#### `variables.tf`
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
}

variable "versioning_enabled" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "lifecycle_enabled" {
  description = "Enable lifecycle management"
  type        = bool
  default     = false
}

variable "lifecycle_expiration_days" {
  description = "Number of days after which objects expire"
  type        = number
  default     = 90
}

variable "lifecycle_noncurrent_expiration_days" {
  description = "Number of days after which noncurrent versions expire"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

#### `outputs.tf`
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

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}
```

### Environment Configurations

#### Development (`terraform/envs/dev/`)

**`backend.tf`**
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    
    # Enable state locking
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

**`main.tf`**
```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      Owner         = var.team_name
    }
  }
}

# Main application S3 bucket
module "app_bucket" {
  source = "../../modules/s3"
  
  environment         = var.environment
  bucket_name         = "${var.project_name}-app-data"
  versioning_enabled  = true
  lifecycle_enabled   = true
  lifecycle_expiration_days = var.lifecycle_expiration_days
  
  common_tags = var.common_tags
}

# Logs S3 bucket
module "logs_bucket" {
  source = "../../modules/s3"
  
  environment         = var.environment
  bucket_name         = "${var.project_name}-logs"
  versioning_enabled  = false
  lifecycle_enabled   = true
  lifecycle_expiration_days = 30
  
  common_tags = var.common_tags
}

# Backup S3 bucket
module "backup_bucket" {
  source = "../../modules/s3"
  
  environment         = var.environment
  bucket_name         = "${var.project_name}-backups"
  versioning_enabled  = true
  lifecycle_enabled   = false
  
  common_tags = var.common_tags
}
```

**`variables.tf`**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "team_name" {
  description = "Name of the team"
  type        = string
}

variable "lifecycle_expiration_days" {
  description = "Number of days for object expiration"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

**`terraform.tfvars`**
```hcl
# Development Environment Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "myapp"
team_name    = "platform-team"

lifecycle_expiration_days = 30

common_tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
  Purpose    = "development"
}
```

#### Staging (`terraform/envs/staging/`)

**`backend.tf`**
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
    
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

**`terraform.tfvars`**
```hcl
# Staging Environment Configuration
aws_region   = "us-east-1"
environment  = "staging"
project_name = "myapp"
team_name    = "platform-team"

lifecycle_expiration_days = 60

common_tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
  Purpose    = "staging"
}
```

#### Production (`terraform/envs/prod/`)

**`backend.tf`**
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

**`terraform.tfvars`**
```hcl
# Production Environment Configuration
aws_region   = "us-east-1"
environment  = "prod"
project_name = "myapp"
team_name    = "platform-team"

lifecycle_expiration_days = 365

common_tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
  Purpose    = "production"
}
```

## GitHub Actions Setup

### Prerequisites

1. **Create Terraform State Backend Resources**
   ```bash
   # Create S3 bucket for Terraform state
   aws s3 mb s3://your-terraform-state-bucket
   
   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name terraform-state-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
   ```

2. **Set up GitHub Secrets**
   Navigate to your repository → Settings → Secrets and variables → Actions:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

## Repository Configuration

### 1. GitHub Environments Setup

Go to repository Settings → Environments and create:

**Development Environment (`dev`)**
- No protection rules needed
- Add environment-specific secrets if needed

**Development Plan Environment (`dev-plan`)**
- No protection rules needed

**Staging Environment (`staging`)**
- Protection rules:
  - Required reviewers: 1-2 team members
  - Deployment branches: `staging` branch only

**Staging Plan Environment (`staging-plan`)**
- No protection rules needed

**Production Environment (`prod`)**
- Protection rules:
  - Required reviewers: 2+ senior team members
  - Wait timer: 5 minutes
  - Deployment branches: `main` branch only

**Production Destroy Environment (`prod-destroy`)**
- Protection rules:
  - Required reviewers: All senior team members
  - Manual approval only

### 2. Branch Protection Rules

Configure branch protection in Settings → Branches:

**Main Branch (`main`)**
- Require pull request reviews before merging
- Require status checks to pass before merging
- Include administrators
- Restrict pushes to specific teams

**Staging Branch (`staging`)**
- Require pull request reviews before merging
- Require status checks to pass before merging

## Best Practices

### 1. **Resource Naming Convention**
```
{environment}-{project}-{resource-type}-{identifier}
Examples:
- dev-myapp-s3-app-data
- staging-myapp-s3-logs
- prod-myapp-s3-backups
```

### 2. **Tagging Strategy**
```hcl
default_tags = {
  Environment   = var.environment
  Project       = var.project_name
  ManagedBy     = "Terraform"
  Owner         = var.team_name
  CostCenter    = var.cost_center
}
```

### 3. **State Management**
- Separate state files per environment
- Use S3 backend with versioning enabled
- Enable state locking with DynamoDB
- Regular state file backups

### 4. **Security Practices**
- Use least-privilege IAM policies
- Enable AWS CloudTrail
- Encrypt state files
- Scan infrastructure code with tfsec
- Regular security audits

### 5. **Code Organization**
- Keep modules reusable and environment-agnostic
- Use variables for environment-specific values
- Maintain consistent file structure
- Document all variables and outputs

## Deployment Workflow

### 1. **Development Deployment**
```bash
# Navigate to Actions → Terraform Deploy → Run workflow
Environment: dev
Action: plan/apply
```

### 2. **Staging Deployment**
```bash
# 1. Create PR to staging branch
# 2. Review automated plan in PR comments
# 3. Merge PR
# 4. Manual deployment via GitHub Actions
Environment: staging
Action: apply
```

### 3. **Production Deployment**
```bash
# 1. Create PR to main branch
# 2. Review automated plan in PR comments
# 3. Get required approvals
# 4. Merge PR
# 5. Manual deployment via GitHub Actions with approval
Environment: prod
Action: apply
```

### 4. **Emergency Procedures**
```bash
# For urgent fixes or rollbacks
# Use manual workflow dispatch with appropriate approvals
# Document all emergency deployments
```

## Example Usage

### Initial Setup
1. **Clone and setup repository structure**
   ```bash
   git clone your-repo
   cd your-repo
   mkdir -p terraform/{envs/{dev,staging,prod},modules/s3}
   mkdir -p .github/workflows
   ```

2. **Add Terraform files** (use examples above)

3. **Initialize Terraform for each environment**
   ```bash
   # Dev environment
   cd terraform/envs/dev
   terraform init
   terraform plan
   
   # Repeat for staging and prod
   ```

4. **Test GitHub Actions**
   - Push code to repository
   - Create test PR to see automated plans
   - Test manual deployment workflow

### Resource Examples After Deployment

With the configuration above, you'll get resources named like:
```
S3 Buckets:
- dev-myapp-app-data
- dev-myapp-logs  
- dev-myapp-backups
- staging-myapp-app-data
- staging-myapp-logs
- staging-myapp-backups
- prod-myapp-app-data
- prod-myapp-logs
- prod-myapp-backups
```

## Troubleshooting

### Common Issues

**1. State Lock Issues**
```bash
# Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

**2. Permission Issues**
- Verify AWS credentials in GitHub secrets
- Check IAM policies for required permissions
- Ensure S3 bucket and DynamoDB table exist

**3. Plan/Apply Failures**
- Check Terraform syntax with `terraform validate`
- Verify variable values in tfvars files
- Review AWS service limits

**4. GitHub Actions Issues**
- Check workflow YAML syntax
- Verify environment protections
- Review action logs for detailed errors

### Useful Commands

```bash
# Format Terraform code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Import existing resource
terraform import aws_s3_bucket.example bucket-name
```

### Getting Help

1. Check GitHub Actions logs for detailed error messages
2. Review Terraform plan output carefully
3. Validate AWS permissions and resource limits
4. Consult team documentation and runbooks
5. Escalate to senior team members for production issues