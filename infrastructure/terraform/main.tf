terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "diamitani-industries-terraform-state"
    key            = "healthie/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "diamitani-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Organization = "Diamitani Industries"
      Project      = "Healthie"
      ManagedBy    = "Terraform"
      Environment  = var.environment
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
