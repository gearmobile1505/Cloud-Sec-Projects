# Terraform configuration for testing security group remediation
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
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create a VPC for our test resources
resource "aws_vpc" "test_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-test-vpc"
    Environment = var.environment
    Purpose     = "Security Testing"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name        = "${var.project_name}-test-igw"
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "test_public_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Type        = "Public"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "test_public_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# Route Table Association
resource "aws_route_table_association" "test_public_rta" {
  subnet_id      = aws_subnet.test_public_subnet.id
  route_table_id = aws_route_table.test_public_rt.id
}

# Security Groups with Various Risk Levels

# HIGH RISK: SSH and RDP open to the world
resource "aws_security_group" "high_risk_sg" {
  name_prefix = "${var.project_name}-high-risk-"
  description = "HIGH RISK: SSH and RDP open to internet - FOR TESTING ONLY"
  vpc_id      = aws_vpc.test_vpc.id

  # SSH open to the world (HIGH RISK)
  ingress {
    description = "SSH from anywhere - HIGH RISK"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDP open to the world (HIGH RISK)
  ingress {
    description = "RDP from anywhere - HIGH RISK"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-high-risk-sg"
    Environment = var.environment
    RiskLevel   = "HIGH"
    Purpose     = "Testing security remediation"
  }
}

# MEDIUM RISK: Database ports open to the world
resource "aws_security_group" "medium_risk_sg" {
  name_prefix = "${var.project_name}-medium-risk-"
  description = "MEDIUM RISK: Database ports open to internet - FOR TESTING ONLY"
  vpc_id      = aws_vpc.test_vpc.id

  # MySQL open to the world (MEDIUM RISK)
  ingress {
    description = "MySQL from anywhere - MEDIUM RISK"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL open to the world (MEDIUM RISK)
  ingress {
    description = "PostgreSQL from anywhere - MEDIUM RISK"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis open to the world (MEDIUM RISK)
  ingress {
    description = "Redis from anywhere - MEDIUM RISK"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MongoDB open to the world (MEDIUM RISK)
  ingress {
    description = "MongoDB from anywhere - MEDIUM RISK"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-medium-risk-sg"
    Environment = var.environment
    RiskLevel   = "MEDIUM"
    Purpose     = "Testing security remediation"
  }
}

# LOW RISK: Web traffic and restricted SSH
resource "aws_security_group" "low_risk_sg" {
  name_prefix = "${var.project_name}-low-risk-"
  description = "LOW RISK: Only web traffic and restricted SSH"
  vpc_id      = aws_vpc.test_vpc.id

  # HTTP from anywhere (acceptable)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere (acceptable)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH only from private networks (good practice)
  ingress {
    description = "SSH from private networks only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-low-risk-sg"
    Environment = var.environment
    RiskLevel   = "LOW"
    Purpose     = "Testing security remediation"
  }
}

# EXTREME RISK: All protocols open to the world
resource "aws_security_group" "extreme_risk_sg" {
  name_prefix = "${var.project_name}-extreme-risk-"
  description = "EXTREME RISK: All protocols open to internet - FOR TESTING ONLY"
  vpc_id      = aws_vpc.test_vpc.id

  # ALL PROTOCOLS open to the world (EXTREME RISK)
  ingress {
    description = "All protocols from anywhere - EXTREME RISK"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-extreme-risk-sg"
    Environment = var.environment
    RiskLevel   = "EXTREME"
    Purpose     = "Testing security remediation"
  }
}

# SECURE: Properly configured security group (baseline)
resource "aws_security_group" "secure_sg" {
  name_prefix = "${var.project_name}-secure-"
  description = "SECURE: Properly configured security group"
  vpc_id      = aws_vpc.test_vpc.id

  # HTTP from anywhere (acceptable for web servers)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere (acceptable for web servers)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH only from specific IP (your IP - will be updated via variables)
  ingress {
    description = "SSH from specific IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-secure-sg"
    Environment = var.environment
    RiskLevel   = "SECURE"
    Purpose     = "Testing security remediation"
  }
}

# Test EC2 Instances (optional - commented out to avoid charges)
# Uncomment if you want to test with actual instances

/*
# Key Pair for testing
resource "aws_key_pair" "test_key" {
  key_name   = "${var.project_name}-test-key"
  public_key = var.public_key_content
  
  tags = {
    Name        = "${var.project_name}-test-key"
    Environment = var.environment
  }
}

# Test instance with high-risk security group
resource "aws_instance" "test_high_risk" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.test_key.key_name
  vpc_security_group_ids  = [aws_security_group.high_risk_sg.id]
  subnet_id              = aws_subnet.test_public_subnet.id
  
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>High Risk Test Instance</h1>" > /var/www/html/index.html
              EOF
  )

  tags = {
    Name        = "${var.project_name}-high-risk-instance"
    Environment = var.environment
    RiskLevel   = "HIGH"
  }
}

# Data source for Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
*/
