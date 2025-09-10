# Phase 3: Service Control Policies (SCPs)
# Implements governance guardrails and compliance policies

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

# Import outputs from previous phases
data "terraform_remote_state" "organizations" {
  backend = "local"
  
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

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

# Deny Root Account Usage SCP
resource "aws_organizations_policy" "deny_root_usage" {
  name        = "DenyRootAccountUsage"
  description = "Deny usage of root account for daily operations"
  type        = "SERVICE_CONTROL_POLICY"
  
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyRootAccountUsage"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken",
          "account:*",
          "billing:*",
          "payments:*",
          "support:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalType" = "Root"
          }
        }
      }
    ]
  })
  
  tags = {
    PolicyType = "Security"
    Purpose    = "Prevent root account misuse"
  }
}

# Region Restriction SCP  
resource "aws_organizations_policy" "restrict_regions" {
  name        = "RestrictRegions"
  description = "Restrict operations to approved regions only"
  type        = "SERVICE_CONTROL_POLICY"
  
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RestrictRegions"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
          "ForAllValues:StringNotEquals" = {
            "aws:PrincipalServiceName" = [
              "cloudfront.amazonaws.com",
              "iam.amazonaws.com",
              "route53.amazonaws.com",
              "support.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
  
  tags = {
    PolicyType = "Governance"
    Purpose    = "Geographic data residency compliance"
  }
}

# Prevent Security Service Disabling
resource "aws_organizations_policy" "prevent_security_disabling" {
  name        = "PreventSecurityServiceDisabling"
  description = "Prevent disabling of key security services"
  type        = "SERVICE_CONTROL_POLICY"
  
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PreventCloudTrailDisabling"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail"
        ]
        Resource = "*"
      },
      {
        Sid    = "PreventConfigDisabling"
        Effect = "Deny"
        Action = [
          "config:StopConfigurationRecorder",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      },
      {
        Sid    = "PreventGuardDutyDisabling"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DeleteIPSet",
          "guardduty:DeleteThreatIntelSet",
          "guardduty:StopMonitoringMembers",
          "guardduty:UpdateDetector"
        ]
        Resource = "*"
      },
      {
        Sid    = "PreventSecurityHubDisabling"
        Effect = "Deny"
        Action = [
          "securityhub:DeleteInsight",
          "securityhub:DisableSecurityHub",
          "securityhub:DisableImportFindingsForProduct",
          "securityhub:BatchDisableStandards"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    PolicyType = "Security"
    Purpose    = "Maintain security baseline"
  }
}

# Production Environment SCP (More Restrictive)
resource "aws_organizations_policy" "production_restrictions" {
  name        = "ProductionRestrictions"
  description = "Additional restrictions for production accounts"
  type        = "SERVICE_CONTROL_POLICY"
  
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInstanceTermination"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::*:role/ProductionAdminRole",
              "arn:aws:iam::*:role/AutoScalingServiceRole"
            ]
          }
        }
      },
      {
        Sid    = "RestrictInstanceTypes"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotEquals = {
            "ec2:InstanceType" = [
              "t3.micro",
              "t3.small",
              "t3.medium",
              "m5.large",
              "m5.xlarge",
              "r5.large",
              "r5.xlarge"
            ]
          }
        }
      },
      {
        Sid    = "PreventResourceDeletion"
        Effect = "Deny"
        Action = [
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "s3:DeleteBucket",
          "dynamodb:DeleteTable"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
  
  tags = {
    PolicyType = "Governance"
    Purpose    = "Production environment protection"
  }
}

# Sandbox Environment SCP (Permissive but Safe)
resource "aws_organizations_policy" "sandbox_restrictions" {
  name        = "SandboxRestrictions" 
  description = "Cost and security controls for sandbox accounts"
  type        = "SERVICE_CONTROL_POLICY"
  
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RestrictExpensiveInstances"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          "ForAnyValue:StringNotEquals" = {
            "ec2:InstanceType" = [
              "t2.micro",
              "t2.small", 
              "t3.micro",
              "t3.small",
              "t3.medium"
            ]
          }
        }
      },
      {
        Sid    = "PreventExpensiveServices"
        Effect = "Deny"
        Action = [
          "redshift:*",
          "elasticmapreduce:*",
          "sagemaker:CreateNotebookInstance",
          "databrew:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "RestrictNetworkChanges"
        Effect = "Deny"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    PolicyType = "Cost-Control"
    Purpose    = "Sandbox cost and security limits"
  }
}

# Attach SCPs to Organizational Units

# Root-level policies (apply to all accounts)
resource "aws_organizations_policy_attachment" "deny_root_usage_root" {
  policy_id = aws_organizations_policy.deny_root_usage.id
  target_id = data.terraform_remote_state.organizations.outputs.root_id
}

resource "aws_organizations_policy_attachment" "restrict_regions_root" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = data.terraform_remote_state.organizations.outputs.root_id
}

resource "aws_organizations_policy_attachment" "prevent_security_disabling_root" {
  policy_id = aws_organizations_policy.prevent_security_disabling.id
  target_id = data.terraform_remote_state.organizations.outputs.root_id
}

# Production-specific policies
resource "aws_organizations_policy_attachment" "production_restrictions" {
  policy_id = aws_organizations_policy.production_restrictions.id
  target_id = data.terraform_remote_state.organizations.outputs.production_ou_id
}

# Sandbox-specific policies  
resource "aws_organizations_policy_attachment" "sandbox_restrictions" {
  policy_id = aws_organizations_policy.sandbox_restrictions.id
  target_id = data.terraform_remote_state.organizations.outputs.sandbox_ou_id
}

# Outputs
output "scp_policy_ids" {
  description = "IDs of all created Service Control Policies"
  value = {
    deny_root_usage            = aws_organizations_policy.deny_root_usage.id
    restrict_regions          = aws_organizations_policy.restrict_regions.id
    prevent_security_disabling = aws_organizations_policy.prevent_security_disabling.id
    production_restrictions   = aws_organizations_policy.production_restrictions.id
    sandbox_restrictions      = aws_organizations_policy.sandbox_restrictions.id
  }
}

output "scp_policy_arns" {
  description = "ARNs of all created Service Control Policies"
  value = {
    deny_root_usage            = aws_organizations_policy.deny_root_usage.arn
    restrict_regions          = aws_organizations_policy.restrict_regions.arn
    prevent_security_disabling = aws_organizations_policy.prevent_security_disabling.arn
    production_restrictions   = aws_organizations_policy.production_restrictions.arn
    sandbox_restrictions      = aws_organizations_policy.sandbox_restrictions.arn
  }
}
