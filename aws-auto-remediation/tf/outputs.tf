# Outputs for security group remediation testing

output "vpc_id" {
  description = "ID of the test VPC"
  value       = aws_vpc.test_vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the test VPC"
  value       = aws_vpc.test_vpc.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.test_public_subnet.id
}

output "high_risk_sg_id" {
  description = "ID of the high-risk security group"
  value       = aws_security_group.high_risk_sg.id
}

output "medium_risk_sg_id" {
  description = "ID of the medium-risk security group"
  value       = aws_security_group.medium_risk_sg.id
}

output "low_risk_sg_id" {
  description = "ID of the low-risk security group"
  value       = aws_security_group.low_risk_sg.id
}

output "extreme_risk_sg_id" {
  description = "ID of the extreme-risk security group"
  value       = aws_security_group.extreme_risk_sg.id
}

output "secure_sg_id" {
  description = "ID of the secure security group"
  value       = aws_security_group.secure_sg.id
}

output "security_group_summary" {
  description = "Summary of all created security groups"
  value = {
    high_risk = {
      id          = aws_security_group.high_risk_sg.id
      name        = aws_security_group.high_risk_sg.name
      description = aws_security_group.high_risk_sg.description
      risk_level  = "HIGH"
    }
    medium_risk = {
      id          = aws_security_group.medium_risk_sg.id
      name        = aws_security_group.medium_risk_sg.name
      description = aws_security_group.medium_risk_sg.description
      risk_level  = "MEDIUM"
    }
    low_risk = {
      id          = aws_security_group.low_risk_sg.id
      name        = aws_security_group.low_risk_sg.name
      description = aws_security_group.low_risk_sg.description
      risk_level  = "LOW"
    }
    extreme_risk = {
      id          = aws_security_group.extreme_risk_sg.id
      name        = aws_security_group.extreme_risk_sg.name
      description = aws_security_group.extreme_risk_sg.description
      risk_level  = "EXTREME"
    }
    secure = {
      id          = aws_security_group.secure_sg.id
      name        = aws_security_group.secure_sg.name
      description = aws_security_group.secure_sg.description
      risk_level  = "SECURE"
    }
  }
}

# VPC Remediation Testing Outputs
output "private_subnet_id" {
  description = "ID of the private subnet for testing"
  value       = aws_subnet.test_private_subnet.id
}

output "permissive_nacl_id" {
  description = "ID of the permissive Network ACL for testing lockdown"
  value       = aws_network_acl.test_permissive_nacl.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.test_public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.test_private_rt.id
}

output "risky_route_table_id" {
  description = "ID of the risky route table for testing"
  value       = aws_route_table.test_risky_rt.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.test_igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.test_nat.id
}

output "nat_eip_id" {
  description = "ID of the NAT Gateway Elastic IP"
  value       = aws_eip.test_nat_eip.id
}

output "vpc_flow_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_log.name
}

output "emergency_testing_summary" {
  description = "Summary of resources for emergency remediation testing"
  value = {
    vpc_id                = aws_vpc.test_vpc.id
    internet_gateway      = aws_internet_gateway.test_igw.id
    permissive_nacl       = aws_network_acl.test_permissive_nacl.id
    risky_route_table     = aws_route_table.test_risky_rt.id
    nat_gateway          = aws_nat_gateway.test_nat.id
    public_subnet        = aws_subnet.test_public_subnet.id
    private_subnet       = aws_subnet.test_private_subnet.id
    flow_logs           = aws_cloudwatch_log_group.vpc_flow_log.name
    high_risk_sg        = aws_security_group.high_risk_sg.id
    extreme_risk_sg     = aws_security_group.extreme_risk_sg.id
  }
}

output "test_commands" {
  description = "Commands to test the security remediation tools"
  value = {
    find_all_open = "python3 ../automation/security_group_remediation.py find --output test_results.json"
    find_ssh_rdp  = "python3 ../automation/security_group_remediation.py find --ports \"22,3389\""
    generate_report = "python3 ../automation/security_group_remediation.py report --output security_report.json"
    dry_run_high_risk = "python3 ../automation/security_group_remediation.py remediate ${aws_security_group.high_risk_sg.id} --dry-run"
    dry_run_medium_risk = "python3 ../automation/security_group_remediation.py remediate ${aws_security_group.medium_risk_sg.id} --dry-run"
    bulk_dry_run = "python3 ../automation/security_group_remediation.py bulk-remediate --dry-run"
  }
}
