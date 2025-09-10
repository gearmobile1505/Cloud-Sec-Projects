# Phase 2: AWS Control Tower & Landing Zone Setup
# Deploys Control Tower with foundational accounts and security baseline

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

# Import outputs from Phase 1 (Organizations)
data "terraform_remote_state" "organizations" {
  backend = "local" # Change to your backend
  
  config = {
    path = "../01-organizations/terraform.tfstate"
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

variable "log_archive_account_name" {
  description = "Name for the Log Archive account"
  type        = string
  default     = "Log Archive"
}

variable "audit_account_name" {
  description = "Name for the Audit account"  
  type        = string
  default     = "Audit"
}

variable "log_archive_account_email" {
  description = "Email for Log Archive account"
  type        = string
}

variable "audit_account_email" {
  description = "Email for Audit account"
  type        = string
}

variable "additional_regions" {
  description = "Additional regions to govern with Control Tower"
  type        = list(string)
  default     = ["us-west-2"]
}

# Control Tower Landing Zone
resource "aws_controltower_landing_zone" "main" {
  manifest_json = jsonencode({
    # Control Tower Landing Zone Manifest
    governedRegions = concat([var.home_region], var.additional_regions)
    
    organizationStructure = {
      core = {
        name = data.terraform_remote_state.organizations.outputs.core_ou_id
      }
    }
    
    centralizedLogging = {
      accountId = aws_organizations_account.log_archive.id
      configurations = {
        loggingBucket = {
          retentionDays = 365
        }
        accessLoggingBucket = {
          retentionDays = 3653 # 10 years
        }
        kmsKeyArn = aws_kms_key.control_tower.arn
      }
    }
    
    securityRoles = {
      accountId = aws_organizations_account.audit.id
    }
    
    accessManagement = {
      enabled = true
    }
  })
  
  version = "3.3"
  
  tags = {
    Name = "Control Tower Landing Zone"
  }
}

# Log Archive Account
resource "aws_organizations_account" "log_archive" {
  name                       = var.log_archive_account_name
  email                      = var.log_archive_account_email
  parent_id                  = data.terraform_remote_state.organizations.outputs.core_ou_id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "DENY"
  
  tags = {
    AccountType = "LogArchive"
    Purpose     = "Centralized logging and compliance"
  }
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Audit Account
resource "aws_organizations_account" "audit" {
  name                       = var.audit_account_name
  email                      = var.audit_account_email
  parent_id                  = data.terraform_remote_state.organizations.outputs.core_ou_id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "DENY"
  
  tags = {
    AccountType = "Audit"
    Purpose     = "Security auditing and compliance"
  }
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# KMS Key for Control Tower
resource "aws_kms_key" "control_tower" {
  description             = "Control Tower KMS key for encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Control Tower"
        Effect = "Allow"
        Principal = {
          Service = [
            "controltower.amazonaws.com",
            "cloudtrail.amazonaws.com",
            "logs.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "Control Tower KMS Key"
  }
}

resource "aws_kms_alias" "control_tower" {
  name          = "alias/control-tower"
  target_key_id = aws_kms_key.control_tower.key_id
}

# Get current account info
data "aws_caller_identity" "current" {}

# SNS Topic for Control Tower notifications
resource "aws_sns_topic" "control_tower_notifications" {
  name = "control-tower-notifications"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "controltower.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = "arn:aws:sns:${var.home_region}:${data.aws_caller_identity.current.account_id}:control-tower-notifications"
      }
    ]
  })
  
  tags = {
    Name = "Control Tower Notifications"
  }
}

# Output important values
output "control_tower_landing_zone_arn" {
  description = "ARN of the Control Tower Landing Zone"
  value       = aws_controltower_landing_zone.main.arn
}

output "control_tower_landing_zone_version" {
  description = "Version of the Control Tower Landing Zone"
  value       = aws_controltower_landing_zone.main.latest_available_version
}

output "log_archive_account_id" {
  description = "ID of the Log Archive account"
  value       = aws_organizations_account.log_archive.id
}

output "audit_account_id" {
  description = "ID of the Audit account" 
  value       = aws_organizations_account.audit.id
}

output "control_tower_kms_key_id" {
  description = "ID of the Control Tower KMS key"
  value       = aws_kms_key.control_tower.key_id
}

output "control_tower_kms_key_arn" {
  description = "ARN of the Control Tower KMS key"
  value       = aws_kms_key.control_tower.arn
}

output "control_tower_sns_topic_arn" {
  description = "ARN of the Control Tower SNS topic"
  value       = aws_sns_topic.control_tower_notifications.arn
}
