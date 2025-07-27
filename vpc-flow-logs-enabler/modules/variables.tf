variable "vpc_ids" {
  description = "List of VPC IDs to enable flow logs for"
  type        = list(string)
  validation {
    condition     = length(var.vpc_ids) > 0
    error_message = "At least one VPC ID must be provided."
  }
}

variable "log_destination_type" {
  description = "The type of destination for VPC Flow Logs (cloud-watch-logs, s3, kinesis-data-firehose)"
  type        = string
  default     = "cloud-watch-logs"
  validation {
    condition = contains([
      "cloud-watch-logs",
      "s3", 
      "kinesis-data-firehose"
    ], var.log_destination_type)
    error_message = "log_destination_type must be one of: cloud-watch-logs, s3, kinesis-data-firehose."
  }
}

variable "log_destination_arn" {
  description = "ARN of the destination for VPC Flow Logs (CloudWatch Log Group, S3 Bucket, or Kinesis Data Firehose)"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs (used when log_destination_type is cloud-watch-logs)"
  type        = string
  default     = "vpc-flow-logs"
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "log_retention_days must be one of the valid CloudWatch log retention values."
  }
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for VPC Flow Logs (used when log_destination_type is s3)"
  type        = string
  default     = null
}

variable "s3_key_prefix" {
  description = "S3 key prefix for VPC Flow Logs"
  type        = string
  default     = "vpc-flow-logs/"
}

variable "traffic_type" {
  description = "The type of traffic to capture (ALL, ACCEPT, REJECT)"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.traffic_type)
    error_message = "traffic_type must be one of: ALL, ACCEPT, REJECT."
  }
}

variable "log_format" {
  description = "The fields to include in the flow log record"
  type        = string
  default     = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${windowstart} $${windowend} $${action} $${flowlogstatus}"
}

variable "max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record (60 or 600 seconds)"
  type        = number
  default     = 600
  validation {
    condition     = contains([60, 600], var.max_aggregation_interval)
    error_message = "max_aggregation_interval must be either 60 or 600 seconds."
  }
}

variable "iam_role_name" {
  description = "Name of the IAM role for VPC Flow Logs delivery"
  type        = string
  default     = "vpc-flow-logs-role"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "VPC-Flow-Logs-Enabler"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_cloudwatch_log_group" {
  description = "Whether to create a new CloudWatch Log Group"
  type        = bool
  default     = true
}

variable "create_s3_bucket" {
  description = "Whether to create a new S3 bucket for flow logs"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting flow logs (optional)"
  type        = string
  default     = null
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  validation {
    condition     = length(var.function_name) > 0 && length(var.function_name) <= 64
    error_message = "Function name must be between 1 and 64 characters."
  }
}

variable "handler" {
  description = "Lambda function entry point"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.12"
  validation {
    condition = contains([
      "python3.8", "python3.9", "python3.10", "python3.11", "python3.12",
      "nodejs18.x", "nodejs20.x", "java11", "java17", "java21",
      "dotnet6", "dotnet8", "go1.x", "provided.al2", "provided.al2023"
    ], var.runtime)
    error_message = "Runtime must be a valid AWS Lambda runtime."
  }
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "source_path" {
  description = "Path to the source code for the Lambda function"
  type        = string
}

variable "Lambda_memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 128
  validation {
    condition     = var.Lambda_memory_size >= 128 && var.Lambda_memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10,240 MB."
  }
}

variable "lambda_layers" {
  description = "List of Lambda layer ARNs to attach to the function"
  type        = list(string)
  default     = []
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda function version"
  type        = bool
  default     = false
}

variable "Lambda_function_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 3
  validation {
    condition     = var.Lambda_function_timeout >= 1 && var.Lambda_function_timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "trusted_entities" {
  description = "List of trusted entities for the Lambda execution role"
  type        = list(string)
  default     = ["lambda.amazonaws.com"]
}

variable "attach_policy_json" {
  description = "Whether to attach a JSON policy to the Lambda execution role"
  type        = bool
  default     = false
}

variable "lambda_policy" {
  description = "JSON policy document to attach to the Lambda execution role"
  type        = string
  default     = null
}

variable "lambda_policy_path" {
  description = "Path to the policy file for the Lambda execution role"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "VPC-Flow-Logs-Enabler"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}