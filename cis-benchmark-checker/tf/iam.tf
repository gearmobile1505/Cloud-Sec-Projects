# IAM Configuration for CIS Testing

# Test IAM User with access keys (for CIS 1.3, 1.4 testing)
resource "aws_iam_user" "test_user" {
  name = "${var.project_name}-test-user"
  path = "/"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-test-user"
    Note = "Test user for CIS 1.3, 1.4 compliance testing"
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

# IAM Policy for test role
resource "aws_iam_role_policy" "test_role" {
  name = "${var.project_name}-test-policy"
  role = aws_iam_role.test_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.test_bucket.arn,
          "${aws_s3_bucket.test_bucket.arn}/*"
        ]
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

# Test S3 bucket
resource "aws_s3_bucket" "test_bucket" {
  bucket        = "${var.project_name}-test-bucket-${local.account_id}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-test-bucket"
    Note = "Test bucket for IAM policy testing"
  })
}

# S3 bucket public access block (compliant)
resource "aws_s3_bucket_public_access_block" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Non-compliant S3 bucket (public read)
resource "aws_s3_bucket" "public_bucket" {
  count = var.create_non_compliant_resources ? 1 : 0
  
  bucket        = "${var.project_name}-public-bucket-${local.account_id}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-bucket"
    Note = "VIOLATION - Public bucket for testing"
  })
}

# Make bucket public (CIS violation)
resource "aws_s3_bucket_public_access_block" "public_bucket" {
  count = var.create_non_compliant_resources ? 1 : 0
  
  bucket = aws_s3_bucket.public_bucket[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_bucket" {
  count = var.create_non_compliant_resources ? 1 : 0
  
  bucket = aws_s3_bucket.public_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public_bucket[0].arn}/*"
      }
    ]
  })
}
