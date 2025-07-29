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

  # SQL Server open to the world (MEDIUM RISK)
  ingress {
    description = "SQL Server from anywhere - MEDIUM RISK"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Elasticsearch open to the world (MEDIUM RISK)
  ingress {
    description = "Elasticsearch from anywhere - MEDIUM RISK"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana open to the world (MEDIUM RISK)
  ingress {
    description = "Kibana from anywhere - MEDIUM RISK"
    from_port   = 5601
    to_port     = 5601
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

# VPC Remediation Testing Resources
# These resources test the emergency_remediation.sh script

# Private Subnet for testing isolation
resource "aws_subnet" "test_private_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Environment = var.environment
    Type        = "Private"
  }
}

# Custom Network ACL with permissive rules (for testing lockdown)
resource "aws_network_acl" "test_permissive_nacl" {
  vpc_id = aws_vpc.test_vpc.id

  # Allow all inbound traffic (RISKY - for testing)
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "${var.project_name}-permissive-nacl"
    Environment = var.environment
    Purpose     = "Testing emergency lockdown"
    RiskLevel   = "HIGH"
  }
}

# Associate permissive NACL with public subnet for testing
resource "aws_network_acl_association" "test_public_nacl_assoc" {
  network_acl_id = aws_network_acl.test_permissive_nacl.id
  subnet_id      = aws_subnet.test_public_subnet.id
}

# Route Table for Private Subnet (no internet access initially)
resource "aws_route_table" "test_private_rt" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
    Type        = "Private"
  }
}

# Route Table Association for Private Subnet
resource "aws_route_table_association" "test_private_rta" {
  subnet_id      = aws_subnet.test_private_subnet.id
  route_table_id = aws_route_table.test_private_rt.id
}

# NAT Gateway for testing route modification
resource "aws_eip" "test_nat_eip" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
    Purpose     = "Testing emergency remediation"
  }

  depends_on = [aws_internet_gateway.test_igw]
}

resource "aws_nat_gateway" "test_nat" {
  allocation_id = aws_eip.test_nat_eip.id
  subnet_id     = aws_subnet.test_public_subnet.id

  tags = {
    Name        = "${var.project_name}-nat-gateway"
    Environment = var.environment
    Purpose     = "Testing emergency remediation"
  }

  depends_on = [aws_internet_gateway.test_igw]
}

# Add route to NAT Gateway in private route table
resource "aws_route" "test_private_nat_route" {
  route_table_id         = aws_route_table.test_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.test_nat.id
}

# Additional route table with direct internet access (risky for testing)
resource "aws_route_table" "test_risky_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name        = "${var.project_name}-risky-rt"
    Environment = var.environment
    Purpose     = "Testing emergency route lockdown"
    RiskLevel   = "HIGH"
  }
}

# VPC Flow Logs for testing monitoring
resource "aws_flow_log" "test_vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.test_vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-vpc-flow-logs"
    Environment = var.environment
  }
}

resource "aws_iam_role" "flow_log_role" {
  name = "${var.project_name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-flow-log-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "${var.project_name}-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
