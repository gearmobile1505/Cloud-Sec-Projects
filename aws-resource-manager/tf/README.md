# Security Group Testing Infrastructure

This Terraform configuration creates AWS resources specifically designed to test our security group remediation tools. It creates security groups with various risk levels to validate our security scripts.

## What This Creates

### Security Groups by Risk Level:

1. **🔴 EXTREME RISK Security Group**
   - All protocols open to 0.0.0.0/0
   - For testing extreme vulnerability detection

2. **🟠 HIGH RISK Security Group**
   - SSH (22) open to 0.0.0.0/0
   - RDP (3389) open to 0.0.0.0/0
   - For testing management port vulnerabilities

3. **🟡 MEDIUM RISK Security Group**
   - MySQL (3306) open to 0.0.0.0/0
   - PostgreSQL (5432) open to 0.0.0.0/0
   - Redis (6379) open to 0.0.0.0/0
   - MongoDB (27017) open to 0.0.0.0/0
   - For testing database exposure

4. **🟢 LOW RISK Security Group**
   - HTTP (80) and HTTPS (443) open to 0.0.0.0/0 (acceptable)
   - SSH (22) restricted to private networks only
   - For testing properly restricted services

5. **✅ SECURE Security Group**
   - HTTP (80) and HTTPS (443) open to 0.0.0.0/0 (acceptable)
   - SSH (22) restricted to your specific IP only
   - Baseline for comparison

### Supporting Infrastructure:
- VPC with public subnet
- Internet Gateway and routing
- (Optional) Test EC2 instances

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (>= 1.0)
3. **Appropriate AWS permissions**:
   - EC2 full access (for security groups and VPC)
   - IAM permissions for Terraform state

## Quick Start

### 1. Setup Configuration

```bash
cd tf
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars

**IMPORTANT**: Update `allowed_ssh_cidr` with your real IP:

```bash
# Get your public IP
curl ifconfig.me

# Edit terraform.tfvars
nano terraform.tfvars
```

Example terraform.tfvars:
```hcl
aws_region = "us-east-1"
project_name = "sec-test"
environment = "testing"
allowed_ssh_cidr = "203.0.113.100/32"  # Replace with YOUR IP
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Test Your Security Tools

After deployment, test with the security remediation tools:

```bash
# Go back to the main directory
cd ..

# Find all open security groups
python3 security_group_remediation.py find

# Generate detailed report
python3 security_group_remediation.py report --output tf_test_report.json

# Test dry-run remediation on specific groups
terraform -chdir=tf output -raw high_risk_sg_id | xargs -I {} python3 security_group_remediation.py remediate {} --dry-run

# Test bulk remediation (dry-run)
python3 security_group_remediation.py bulk-remediate --dry-run
```

## Expected Test Results

When you run the security tools, you should see:

### Find Command Results:
- **4 security groups** with open rules (extreme, high, medium, + any existing ones)
- **Various ports** flagged: 22, 3389, 3306, 5432, 6379, 27017, and protocol -1

### Report Command Results:
- **EXTREME**: 1 security group (all protocols open)
- **HIGH**: 1+ security groups (SSH/RDP open)
- **MEDIUM**: 1 security group (database ports open)
- **LOW/SECURE**: Should not appear in vulnerability reports

### Remediation Results:
- **Dry-run should show** exactly what rules would be changed
- **Actual remediation** should close internet access and replace with restricted CIDRs

## Testing Scenarios

### 1. Basic Detection Test
```bash
python3 security_group_remediation.py find --ports "22,3389"
```
Expected: Should find HIGH and EXTREME risk groups

### 2. Database Security Test
```bash
python3 security_group_remediation.py find --ports "3306,5432,6379,27017"
```
Expected: Should find MEDIUM and EXTREME risk groups

### 3. Complete Security Audit
```bash
python3 security_group_remediation.py report --output complete_audit.json
```
Expected: Detailed JSON report with risk classifications

### 4. Remediation Testing
```bash
# Get the extreme risk security group ID
EXTREME_SG=$(terraform output -raw extreme_risk_sg_id)

# Test remediation
python3 security_group_remediation.py remediate $EXTREME_SG --dry-run
```

## Cleanup

⚠️ **Important**: Clean up resources to avoid charges:

```bash
cd tf
terraform destroy
```

## Cost Considerations

- **Security Groups**: Free
- **VPC/Subnets/IGW**: Free
- **EC2 Instances**: Commented out by default (would incur charges)

## Customization

### Enable EC2 Instances for Testing
Uncomment the EC2 instance resources in `main.tf` and add your SSH public key:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/sec_test_key

# Add public key to terraform.tfvars
echo "public_key_content = \"$(cat ~/.ssh/sec_test_key.pub)\"" >> terraform.tfvars
```

### Test Different Regions
Change `aws_region` in terraform.tfvars:

```hcl
aws_region = "us-west-2"  # or any preferred region
```

### Modify Risk Scenarios
Edit `main.tf` to add/remove ports or create custom security group configurations.

## Troubleshooting

### Common Issues:

1. **"No declaration found for var.xxx"**
   - Ensure `variables.tf` exists
   - Run `terraform init`

2. **"Invalid CIDR block"**
   - Check your `allowed_ssh_cidr` format (should be IP/32 for single IP)

3. **"Unauthorized operation"**
   - Verify AWS credentials: `aws sts get-caller-identity`
   - Check IAM permissions for EC2 operations

4. **"Resource already exists"**
   - Use unique `project_name` in terraform.tfvars
   - Or run `terraform destroy` first

### Validation Commands:

```bash
# Validate Terraform configuration
terraform validate

# Check AWS connectivity
aws ec2 describe-security-groups --region us-east-1

# Test Python tools
python3 -c "import boto3; print('AWS SDK working')"
```

## Integration with CI/CD

This infrastructure can be used in automated testing pipelines:

```yaml
# Example GitHub Actions
- name: Deploy Test Infrastructure
  run: |
    cd tf
    terraform init
    terraform apply -auto-approve

- name: Run Security Tests
  run: |
    python3 security_group_remediation.py find --output test_results.json
    # Add assertions based on expected results

- name: Cleanup
  run: |
    cd tf
    terraform destroy -auto-approve
```
