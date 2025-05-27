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
    key    = "prod/terraform.tfstate"
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
  environment = "prod" # Only line that changes per environment
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Application data bucket
module "app_bucket" {
  source = "../../modules/s3"

  environment = local.environment
  bucket_name = "myapp-data-${random_string.suffix.result}"
}

# Logs bucket
module "logs_bucket" {
  source = "../../modules/s3"

  environment = local.environment
  bucket_name = "myapp-logs-${random_string.suffix.result}"
}

# Static assets bucket
module "assets_bucket" {
  source = "../../modules/s3"

  environment = local.environment
  bucket_name = "myapp-assets-${random_string.suffix.result}"
}
