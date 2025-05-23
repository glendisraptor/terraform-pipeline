terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "your-terraform-state-bucket" # Replace with your state bucket
    key    = "staging/terraform.tfstate"   # Only this line changes
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
  environment = "staging" # Only this line changes
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
