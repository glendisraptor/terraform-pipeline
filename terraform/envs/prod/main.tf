terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket-345676654" # Replace with your state bucket
    key    = "prod/terraform.tfstate"           # Only this line changes
    region = "af-south-1"

    # Enable state locking
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "af-south-1"

  default_tags {
    tags = {
      Environment = local.environment
      ManagedBy   = "Terraform"
      Team        = "platform-team"
    }
  }
}

locals {
  environment = "prod" # Only this line changes
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
