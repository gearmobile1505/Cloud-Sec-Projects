

variable "central_account_id" {
  description = "AWS Account ID where the Lambda function is deployed"
  type        = string
}

variable "lambda_role_name" {
  description = "Name of the Lambda execution role in the central account"
  type        = string
  default     = "lambda-vpc-flow-logs-enabler-role"
}

# Cross-account role that the Lambda function will assume
resource "aws_iam_role" "vpc_flow_logs_cross_account_role" {
  name = "VPC_FlowLogs_CrossAccountRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.central_account_id}:role/${var.lambda_role_name}"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "vpc-flow-logs-cross-account"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "VPC_FlowLogs_CrossAccountRole"
    Purpose     = "Allow central Lambda to enable VPC Flow Logs"
    Environment = "production"
  }
}

# IAM policy for VPC Flow Logs operations
data "aws_iam_policy_document" "vpc_flow_logs_permissions" {
  statement {
    sid    = "VPCFlowLogsPermissions"
    effect = "Allow"
    
    actions = [
      "ec2:CreateFlowLogs",
      "ec2:DescribeFlowLogs",
      "ec2:DescribeVpcs",
      "ec2:DescribeRegions"
    ]
    
    resources = ["*"]
  }
  
  statement {
    sid    = "LogsDeliveryPermissions"
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/vpc/flowlogs*"
    ]
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy" "vpc_flow_logs_cross_account_policy" {
  name   = "vpc-flow-logs-permissions"
  role   = aws_iam_role.vpc_flow_logs_cross_account_role.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_permissions.json
}

# Output the role ARN for reference
output "cross_account_role_arn" {
  description = "ARN of the cross-account role"
  value       = aws_iam_role.vpc_flow_logs_cross_account_role.arn
}
