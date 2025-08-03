# Variables for CIS Benchmark Test Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., test, dev, prod)"
  type        = string
  default     = "test"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cis-benchmark-test"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "create_non_compliant_resources" {
  description = "Whether to create intentionally non-compliant resources for testing"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs (CIS 5.5)"
  type        = bool
  default     = true
}
