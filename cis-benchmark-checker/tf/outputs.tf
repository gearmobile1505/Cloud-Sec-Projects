# Outputs for CIS Benchmark Test Infrastructure

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# Security Group Information
output "compliant_ssh_security_group_id" {
  description = "ID of the compliant SSH security group"
  value       = aws_security_group.compliant_ssh.id
}

output "non_compliant_ssh_security_group_id" {
  description = "ID of the non-compliant SSH security group (if created)"
  value       = var.create_non_compliant_resources ? aws_security_group.non_compliant_ssh[0].id : null
}

output "web_server_security_group_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web_server.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# CloudTrail Information (Disabled for cleanup)
# output "cloudtrail_arn" {
#   description = "ARN of the CloudTrail"
#   value       = aws_cloudtrail.main.arn
# }

# output "cloudtrail_bucket_name" {
#   description = "Name of the CloudTrail S3 bucket"
#   value       = aws_s3_bucket.cloudtrail.bucket
# }

# output "cloudtrail_kms_key_id" {
#   description = "ID of the CloudTrail KMS key"
#   value       = aws_kms_key.cloudtrail.key_id
# }

# output "cloudtrail_kms_key_arn" {
#   description = "ARN of the CloudTrail KMS key"
#   value       = aws_kms_key.cloudtrail.arn
# }

# IAM Information
output "test_user_name" {
  description = "Name of the test IAM user"
  value       = aws_iam_user.test_user.name
}

output "test_user_access_key_id" {
  description = "Access key ID for the test user"
  value       = aws_iam_access_key.test_user.id
  sensitive   = true
}

output "old_key_user_name" {
  description = "Name of the old key test user (if created)"
  value       = var.create_non_compliant_resources ? aws_iam_user.old_key_user[0].name : null
}

output "test_role_arn" {
  description = "ARN of the test IAM role"
  value       = aws_iam_role.test_role.arn
}

# Config Information (Disabled for cleanup)
# output "config_bucket_name" {
#   description = "Name of the AWS Config S3 bucket"
#   value       = var.enable_config ? aws_s3_bucket.config[0].bucket : null
# }

# output "config_recorder_name" {
#   description = "Name of the AWS Config configuration recorder"
#   value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
# }

# VPC Flow Logs
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_flow_logs ? aws_flow_log.vpc_flow_log[0].id : null
}

# Account and Region Information
output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

# CIS Compliance Testing Information (Disabled for cleanup)
# Note: CloudTrail and Config resources have been disabled for safe cleanup
# Uncomment and update resource references when re-enabling these services
# output "cis_compliance_test_summary" {
#   description = "Summary of resources for CIS compliance testing"
#   value = {
#     vpc_id                              = aws_vpc.main.id
#     vpc_flow_logs_enabled              = var.enable_flow_logs
#     cloudtrail_enabled                 = false  # Disabled for cleanup
#     config_enabled                     = var.enable_config
#     compliant_security_groups_created  = true
#     non_compliant_resources_created    = var.create_non_compliant_resources
#     iam_password_policy_configured     = true
#   }
# }

# Test Commands
output "test_commands" {
  description = "Commands to test CIS compliance"
  value = {
    list_controls       = "python3 cis_checker.py list"
    check_all           = "python3 cis_checker.py check"
    check_critical      = "python3 cis_checker.py check --controls '1.12,3.1,5.2'"
    check_with_profile  = "python3 cis_checker.py check --profile ${var.environment}"
    automation_script   = "./run_cis_checks.sh --controls '1.12,3.1,5.2,5.5'"
    dry_run            = "./run_cis_checks.sh --dry-run"
  }
}

# EKS Cluster Information
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].security_group_ids
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "eks_node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.main.arn
}
