# IAM Configuration for CIS Testing

# Test IAM User with access keys (for CIS 1.3, 1.4 testing)
resource "aws_iam_user" "test_user" {
  name = "${var.project_name}-test-user"
  path = "/"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-test-user"
    Note = "Test user for CIS 1.3 and 1.4 compliance testing"
  })
}

# Access key for test user (CIS 1.3, 1.4)
resource "aws_iam_access_key" "test_user" {
  user = aws_iam_user.test_user.name
}

# IAM User with old access key (simulate CIS 1.3, 1.4 violations)
resource "aws_iam_user" "old_key_user" {
  count = var.create_non_compliant_resources ? 1 : 0
  
  name = "${var.project_name}-old-key-user"
  path = "/"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-old-key-user"
    Note = "User with potentially old access key for CIS testing"
  })
}

resource "aws_iam_access_key" "old_key_user" {
  count = var.create_non_compliant_resources ? 1 : 0
  
  user = aws_iam_user.old_key_user[0].name
}

# IAM Password Policy (CIS 1.5-1.11)
resource "aws_iam_account_password_policy" "compliant" {
  minimum_password_length        = 14                # CIS 1.5
  require_lowercase_characters   = true              # CIS 1.7
  require_numbers               = true               # CIS 1.8
  require_uppercase_characters   = true              # CIS 1.6
  require_symbols               = true               # CIS 1.9
  allow_users_to_change_password = true              # CIS 1.10
  max_password_age              = 90                 # CIS 1.11
  password_reuse_prevention     = 24                 # CIS 1.5 (prevent reuse)
}

# IAM Role for testing
resource "aws_iam_role" "test_role" {
  name = "${var.project_name}-test-role"

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

  tags = local.common_tags
}

# IAM Policy for test role (removed S3 permissions)
resource "aws_iam_role_policy" "test_role" {
  name = "${var.project_name}-test-policy"
  role = aws_iam_role.test_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Instance profile for test role
resource "aws_iam_instance_profile" "test_role" {
  name = "${var.project_name}-test-profile"
  role = aws_iam_role.test_role.name

  tags = local.common_tags
}
