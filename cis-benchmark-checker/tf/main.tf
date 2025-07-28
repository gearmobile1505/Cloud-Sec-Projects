# CIS Benchmark Test Infrastructure
# This Terraform configuration creates AWS resources to test CIS compliance checks
# Some resources are intentionally non-compliant for testing purposes

terraform {
  required_version = ">= 1.0"
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
      Project     = "CIS-Benchmark-Testing"
      Environment = var.environment
      CreatedBy   = "Terraform"
      Purpose     = "CIS-Compliance-Testing"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  common_tags = {
    Project     = "CIS-Benchmark-Testing"
    Environment = var.environment
    CreatedBy   = "Terraform"
  }
}
