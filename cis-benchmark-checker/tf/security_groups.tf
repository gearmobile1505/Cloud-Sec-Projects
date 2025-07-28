# Security Groups for CIS Testing

# Default Security Group (CIS 5.3 - Should restrict all traffic)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # Remove all default rules - CIS 5.3 compliant
  ingress = []
  egress  = []

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-default-sg-compliant"
    Note = "CIS 5.3 Compliant - No traffic allowed"
  })
}

# Compliant Security Group - Restricted SSH (CIS 5.2 compliant)
resource "aws_security_group" "compliant_ssh" {
  name_prefix = "${var.project_name}-compliant-ssh"
  description = "CIS 5.2 Compliant - SSH from specific IP ranges only"
  vpc_id      = aws_vpc.main.id

  # SSH from specific IP ranges (not 0.0.0.0/0)
  ingress {
    description = "SSH from office network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]  # Private ranges only
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-compliant-ssh-sg"
    Note = "CIS 5.2 Compliant - SSH not from 0.0.0.0/0"
  })
}

# Non-Compliant Security Group - Open SSH (CIS 5.2 violation)
resource "aws_security_group" "non_compliant_ssh" {
  count = var.create_non_compliant_resources ? 1 : 0

  name_prefix = "${var.project_name}-non-compliant-ssh"
  description = "CIS 5.2 VIOLATION - SSH from anywhere"
  vpc_id      = aws_vpc.main.id

  # SSH from anywhere - CIS 5.2 violation
  ingress {
    description = "SSH from anywhere - VIOLATION"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # This violates CIS 5.2
  }

  # RDP from anywhere - Another CIS 5.2 violation
  ingress {
    description = "RDP from anywhere - VIOLATION"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # This violates CIS 5.2
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-non-compliant-ssh-sg"
    Note = "CIS 5.2 VIOLATION - SSH and RDP from 0.0.0.0/0"
  })
}

# Web Server Security Group - Compliant
resource "aws_security_group" "web_server" {
  name_prefix = "${var.project_name}-web-server"
  description = "Web server security group - HTTP/HTTPS allowed"
  vpc_id      = aws_vpc.main.id

  # HTTP from anywhere (acceptable for web servers)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere (acceptable for web servers)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-server-sg"
    Note = "Compliant - Only HTTP/HTTPS from 0.0.0.0/0"
  })
}

# Database Security Group - Compliant
resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-database"
  description = "Database security group - MySQL from web servers only"
  vpc_id      = aws_vpc.main.id

  # MySQL from web server security group only
  ingress {
    description     = "MySQL from web servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server.id]
  }

  # No egress rules needed for database

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-database-sg"
    Note = "Compliant - Database access from specific security groups only"
  })
}
