# Variables for security group remediation testing

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "sec-test"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "testing"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access (your IP)"
  type        = string
  default     = "192.168.1.0/24"
  # Change this to your actual IP/network for secure testing
  # You can get your IP with: curl ifconfig.me
}

# variable "instance_type" {
#   description = "EC2 instance type for test instances"
#   type        = string
#   default     = "t3.micro"
# }

# variable "public_key_content" {
#   description = "Public key content for EC2 key pair"
#   type        = string
#   default     = ""
#   # Add your public key content here if you want to deploy test instances
# }

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}
