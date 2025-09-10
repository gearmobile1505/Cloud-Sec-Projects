# Phase 1: AWS Organizations Setup
# Creates the foundation for Control Tower and multi-account management

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
  region = var.home_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "Control-Tower-Setup"
      Environment = "Management"
      Owner       = var.organization_name
    }
  }
}

# Variables
variable "home_region" {
  description = "Primary region for Control Tower deployment"
  type        = string
  default     = "us-east-1"
}

variable "organization_name" {
  description = "Name of your organization"
  type        = string
}

variable "core_ou_name" {
  description = "Name for the Core OU"
  type        = string
  default     = "Core"
}

variable "workloads_ou_name" {
  description = "Name for the Workloads OU"
  type        = string
  default     = "Workloads"
}

# Create AWS Organization
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
    "controltower.amazonaws.com",
    "account.amazonaws.com"
  ]
  
  feature_set = "ALL"
  
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY",
    "AISERVICES_OPT_OUT_POLICY"
  ]
}

# Root Organizational Unit (automatically created, just reference)
data "aws_organizations_organization" "current" {
  depends_on = [aws_organizations_organization.main]
}

# Core OU - for foundational accounts (Log Archive, Audit)
resource "aws_organizations_organizational_unit" "core" {
  name      = var.core_ou_name
  parent_id = data.aws_organizations_organization.current.roots[0].id
  
  tags = {
    Purpose = "Core foundational accounts"
    Type    = "Core"
  }
}

# Workloads OU - for application and workload accounts
resource "aws_organizations_organizational_unit" "workloads" {
  name      = var.workloads_ou_name
  parent_id = data.aws_organizations_organization.current.roots[0].id
  
  tags = {
    Purpose = "Application and workload accounts"
    Type    = "Workloads"
  }
}

# Additional OUs for different environments
resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
  
  tags = {
    Purpose = "Production workload accounts"
    Type    = "Production"
  }
}

resource "aws_organizations_organizational_unit" "non_production" {
  name      = "Non-Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
  
  tags = {
    Purpose = "Non-production workload accounts"
    Type    = "Non-Production"
  }
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organizational_unit.workloads.id
  
  tags = {
    Purpose = "Sandbox and development accounts"
    Type    = "Sandbox"
  }
}

# Output important values for next phases
output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization"
  value       = aws_organizations_organization.main.arn
}

output "root_id" {
  description = "The ID of the root OU"
  value       = data.aws_organizations_organization.current.roots[0].id
}

output "core_ou_id" {
  description = "The ID of the Core OU"
  value       = aws_organizations_organizational_unit.core.id
}

output "workloads_ou_id" {
  description = "The ID of the Workloads OU"
  value       = aws_organizations_organizational_unit.workloads.id
}

output "production_ou_id" {
  description = "The ID of the Production OU"
  value       = aws_organizations_organizational_unit.production.id
}

output "non_production_ou_id" {
  description = "The ID of the Non-Production OU"
  value       = aws_organizations_organizational_unit.non_production.id
}

output "sandbox_ou_id" {
  description = "The ID of the Sandbox OU"
  value       = aws_organizations_organizational_unit.sandbox.id
}

output "management_account_id" {
  description = "The ID of the management account"
  value       = data.aws_organizations_organization.current.master_account_id
}
