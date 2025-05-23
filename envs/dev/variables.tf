variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}


variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "example-bucket"
}

variable "team_name" {
  description = "Team name"
  type        = string
  default     = "example-team"
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = "12345"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "example-project"
}
