variable "aws_region" {
  description = "AWS region for Healthie deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "diamitani-industries"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "healthie"
}

variable "domain_name" {
  description = "Domain name for Healthie application"
  type        = string
  default     = "healthie.diamitani.com"
}

variable "allowed_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["https://healthie.diamitani.com"]
}

variable "enable_waf" {
  description = "Enable AWS WAF for additional security"
  type        = bool
  default     = true
}

variable "enable_cognito_mfa" {
  description = "Enable MFA for Cognito user pool"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "backup_retention_days" {
  description = "Database backup retention in days"
  type        = number
  default     = 30
}
