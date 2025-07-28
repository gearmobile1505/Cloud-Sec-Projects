# EKS Cluster Configuration
# Clean EKS cluster deployment with proper security settings

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  # Enable logging for better security monitoring
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Enable encryption at rest
  # Note: Encryption disabled for simplified cleanup
  # encryption_config {
  #   resources = ["secrets"]
  #   provider {
  #     key_arn = aws_kms_key.cloudtrail.arn
  #   }
  # }

  depends_on = [
    aws_iam_role_policy_attachment.eks_policy,
    aws_cloudwatch_log_group.eks_cluster_logs,
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-cluster"
  })
}

# CloudWatch Log Group for EKS Cluster Logs
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/aws/eks/${var.project_name}-eks-cluster/cluster"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-cluster-logs"
  })
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  ami_type       = "AL2023_x86_64_STANDARD"

  # Optional: Enable remote access if needed
  # remote_access {
  #   ec2_ssh_key = aws_key_pair.eks_nodes.key_name
  # }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-node-group"
  })
}

# IAM Roles for EKS
resource "aws_iam_role" "eks_role" {
  name = "${var.project_name}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-role"
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role" "node_role" {
  name = "${var.project_name}-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  count = 3
  policy_arn = element([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ], count.index)
  role = aws_iam_role.node_role.name
}

resource "aws_iam_policy" "eks_view_resources_policy" {
  name        = "${var.project_name}-EKSViewResourcesPolicy"
  description = "Policy to allow a principal to view Kubernetes resources for all clusters in the account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:ListFargateProfiles",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListUpdates",
          "eks:AccessKubernetesApi",
          "eks:ListAddons",
          "eks:DescribeCluster",
          "eks:DescribeAddonVersions",
          "eks:ListClusters",
          "eks:ListIdentityProviderConfigs",
          "iam:ListRoles"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "arn:aws:ssm:*:${local.account_id}:parameter/*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-EKSViewResourcesPolicy"
  })
}

resource "aws_iam_role" "eks_connector_agent_role" {
  name = "${var.project_name}-EKSConnectorAgentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-EKSConnectorAgentRole"
  })
}

resource "aws_iam_policy" "eks_connector_agent_policy" {
  name        = "${var.project_name}-EKSConnectorAgentPolicy"
  description = "Policy for EKS Connector Agent"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SsmControlChannel"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel"
        ]
        Resource = "arn:aws:eks:*:*:cluster/*"
      },
      {
        Sid    = "ssmDataplaneOperations"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenDataChannel",
          "ssmmessages:OpenControlChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-EKSConnectorAgentPolicy"
  })
}

resource "aws_iam_role_policy_attachment" "eks_connector_agent_policy_attachment" {
  role       = aws_iam_role.eks_connector_agent_role.name
  policy_arn = aws_iam_policy.eks_connector_agent_policy.arn
}

# Security Groups for EKS

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-eks-cluster-"
  vpc_id      = aws_vpc.main.id

  # HTTPS access from specific IP
  # TEMPORARY: Using 0.0.0.0/0 for cleanup - replace with YOUR_IP_ADDRESS/32 for deployment
  ingress {
    description = "HTTPS access from specific IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with YOUR_IP_ADDRESS/32
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-cluster-sg"
  })
}

# EKS Node Group Security Group
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-eks-nodes-"
  vpc_id      = aws_vpc.main.id

  # SSH access from specific IP
  # TEMPORARY: Using 0.0.0.0/0 for cleanup - replace with YOUR_IP_ADDRESS/32 for deployment
  ingress {
    description = "SSH access from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with YOUR_IP_ADDRESS/32
  }

  # HTTPS access from specific IP
  # TEMPORARY: Using 0.0.0.0/0 for cleanup - replace with YOUR_IP_ADDRESS/32 for deployment
  ingress {
    description = "HTTPS access from specific IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with YOUR_IP_ADDRESS/32
  }

  # Kubelet API access from specific IP
  # TEMPORARY: Using 0.0.0.0/0 for cleanup - replace with YOUR_IP_ADDRESS/32 for deployment
  ingress {
    description = "Kubelet API access from specific IP"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with YOUR_IP_ADDRESS/32
  }

  # NodePort services access from specific IP
  # TEMPORARY: Using 0.0.0.0/0 for cleanup - replace with YOUR_IP_ADDRESS/32 for deployment
  ingress {
    description = "NodePort services access from specific IP"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with YOUR_IP_ADDRESS/32
  }

  # Allow all traffic from cluster security group
  ingress {
    description     = "All traffic from EKS cluster"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Allow node to node communication
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-nodes-sg"
  })
}

# SSH Key Pair for node access
resource "tls_private_key" "eks_nodes" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks_nodes" {
  key_name   = "${var.project_name}-eks-nodes"
  public_key = tls_private_key.eks_nodes.public_key_openssh

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-nodes-keypair"
  })
}
