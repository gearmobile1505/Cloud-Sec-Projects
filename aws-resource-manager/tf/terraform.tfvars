# Security Group Testing Configuration
aws_region = "us-east-1"
project_name = "sec-test"
environment = "testing"

# Network configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# SSH access restricted to your IP
allowed_ssh_cidr = "24.181.3.125/32"

# EC2 instance type (if enabling instances)
instance_type = "t3.micro"

# SSH public key (leave empty to disable instances)
public_key_content = ""
