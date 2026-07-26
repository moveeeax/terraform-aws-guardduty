terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.20.0"
    }
  }
}

variable "region" {
  description = "AWS region for the provider."
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.region
}

module "guardduty" {
  source = "../.."

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  enable_s3_protection         = true
  enable_rds_protection        = true
  enable_lambda_protection     = true

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "detector_id" {
  value = module.guardduty.id
}

output "features" {
  value = module.guardduty.features
}
