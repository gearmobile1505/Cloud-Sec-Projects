# 🚀 Deployment Guide - AWS Control Tower with Terraform

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- [ ] **AWS CLI** configured with management account credentials
- [ ] **Terraform** >= 1.0 installed
- [ ] **Administrative permissions** in the AWS management account
- [ ] **Clean AWS account** (no existing Control Tower or Organizations)
- [ ] **Unique email addresses** for core accounts (3 required)
- [ ] **Decision on primary region** (us-east-1, us-west-2, eu-west-1, etc.)

## ⚠️ Important Notes

### Cost Implications:
- **Control Tower**: ~$3-5/month per managed account
- **Config Rules**: ~$2/rule/region/month  
- **CloudTrail**: ~$2/100K events
- **GuardDuty**: ~$3-4/month per account
- **Estimated monthly cost**: $50-100 for 5 accounts

### Time Requirements:
- **Phase 1**: Organizations (5-10 minutes)
- **Phase 2**: Control Tower (60-90 minutes) 
- **Phase 3**: SCPs (10-15 minutes)
- **Phase 4**: AFT (30-45 minutes)
- **Total**: 2-3 hours

## 🗂️ Phase-by-Phase Deployment

### Phase 1: AWS Organizations (5-10 minutes)

```bash
# 1. Navigate to organizations setup
cd 01-organizations

# 2. Copy and customize variables
cp ../terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Initialize and deploy
terraform init
terraform plan
terraform apply
```

**What this creates:**
- AWS Organizations with all features enabled
- Core and Workloads organizational units
- Production, Non-Production, and Sandbox sub-OUs
- Service access principals for Control Tower

### Phase 2: Control Tower & Landing Zone (60-90 minutes)

```bash
# 1. Navigate to control tower setup
cd ../02-control-tower

# 2. Copy variables (reuse from Phase 1)
cp ../terraform.tfvars.example terraform.tfvars
# Edit with your email addresses

# 3. Initialize and deploy
terraform init
terraform plan
terraform apply
```

**What this creates:**
- Control Tower Landing Zone
- Log Archive account with centralized logging
- Audit account for security and compliance
- Baseline security controls and Config rules
- CloudTrail organization trail
- KMS keys for encryption

**⏰ This is the longest phase - Control Tower setup takes 60-90 minutes!**

### Phase 3: Service Control Policies (10-15 minutes)

```bash
# 1. Navigate to SCPs setup
cd ../03-scps

# 2. Copy variables
cp ../terraform.tfvars.example terraform.tfvars
# Edit allowed_regions if needed

# 3. Initialize and deploy
terraform init
terraform plan
terraform apply
```

**What this creates:**
- Root account usage prevention policy
- Regional restriction policies
- Security service protection policies
- Production environment restrictions
- Sandbox cost control policies

### Phase 4: Account Factory for Terraform (30-45 minutes)

```bash
# 1. Navigate to AFT setup  
cd ../04-aft-setup

# 2. Copy variables
cp ../terraform.tfvars.example terraform.tfvars
# Edit AFT account email

# 3. Initialize and deploy
terraform init
terraform plan
terraform apply
```

**What this creates:**
- AFT Management account
- Terraform backend (S3 + DynamoDB)
- Account provisioning Lambda function
- CodeCommit repository for account requests
- EventBridge rules for automation
- SNS topics for notifications

## 📧 Email Address Requirements

You need **3 unique email addresses**:

```bash
# Example email structure:
log_archive_account_email = "aws-logs@yourcompany.com"
audit_account_email       = "aws-audit@yourcompany.com" 
aft_account_email         = "aws-aft@yourcompany.com"
```

**Options:**
- Use email aliases: `admin+aws-logs@yourcompany.com`
- Use subdirectory: `aws/logs@yourcompany.com`
- Create dedicated accounts

## 🔧 Customization Options

### Variable Customization

Edit `terraform.tfvars` in each phase:

```hcl
# Basic Configuration
organization_name = "Your Company Name"
home_region      = "us-east-1"  # or your preferred region

# Email Addresses (REQUIRED - must be unique)
log_archive_account_email = "your-unique-email@company.com"
audit_account_email       = "another-unique-email@company.com"
aft_account_email         = "third-unique-email@company.com"

# Regional Configuration
allowed_regions = [
  "us-east-1",
  "us-west-2", 
  "eu-west-1"
]
```

### SCP Customization

Common customizations in `03-scps/main.tf`:

```hcl
# Allow additional instance types
"ec2:InstanceType" = [
  "t3.micro", "t3.small", "t3.medium",
  "m5.large", "m5.xlarge",
  "c5.large", "c5.xlarge"  # Add these
]

# Allow additional regions
allowed_regions = [
  "us-east-1", "us-west-2",
  "eu-central-1", "ap-southeast-1"  # Add these
]
```

## 🏗️ Architecture Overview

```
Management Account
├── Organizations
│   ├── Root OU
│   │   ├── Core OU
│   │   │   ├── Log Archive Account
│   │   │   ├── Audit Account
│   │   │   └── AFT Management Account
│   │   └── Workloads OU
│   │       ├── Production OU
│   │       ├── Non-Production OU
│   │       └── Sandbox OU
│   └── Service Control Policies
│       ├── Root Level (All accounts)
│       ├── Production Specific
│       └── Sandbox Specific
└── Control Tower Landing Zone
    ├── Baseline Security Controls
    ├── Centralized Logging
    ├── Config Rules
    └── AFT Automation
```

## 🔍 Validation Steps

After each phase, validate the deployment:

### Phase 1 Validation:
```bash
# Check Organizations
aws organizations describe-organization
aws organizations list-roots
aws organizations list-organizational-units-for-parent --parent-id <root-id>
```

### Phase 2 Validation:
```bash
# Check Control Tower
aws controltower list-landing-zones
aws organizations list-accounts

# Verify accounts created
aws organizations describe-account --account-id <log-archive-account-id>
aws organizations describe-account --account-id <audit-account-id>
```

### Phase 3 Validation:
```bash
# Check SCPs
aws organizations list-policies --filter SERVICE_CONTROL_POLICY
aws organizations list-policies-for-target --target-id <ou-id> --filter SERVICE_CONTROL_POLICY
```

### Phase 4 Validation:
```bash
# Check AFT resources
aws s3 ls | grep aft-backend
aws dynamodb list-tables | grep aft-backend-lock
aws lambda list-functions | grep aft-account-provisioning
```

## 🚨 Troubleshooting

### Common Issues:

**"Organizations already exists"**
- Solution: Import existing organization or start fresh

**"Control Tower deployment failed"**
- Check region support
- Verify email addresses are unique
- Ensure no existing Control Tower setup

**"Email already in use"**
- Each account needs a unique email address
- Use email aliases or create new addresses

**"Region not supported"**
- Control Tower has limited regional availability
- Use supported regions: us-east-1, us-west-2, eu-west-1, etc.

### Cleanup Commands:

```bash
# Destroy in reverse order
cd 04-aft-setup && terraform destroy
cd ../03-scps && terraform destroy  
cd ../02-control-tower && terraform destroy
cd ../01-organizations && terraform destroy
```

## 📊 Monitoring & Management

### Post-Deployment Monitoring:

1. **Control Tower Dashboard**: Monitor landing zone health
2. **Config Dashboard**: Track compliance status  
3. **CloudTrail**: Review API activity
4. **Cost Explorer**: Monitor costs across accounts

### Ongoing Management:

- **Monthly**: Review SCP effectiveness
- **Quarterly**: Update Terraform and Control Tower
- **Annually**: Audit account structure and policies

## 🎯 Next Steps

After successful deployment:

1. **Create workload accounts** using AFT
2. **Deploy applications** to managed accounts  
3. **Monitor compliance** via Config and Security Hub
4. **Customize account baselines** as needed
5. **Train teams** on the new multi-account structure

## 📞 Support Resources

- **AWS Control Tower**: https://docs.aws.amazon.com/controltower/
- **Account Factory for Terraform**: https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html
- **Organizations**: https://docs.aws.amazon.com/organizations/
- **Service Control Policies**: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html

Your enterprise-grade AWS multi-account environment is now ready! 🎉
