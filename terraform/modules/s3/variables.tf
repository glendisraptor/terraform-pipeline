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
