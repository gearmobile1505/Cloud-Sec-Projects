# Terraform Testing Infrastructure for VPC Remediation

This Terraform configuration creates comprehensive AWS infrastructure designed for testing both security group remediation AND VPC emergency response capabilities.

## Overview

The configuration creates two testing scenarios:

### 1. Security Group Remediation Testing
- **Security groups with various risk levels** to test detection and remediation
- **Comprehensive port coverage** for all risky services

### 2. VPC Emergency Remediation Testing
- **Permissive Network ACLs** for testing lockdown procedures
- **Multiple route tables** for testing internet access control
- **NAT Gateway and Internet Gateway** for testing connectivity isolation
- **VPC Flow Logs** for monitoring and auditing
- **Multiple subnets** for testing subnet-level isolation

## Resources Created

### Security Groups (for security_group_remediation.py testing)
- **high-risk-sg**: SSH (22) and RDP (3389) open to 0.0.0.0/0
- **medium-risk-sg**: Database ports (3306, 5432, 6379, 27017, 1433, 9200, 5601) open to 0.0.0.0/0
- **extreme-risk-sg**: All protocols open to 0.0.0.0/0
- **low-risk-sg**: Web traffic (80/443) open, SSH restricted to private networks
- **secure-sg**: Properly configured baseline

### VPC Infrastructure (for emergency_remediation.sh testing)
- **VPC**: Test environment (10.0.0.0/16)
- **Public Subnet**: Internet-accessible subnet (10.0.1.0/24)
- **Private Subnet**: Internal subnet (10.0.2.0/24)
- **Internet Gateway**: For public internet access
- **NAT Gateway**: For private subnet internet access
- **Permissive Network ACL**: Allows all traffic (RISKY - for testing lockdown)
- **Multiple Route Tables**: 
  - Public route table (internet access)
  - Private route table (NAT gateway access)
  - Risky route table (direct internet access)
- **VPC Flow Logs**: For monitoring network traffic

## Quick Start

### 1. Configure Variables
```bash
cd tf/
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings:
# allowed_ssh_cidr = "YOUR.IP.ADDRESS/32"
# aws_region = "us-east-1"
```

### 2. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 3. Test Security Group Remediation
```bash
cd ../automation

# Test detection
python3 security_group_remediation.py find

# Test reporting
python3 security_group_remediation.py report --output test_report.json

# Test remediation (dry run)
HIGH_RISK_SG=$(terraform output -raw high_risk_sg_id)
python3 security_group_remediation.py remediate $HIGH_RISK_SG --dry-run

# Test bulk remediation
python3 security_group_remediation.py bulk-remediate --dry-run
```

### 4. Test VPC Emergency Remediation
```bash
cd ../scripts

# Get VPC ID for testing
VPC_ID=$(terraform output -raw vpc_id)

# Test emergency lockdown (dry run)
./emergency_remediation.sh --vpc-id $VPC_ID --dry-run

# Test actual lockdown (be careful!)
./emergency_remediation.sh --vpc-id $VPC_ID --confirm
```

## Comprehensive Testing Scenarios

### Security Group Testing
```bash
# Should detect 3 risky security groups
python3 security_group_remediation.py find
# Expected: high-risk, medium-risk, extreme-risk

# Test risk categorization
python3 security_group_remediation.py report --format human
# Expected: 1 HIGH, 1 MEDIUM, 1 EXTREME, 2 SECURE

# Test individual remediation
SG_ID=$(terraform output -raw extreme_risk_sg_id)
python3 security_group_remediation.py remediate $SG_ID --dry-run
# Expected: Show removal of 0.0.0.0/0 rules, addition of private network rules
```

### VPC Emergency Response Testing
```bash
# Test assessment phase
./emergency_remediation.sh --vpc-id $(terraform output -raw vpc_id) --dry-run
# Expected: Detect permissive NACLs, risky routes, internet gateways

# Test specific component lockdown
VPC_ID=$(terraform output -raw vpc_id)
NACL_ID=$(terraform output -raw permissive_nacl_id)
RT_ID=$(terraform output -raw risky_route_table_id)

# Check current NACL rules
aws ec2 describe-network-acls --network-acl-ids $NACL_ID

# Check current routes
aws ec2 describe-route-tables --route-table-ids $RT_ID

# Test lockdown (will modify these resources)
./emergency_remediation.sh --vpc-id $VPC_ID --confirm
```

### Flow Logs Monitoring
```bash
# Check VPC Flow Logs are working
LOG_GROUP=$(terraform output -raw vpc_flow_log_group)
aws logs describe-log-streams --log-group-name $LOG_GROUP

# Generate some traffic for testing
# (if EC2 instances are deployed)
```

## Testing Workflow

### Phase 1: Initial Assessment
1. Deploy infrastructure: `terraform apply`
2. Run security assessment: `python3 security_group_remediation.py find`
3. Generate baseline report: `python3 security_group_remediation.py report`
4. Run VPC assessment: `./emergency_remediation.sh --vpc-id $(terraform output -raw vpc_id) --dry-run`

### Phase 2: Remediation Testing
1. Test security group remediation: `python3 security_group_remediation.py bulk-remediate --dry-run`
2. Apply security group fixes: `python3 security_group_remediation.py bulk-remediate`
3. Test VPC lockdown: `./emergency_remediation.sh --vpc-id $(terraform output -raw vpc_id) --confirm`

### Phase 3: Verification
1. Verify security groups are fixed: `python3 security_group_remediation.py find`
2. Check NACL modifications: `aws ec2 describe-network-acls --network-acl-ids $(terraform output -raw permissive_nacl_id)`
3. Check route table modifications: `aws ec2 describe-route-tables --route-table-ids $(terraform output -raw risky_route_table_id)`
4. Review flow logs: `aws logs filter-log-events --log-group-name $(terraform output -raw vpc_flow_log_group)`

### Phase 4: Restoration Testing
1. Use the generated restoration guide from emergency script
2. Restore original configurations
3. Verify full functionality

## Expected Results

### Security Group Detection
- **3 security groups flagged** for remediation
- **2 security groups marked as secure**
- **Detailed risk assessment** with port-specific analysis

### VPC Emergency Response
- **Permissive NACL detected** and lockdown rules applied
- **Risky route tables identified** and modified
- **Internet access controlled** through gateway management
- **Comprehensive restoration guide** generated

### Monitoring
- **VPC Flow Logs capturing** all network traffic
- **CloudWatch logs available** for analysis
- **Audit trail maintained** for all operations

## Cost Considerations

### Free Tier Resources
- VPC, subnets, security groups, route tables: **Free**
- Internet Gateway: **Free**
- VPC Flow Logs: **Free** (within limits)

### Billable Resources
- **NAT Gateway**: ~$0.045/hour + data processing charges
- **CloudWatch Logs**: $0.50/GB ingested (minimal for testing)
- **Elastic IP**: **Free** while attached to NAT Gateway

### Cost Optimization
- **Total cost**: ~$1-2/day for testing
- **Cleanup**: Run `terraform destroy` when done
- **EC2 instances**: Commented out to avoid charges

## Security Warnings

⚠️ **CRITICAL**: This infrastructure creates intentionally vulnerable configurations

- **ONLY USE IN ISOLATED TEST ENVIRONMENTS**
- **NEVER deploy in production or shared environments**
- **Clean up resources after testing**
- **Monitor AWS costs during testing**
- **The permissive NACL allows dangerous access patterns**

## Troubleshooting

### Common Issues
1. **Permission errors**: Ensure AWS credentials have EC2, VPC, and CloudWatch permissions
2. **Resource limits**: Check AWS service quotas for your region
3. **IP configuration**: Update `allowed_ssh_cidr` with your actual IP
4. **Region availability**: Some resources may not be available in all regions

### Cleanup
```bash
# Full cleanup
terraform destroy

# Verify cleanup
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=testing"
```

This comprehensive testing infrastructure allows you to validate both security group remediation and VPC emergency response capabilities in a safe, controlled environment.
