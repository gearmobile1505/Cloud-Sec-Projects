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

output "test_commands" {
  description = "Commands to test the security remediation tools"
  value = {
    find_all_open = "python3 ../security_group_remediation.py find --output test_results.json"
    find_ssh_rdp  = "python3 ../security_group_remediation.py find --ports \"22,3389\""
    generate_report = "python3 ../security_group_remediation.py report --output security_report.json"
    dry_run_high_risk = "python3 ../security_group_remediation.py remediate ${aws_security_group.high_risk_sg.id} --dry-run"
    dry_run_medium_risk = "python3 ../security_group_remediation.py remediate ${aws_security_group.medium_risk_sg.id} --dry-run"
    bulk_dry_run = "python3 ../security_group_remediation.py bulk-remediate --dry-run"
  }
}
