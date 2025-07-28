# CIS Benchmark Test Infrastructure

This Terraform configuration creates AWS resources specifically designed to test the CIS Benchmark Checker tool. It includes both compliant and intentionally non-compliant resources to validate the checker's detection capabilities.

## 🎯 Purpose

This infrastructure provides:
- **Compliant resources** to verify the tool correctly identifies good configurations
- **Non-compliant resources** to verify the tool correctly identifies violations
- **Complete test environment** covering multiple CIS benchmark categories

## 🏗️ Resources Created

### VPC and Networking (CIS 5.x)
- ✅ **VPC** with public and private subnets
- ✅ **VPC Flow Logs** enabled (CIS 5.5)
- ✅ **Default Security Group** with no rules (CIS 5.3)
- ✅ **Compliant Security Groups** with restricted access
- ❌ **Non-compliant Security Group** with SSH/RDP from 0.0.0.0/0 (CIS 5.2 violation)

### CloudTrail and Logging (CIS 3.x)
- ✅ **CloudTrail** enabled in all regions (CIS 3.1)
- ✅ **Log file validation** enabled (CIS 3.2)
- ✅ **S3 bucket** not publicly accessible (CIS 3.3)
- ✅ **CloudWatch integration** enabled (CIS 3.4)
- ✅ **KMS encryption** with key rotation (CIS 3.7, 3.8)

### AWS Config (CIS 3.5)
- ✅ **AWS Config** enabled with configuration recorder
- ✅ **Config Rules** for CIS compliance checks
- ✅ **S3 delivery channel** for configuration history

### IAM (CIS 1.x)
- ✅ **Password policy** compliant with CIS requirements (1.5-1.11)
- ✅ **Test IAM users** with access keys for testing
- ❌ **Potentially old access keys** for testing key rotation checks

### S3 Buckets
- ✅ **Private S3 buckets** with proper access controls
- ❌ **Public S3 bucket** for testing public access detection

## 🚀 Quick Start

### 1. Prerequisites
```bash
# Install Terraform
brew install terraform  # macOS
# or download from https://terraform.io

# Verify installation
terraform version

# Configure AWS credentials
aws configure
```

### 2. Deploy Infrastructure
```bash
# Navigate to terraform directory
cd tf

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Test CIS Compliance
```bash
# Go back to the scripts directory
cd ../scripts

# Test the checker against your new infrastructure
python3 cis_checker.py check --controls "1.12,3.1,5.2,5.5"

# Run comprehensive check
./run_cis_checks.sh --controls "1.12,3.1,3.2,3.4,3.7,5.2,5.3,5.5"

# Check for specific violations
python3 cis_checker.py check --format json --output ../reports/tf-test-results.json
```

## 📊 Expected Results

When you run the CIS checker against this infrastructure, you should see:

### ✅ Compliant Controls
- **CIS 3.1** - CloudTrail enabled in all regions
- **CIS 3.2** - CloudTrail log file validation enabled
- **CIS 3.4** - CloudTrail integrated with CloudWatch Logs
- **CIS 3.7** - CloudTrail logs encrypted with KMS
- **CIS 3.8** - KMS key rotation enabled
- **CIS 5.3** - Default security group restricts all traffic
- **CIS 5.5** - VPC flow logging enabled

### ❌ Non-Compliant Controls (if enabled)
- **CIS 5.2** - Security groups allow ingress from 0.0.0.0/0 to admin ports
- **CIS 1.3/1.4** - Access keys potentially unused/old (time-dependent)

## 🔧 Configuration Options

### terraform.tfvars
```hcl
# Basic settings
aws_region   = "us-east-1"
environment  = "test"
project_name = "cis-benchmark-test"

# Feature flags
create_non_compliant_resources = true  # Create violation resources
enable_flow_logs              = true   # Enable VPC Flow Logs
enable_config                 = true   # Enable AWS Config

# Unique bucket name (optional)
cloudtrail_bucket_name = "your-unique-bucket-name"
```

### Key Variables

- **`create_non_compliant_resources`** - Set to `true` to create intentionally non-compliant resources for testing violations
- **`enable_flow_logs`** - Enable VPC Flow Logs (CIS 5.5)
- **`enable_config`** - Enable AWS Config service (CIS 3.5)
- **`cloudtrail_bucket_name`** - Custom bucket name (auto-generated if not specified)

## 💰 Cost Considerations

This test infrastructure will incur AWS charges:

- **VPC & Networking**: Minimal cost
- **CloudTrail**: ~$2/month for management events
- **VPC Flow Logs**: ~$0.50/GB of log data
- **AWS Config**: ~$2/month + $0.003/configuration item
- **S3 Storage**: Minimal for logs
- **KMS**: $1/month per key

**Estimated monthly cost: $5-15** depending on usage.

## 🧹 Cleanup

To avoid ongoing charges, destroy the infrastructure when testing is complete:

```bash
cd tf
terraform destroy
```

**Warning**: This will permanently delete all created resources and data.

## 🔍 Testing Scenarios

### Scenario 1: Basic Compliance Check
```bash
# Test core CIS controls
cd ../scripts
python3 cis_checker.py check --controls "1.12,3.1,5.2"
```

### Scenario 2: Full Infrastructure Scan
```bash
# Comprehensive check of all implemented controls
./run_cis_checks.sh
```

### Scenario 3: Violation Detection
```bash
# Ensure non-compliant resources are detected
python3 cis_checker.py check --controls "5.2" --format json | jq '.results[] | select(.status == "NON_COMPLIANT")'
```

### Scenario 4: Automation Testing
```bash
# Test automation script with S3 upload (requires S3 bucket)
./run_cis_checks.sh --s3-bucket your-reports-bucket --dry-run
```

## 📝 Validation Checklist

After deployment, verify:
- [ ] CloudTrail is logging to S3 and CloudWatch
- [ ] VPC Flow Logs are being generated
- [ ] Security groups contain the expected rules
- [ ] AWS Config is recording configuration changes
- [ ] KMS key rotation is enabled
- [ ] S3 buckets have correct public access settings

## 🐛 Troubleshooting

### Common Issues

1. **Bucket name conflicts**
   ```bash
   # Use a unique bucket name in terraform.tfvars
   cloudtrail_bucket_name = "your-unique-name-${random_id}"
   ```

2. **AWS Config permissions**
   ```bash
   # Ensure your AWS user has Config permissions
   aws iam list-attached-user-policies --user-name your-username
   ```

3. **Region-specific resources**
   ```bash
   # Some resources are region-specific
   terraform plan -var="aws_region=us-west-2"
   ```

## 🔗 Integration with CIS Checker

This infrastructure is designed to work seamlessly with the CIS Benchmark Checker:

```bash
# Test against the infrastructure
cd ../scripts
python3 cis_checker.py check --region us-east-1

# Use automation script
./run_cis_checks.sh --region us-east-1 --output-dir ../reports
```

## 📚 Additional Resources

- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Config Rules](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)
- [CloudTrail Best Practices](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/best-practices-security.html)
