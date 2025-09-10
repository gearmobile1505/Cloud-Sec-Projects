# Phase 4: Account Factory for Terraform (AFT)
# Automates account provisioning with Terraform

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
      Project     = "Control-Tower-AFT"
      Environment = "Management"
      Owner       = var.organization_name
    }
  }
}

provider "aws" {
  alias  = "aft_management"
  region = var.aft_management_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "Control-Tower-AFT"
      Environment = "AFT-Management"
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

data "terraform_remote_state" "control_tower" {
  backend = "local"
  
  config = {
    path = "../02-control-tower/terraform.tfstate"
  }
}

# Variables
variable "home_region" {
  description = "Primary region for Control Tower deployment"
  type        = string
  default     = "us-east-1"
}

variable "aft_management_region" {
  description = "Region for AFT management resources"
  type        = string
  default     = "us-east-1"
}

variable "organization_name" {
  description = "Name of your organization"
  type        = string
}

variable "aft_account_name" {
  description = "Name for the AFT Management account"
  type        = string
  default     = "AFT Management"
}

variable "aft_account_email" {
  description = "Email for AFT Management account"
  type        = string
}

variable "github_repository_url" {
  description = "GitHub repository URL for AFT account configurations"
  type        = string
  default     = ""
}

variable "codecommit_repository_name" {
  description = "CodeCommit repository name for AFT (if not using GitHub)"
  type        = string
  default     = "aft-account-request"
}

variable "aft_feature_set" {
  description = "AFT feature set configuration"
  type = object({
    terraform_version                = string
    terraform_distribution           = string
    account_customizations_enabled   = bool
    global_customizations_enabled    = bool
    account_provisioning_enabled     = bool
  })
  default = {
    terraform_version              = "1.5.7"
    terraform_distribution         = "oss"
    account_customizations_enabled = true
    global_customizations_enabled  = true
    account_provisioning_enabled   = true
  }
}

# AFT Management Account
resource "aws_organizations_account" "aft_management" {
  name                       = var.aft_account_name
  email                      = var.aft_account_email
  parent_id                  = data.terraform_remote_state.organizations.outputs.core_ou_id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "DENY"
  
  tags = {
    AccountType = "AFT-Management"
    Purpose     = "Account Factory for Terraform automation"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# AFT S3 Bucket for Terraform State
resource "aws_s3_bucket" "aft_backend" {
  bucket = "aft-backend-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name    = "AFT Terraform Backend"
    Purpose = "AFT state management"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket_versioning" "aft_backend" {
  bucket = aws_s3_bucket.aft_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "aft_backend" {
  bucket = aws_s3_bucket.aft_backend.id
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "aft_backend" {
  bucket = aws_s3_bucket.aft_backend.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "aft_backend_lock" {
  name           = "aft-backend-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name    = "AFT Terraform State Lock"
    Purpose = "AFT state locking"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# CodeCommit Repository for Account Requests (if not using GitHub)
resource "aws_codecommit_repository" "aft_account_request" {
  count           = var.github_repository_url == "" ? 1 : 0
  repository_name = var.codecommit_repository_name
  description     = "AFT Account Request Repository"
  
  tags = {
    Name    = "AFT Account Request Repository"
    Purpose = "Account provisioning automation"
  }
}

# IAM Role for AFT Execution
resource "aws_iam_role" "aft_execution" {
  name = "AFTExecutionRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "codebuild.amazonaws.com",
            "codepipeline.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_organizations_account.aft_management.id}:root"
        }
      }
    ]
  })
  
  tags = {
    Name = "AFT Execution Role"
  }
}

# IAM Policy for AFT Execution
resource "aws_iam_role_policy" "aft_execution" {
  name = "AFTExecutionPolicy"
  role = aws_iam_role.aft_execution.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "organizations:*",
          "controltower:*",
          "servicecatalog:*",
          "iam:*",
          "lambda:*",
          "codebuild:*",
          "codepipeline:*",
          "codecommit:*",
          "s3:*",
          "dynamodb:*",
          "logs:*",
          "events:*",
          "sns:*",
          "sqs:*",
          "ssm:*",
          "sts:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function for AFT Account Provisioning
resource "aws_lambda_function" "aft_account_provisioning" {
  filename         = "aft_provisioning.zip"
  function_name    = "aft-account-provisioning"
  role            = aws_iam_role.aft_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 900
  
  environment {
    variables = {
      AFT_BACKEND_BUCKET     = aws_s3_bucket.aft_backend.id
      AFT_LOCK_TABLE         = aws_dynamodb_table.aft_backend_lock.name
      ORGANIZATION_ID        = data.terraform_remote_state.organizations.outputs.organization_id
      CT_HOME_REGION         = var.home_region
      TERRAFORM_VERSION      = var.aft_feature_set.terraform_version
      TERRAFORM_DISTRIBUTION = var.aft_feature_set.terraform_distribution
    }
  }
  
  tags = {
    Name = "AFT Account Provisioning Lambda"
  }
  
  depends_on = [data.archive_file.aft_lambda_zip]
}

# Lambda IAM Role
resource "aws_iam_role" "aft_lambda" {
  name = "AFTLambdaExecutionRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aft_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.aft_lambda.name
}

# Placeholder Lambda code
data "archive_file" "aft_lambda_zip" {
  type        = "zip"
  output_path = "aft_provisioning.zip"
  
  source {
    content = templatefile("${path.module}/lambda/aft_provisioning.py", {
      organization_id = data.terraform_remote_state.organizations.outputs.organization_id
    })
    filename = "index.py"
  }
}

# SNS Topic for AFT Notifications
resource "aws_sns_topic" "aft_notifications" {
  name = "aft-account-notifications"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "events.amazonaws.com"
          ]
        }
        Action   = "SNS:Publish"
        Resource = "arn:aws:sns:${var.home_region}:*:aft-account-notifications"
      }
    ]
  })
  
  tags = {
    Name = "AFT Account Notifications"
  }
}

# EventBridge Rule for Account Creation Events
resource "aws_cloudwatch_event_rule" "account_creation" {
  name        = "aft-account-creation"
  description = "Capture account creation events from Control Tower"
  
  event_pattern = jsonencode({
    source        = ["aws.controltower"]
    detail-type   = ["AWS Service Event via CloudFormation"]
    detail = {
      eventName = ["CreateManagedAccount"]
      responseElements = {
        createManagedAccountStatus = {
          state = ["SUCCEEDED"]
        }
      }
    }
  })
  
  tags = {
    Name = "AFT Account Creation Rule"
  }
}

resource "aws_cloudwatch_event_target" "account_creation_lambda" {
  rule      = aws_cloudwatch_event_rule.account_creation.name
  target_id = "AFTAccountProvisioningTarget"
  arn       = aws_lambda_function.aft_account_provisioning.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aft_account_provisioning.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.account_creation.arn
}

# Outputs
output "aft_management_account_id" {
  description = "ID of the AFT Management account"
  value       = aws_organizations_account.aft_management.id
}

output "aft_backend_bucket" {
  description = "S3 bucket for AFT Terraform backend"
  value       = aws_s3_bucket.aft_backend.id
}

output "aft_backend_lock_table" {
  description = "DynamoDB table for AFT state locking"
  value       = aws_dynamodb_table.aft_backend_lock.name
}

output "aft_execution_role_arn" {
  description = "ARN of the AFT execution role"
  value       = aws_iam_role.aft_execution.arn
}

output "aft_lambda_function_name" {
  description = "Name of the AFT Lambda function"
  value       = aws_lambda_function.aft_account_provisioning.function_name
}

output "aft_sns_topic_arn" {
  description = "ARN of the AFT SNS topic"
  value       = aws_sns_topic.aft_notifications.arn
}

output "codecommit_repository_url" {
  description = "URL of the CodeCommit repository (if created)"
  value       = length(aws_codecommit_repository.aft_account_request) > 0 ? aws_codecommit_repository.aft_account_request[0].clone_url_http : null
}
