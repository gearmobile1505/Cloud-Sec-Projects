# CIS Benchmark Checker - Usage Guide

Comprehensive documentation for using the CIS Benchmark Checker to assess and monitor AWS security compliance.

> **🚀 FIRST TIME SETUP? Start with the [Complete Walkthrough](WALKTHROUGH.md) for end-to-end setup instructions!**

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Basic Usage](#basic-usage)
3. [Advanced Usage](#advanced-usage)
4. [Automation & Scheduling](#automation--scheduling)
5. [Integration Options](#integration-options)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

## Installation & Setup

### System Requirements
- **Python**: 3.7 or higher
- **AWS CLI**: v1.18+ or v2.0+
- **jq**: Latest version for JSON processing
- **Operating System**: Linux, macOS, or Windows (with WSL)

### AWS Permissions Required
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "iam:Get*",
                "iam:List*",
                "cloudtrail:Describe*",
                "cloudtrail:Get*",
                "config:Describe*",
                "config:Get*",
                "s3:Get*",
                "s3:List*",
                "kms:Describe*",
                "kms:Get*",
                "kms:List*",
                "logs:Describe*",
                "logs:Get*"
            ],
            "Resource": "*"
        }
    ]
}
```

### AWS Credentials Setup

#### Option 1: AWS CLI Configuration
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

#### Option 2: Environment Variables
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

#### Option 3: IAM Roles (for EC2 instances)
```bash
# No additional configuration needed if running on EC2 with proper IAM role
```

#### Option 4: AWS Profiles
```bash
# Configure multiple profiles
aws configure --profile production
aws configure --profile development

# Use specific profile
python3 cis_checker.py check --profile production
```

## Basic Usage

### Command Structure
```bash
cd scripts
python3 cis_checker.py [GLOBAL_OPTIONS] COMMAND [COMMAND_OPTIONS]
```

### List Available Controls
```bash
# See all implemented CIS controls
python3 cis_checker.py list

# See controls from extended checker
python3 extended_cis.py list
```

### Run Compliance Checks

#### Check All Implemented Controls
```bash
python3 cis_checker.py check
```

#### Check Specific Controls
```bash
# Check critical IAM controls
python3 cis_checker.py check --controls "1.12,1.13"

# Check network security controls
python3 cis_checker.py check --controls "5.1,5.2,5.3,5.5"

# Check logging controls
python3 cis_checker.py check --controls "3.1,3.2,3.3,3.4"
```

#### Output Formats
```bash
# JSON output (default)
python3 cis_checker.py check --format json

# Human-readable text
python3 cis_checker.py check --format text

# Save to file
python3 cis_checker.py check --output compliance_report.json
python3 cis_checker.py check --format text --output compliance_report.txt
```

### Using Different AWS Profiles and Regions
```bash
# Use specific AWS profile
python3 cis_checker.py --profile production check

# Check different region
python3 cis_checker.py --region us-west-2 check

# Combine profile and region
python3 cis_checker.py --profile production --region eu-west-1 check
```

## Advanced Usage

### Extended CIS Checker
```bash
# Run extended checks (password policies, KMS rotation, etc.)
python3 extended_cis.py check --controls "1.5,1.6,3.8,5.5"

# Combine base and extended controls
python3 extended_cis.py check --controls "1.12,1.5,3.1,3.8,5.2,5.5"
```

### Automation Script Usage

#### Basic Automation
```bash
# Make script executable
chmod +x run_cis_checks.sh

# Run basic compliance check
./run_cis_checks.sh

# Check specific controls
./run_cis_checks.sh --controls "1.12,1.13,3.1,5.2"
```

#### Advanced Automation Options
```bash
# Use specific AWS profile and region
./run_cis_checks.sh --profile production --region us-west-2

# Store reports in custom directory
./run_cis_checks.sh --output-dir /var/log/compliance

# Upload reports to S3
./run_cis_checks.sh --s3-bucket my-compliance-reports

# Send notifications via SNS
./run_cis_checks.sh --sns-topic arn:aws:sns:us-east-1:123456789:alerts

# Combine all options
./run_cis_checks.sh \
  --profile production \
  --region us-east-1 \
  --controls "1.12,1.13,3.1,5.2" \
  --s3-bucket compliance-reports \
  --sns-topic arn:aws:sns:us-east-1:123456789:security-alerts \
  --output-dir ./reports
```

#### Dry Run Mode
```bash
# Test configuration without running actual checks
./run_cis_checks.sh --dry-run

# Test with full configuration
./run_cis_checks.sh \
  --dry-run \
  --profile production \
  --s3-bucket test-bucket \
  --sns-topic arn:aws:sns:us-east-1:123456789:test
```

## Automation & Scheduling

### Cron Job Setup (Linux/macOS)
```bash
# Edit crontab
crontab -e

# Daily check at 2 AM
0 2 * * * /path/to/cis-benchmark-checker/run_cis_checks.sh --profile production --s3-bucket compliance-reports

# Weekly check on Sundays at 6 AM
0 6 * * 0 /path/to/cis-benchmark-checker/run_cis_checks.sh --profile production --controls "1.12,1.13,3.1,5.2"

# Monthly comprehensive check
0 3 1 * * /path/to/cis-benchmark-checker/run_cis_checks.sh --profile production --sns-topic arn:aws:sns:us-east-1:123456789:monthly-reports
```

### Systemd Timer (Linux)
```bash
# Create service file: /etc/systemd/system/cis-compliance.service
[Unit]
Description=CIS Compliance Check
After=network.target

[Service]
Type=oneshot
User=compliance
ExecStart=/opt/cis-benchmark-checker/run_cis_checks.sh --profile production --s3-bucket compliance-reports
WorkingDirectory=/opt/cis-benchmark-checker

# Create timer file: /etc/systemd/system/cis-compliance.timer
[Unit]
Description=Run CIS compliance check daily
Requires=cis-compliance.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

# Enable and start
sudo systemctl enable cis-compliance.timer
sudo systemctl start cis-compliance.timer
```

### AWS Lambda Deployment
```bash
# Package the function
zip -r cis-compliance-lambda.zip *.py requirements.txt

# Deploy with AWS CLI
aws lambda create-function \
  --function-name cis-compliance-checker \
  --runtime python3.9 \
  --role arn:aws:iam::123456789:role/lambda-execution-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://cis-compliance-lambda.zip \
  --timeout 300 \
  --memory-size 512 \
  --environment Variables='{
    "S3_BUCKET":"compliance-reports",
    "SNS_TOPIC":"arn:aws:sns:us-east-1:123456789:alerts",
    "CONTROL_IDS":"1.12,1.13,3.1,5.2"
  }'

# Schedule with CloudWatch Events
aws events put-rule \
  --name cis-compliance-daily \
  --schedule-expression "rate(1 day)"

aws events put-targets \
  --rule cis-compliance-daily \
  --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:123456789:function:cis-compliance-checker"
```

## Integration Options

### S3 Integration
```bash
# Create S3 bucket for reports
aws s3 mb s3://my-compliance-reports

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-compliance-reports \
  --versioning-configuration Status=Enabled

# Set lifecycle policy (optional)
cat > lifecycle.json << EOF
{
  "Rules": [{
    "ID": "compliance-reports-lifecycle",
    "Status": "Enabled",
    "Transitions": [{
      "Days": 30,
      "StorageClass": "STANDARD_IA"
    }, {
      "Days": 90,
      "StorageClass": "GLACIER"
    }]
  }]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket my-compliance-reports \
  --lifecycle-configuration file://lifecycle.json

# Use with automation script
./run_cis_checks.sh --s3-bucket my-compliance-reports
```

### SNS Integration
```bash
# Create SNS topic
aws sns create-topic --name cis-compliance-alerts

# Subscribe email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789:cis-compliance-alerts \
  --protocol email \
  --notification-endpoint security@company.com

# Subscribe Slack (via webhook)
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789:cis-compliance-alerts \
  --protocol https \
  --notification-endpoint https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK

# Use with automation script
./run_cis_checks.sh --sns-topic arn:aws:sns:us-east-1:123456789:cis-compliance-alerts
```

### Security Hub Integration
```bash
# Enable Security Hub (one-time setup)
aws securityhub enable-security-hub

# Enable CIS AWS Foundations standard
aws securityhub batch-enable-standards \
  --standards-subscription-requests StandardsArn=arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-standard/v/1.0.0

# Run with Security Hub integration
./run_cis_checks.sh --integration security-hub
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Permission Errors
```bash
# Check current permissions
aws sts get-caller-identity

# Test specific service permissions
aws iam list-users --max-items 1
aws ec2 describe-security-groups --max-items 1
aws cloudtrail describe-trails

# If using IAM role, verify role permissions
aws iam get-role --role-name your-role-name
aws iam list-attached-role-policies --role-name your-role-name
```

#### 2. Python/Dependency Issues
```bash
# Check Python version
python3 --version

# Reinstall requirements
pip uninstall boto3 botocore
pip install -r requirements.txt

# Check import issues
python3 -c "
import boto3
import json
import logging
print('All imports successful')
"
```

#### 3. AWS CLI Issues
```bash
# Check AWS CLI configuration
aws configure list

# Test connectivity
aws sts get-caller-identity

# Check region configuration
aws configure get region

# Test with specific profile
aws --profile production sts get-caller-identity
```

#### 4. Regional Issues
```bash
# Some services are global, others regional
# IAM: Global service
# CloudTrail: Check us-east-1 for global trails
# EC2/VPC: Regional services

# Check CloudTrail in us-east-1 regardless of your region
aws cloudtrail describe-trails --region us-east-1

# Check EC2 resources in specific region
aws ec2 describe-security-groups --region us-west-2
```

#### 5. JSON Processing Issues
```bash
# Install jq if missing
# macOS: brew install jq
# Ubuntu/Debian: apt-get install jq
# CentOS/RHEL: yum install jq

# Test jq installation
echo '{"test": "value"}' | jq .
```

### Debug Mode
```bash
# Enable verbose logging
python3 cis_checker.py check --verbose

# Set debug log level
export LOG_LEVEL=DEBUG
python3 cis_checker.py check

# Debug automation script
bash -x ./run_cis_checks.sh --dry-run
```

### Manual Verification
```bash
# Manually verify specific controls

# Control 1.12: Root access keys
aws iam get-account-summary | grep AccountAccessKeysPresent

# Control 3.1: CloudTrail
aws cloudtrail describe-trails --region us-east-1

# Control 5.2: Security groups
aws ec2 describe-security-groups \
  --filters "Name=ip-permission.cidr,Values=0.0.0.0/0" \
  --query 'SecurityGroups[?length(IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`] && (FromPort==`22` || FromPort==`3389`)]) > `0`]'
```

## Best Practices

### Security Best Practices
1. **Use IAM Roles**: Prefer IAM roles over access keys when possible
2. **Least Privilege**: Grant only necessary permissions for compliance checking
3. **Regular Rotation**: Rotate access keys regularly if using them
4. **Secure Storage**: Store reports securely in S3 with encryption
5. **Monitor Access**: Enable CloudTrail for compliance checking activities

### Operational Best Practices
1. **Regular Scheduling**: Run checks daily or weekly depending on environment
2. **Baseline Establishment**: Establish compliance baselines for comparison
3. **Exception Handling**: Document and track approved exceptions
4. **Remediation Tracking**: Track remediation efforts and timelines
5. **Continuous Monitoring**: Integrate with existing monitoring systems

### Performance Best Practices
1. **Regional Optimization**: Run checks in the same region as resources when possible
2. **Parallel Execution**: Use multiple instances for large multi-account environments
3. **Rate Limiting**: Respect AWS API rate limits
4. **Caching**: Cache results when appropriate for repeated checks
5. **Resource Filtering**: Filter checks to relevant resources only

### Reporting Best Practices
1. **Standardized Formats**: Use consistent report formats across environments
2. **Historical Tracking**: Maintain historical compliance data
3. **Executive Summaries**: Provide high-level summaries for management
4. **Actionable Results**: Include specific remediation steps
5. **Integration**: Integrate with existing security and compliance tools

### Example Compliance Workflow
```bash
# 1. Daily automated checks
./run_cis_checks.sh \
  --profile production \
  --controls "1.12,1.13,3.1,5.2" \
  --s3-bucket daily-compliance-reports \
  --sns-topic arn:aws:sns:us-east-1:123456789:daily-alerts

# 2. Weekly comprehensive checks
./run_cis_checks.sh \
  --profile production \
  --s3-bucket weekly-compliance-reports \
  --sns-topic arn:aws:sns:us-east-1:123456789:weekly-reports

# 3. Monthly audit reports
./run_cis_checks.sh \
  --profile production \
  --output-dir /audit/monthly \
  --s3-bucket audit-compliance-reports \
  --integration security-hub

# 4. Remediation verification
python3 cis_checker.py check \
  --controls "1.12" \
  --format text
```

## Test Infrastructure

A complete Terraform configuration is provided in the `tf/` directory to create AWS test resources for validating the CIS checker functionality.

### Quick Test Setup

```bash
# 1. Deploy test infrastructure
cd tf
./deploy.sh init
./deploy.sh apply

# 2. Test CIS compliance
./deploy.sh test

# 3. Clean up
./deploy.sh destroy
```

### What Gets Created

The test infrastructure includes:

**Compliant Resources:**
- VPC with Flow Logs enabled (CIS 5.5)
- CloudTrail with encryption and validation (CIS 3.1, 3.2, 3.7)
- Properly configured Security Groups
- IAM Password Policy (CIS 1.5-1.11)
- AWS Config enabled (CIS 3.5)

**Non-Compliant Resources (for testing):**
- Security Group allowing SSH from 0.0.0.0/0 (CIS 5.2 violation)
- Public S3 bucket (for S3 public access testing)
- Test IAM users with access keys (for key rotation testing)

### Expected Test Results

When running against the test infrastructure:
```bash
# Should show both compliant and non-compliant results
python3 cis_checker.py check --controls "1.12,3.1,5.2,5.5"

✓ CIS 3.1: CloudTrail enabled in all regions - COMPLIANT
✓ CIS 5.5: VPC flow logging enabled - COMPLIANT
✗ CIS 5.2: Security groups allow ingress from 0.0.0.0/0 - NON_COMPLIANT
```

See [tf/README.md](tf/README.md) for complete documentation.

This comprehensive usage guide ensures that users can effectively implement and operate the CIS Benchmark Checker in their AWS environments.
