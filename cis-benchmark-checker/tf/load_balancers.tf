# Load Balancer Resources
# This file creates Terraform-managed load balancers to replace the Kubernetes-managed ones
# This ensures proper cleanup and lifecycle management

# Application Load Balancer (ALB)
resource "aws_lb" "main_alb" {
  count              = var.create_alb ? 1 : 0
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  # Enable access logs (optional - disabled for cost savings)
  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "alb-logs"
  #   enabled = true
  # }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb"
    Type = "Application Load Balancer"
  })
}

# Target Group for ALB
resource "aws_lb_target_group" "alb_tg" {
  count    = var.create_alb ? 1 : 0
  name     = "${var.project_name}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-target-group"
  })
}

# ALB Listener
resource "aws_lb_listener" "alb_listener" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.main_alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg[0].arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-listener"
  })
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  count       = var.create_alb ? 1 : 0
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
