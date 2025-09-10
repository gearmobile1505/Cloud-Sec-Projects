# AFT Account Request Examples

This directory contains examples for creating new AWS accounts using Account Factory for Terraform (AFT).

## 🎯 Account Request Process

AFT uses Git-based workflow for account provisioning:

1. **Create account request file** in JSON format
2. **Commit to repository** (CodeCommit or external Git)
3. **AFT processes request** automatically
4. **Account provisioned** with baseline configurations
5. **Custom configurations applied** via Lambda

## 📋 Account Request Template

### Basic Account Request

```json
{
  "account_name": "MyWorkload-Production",
  "account_email": "myworkload-prod@company.com",
  "organizational_unit": "Workloads/Production", 
  "account_customizations_name": "production-baseline",
  "custom_fields": {
    "Environment": "Production",
    "Owner": "Platform Team",
    "CostCenter": "Engineering-001",
    "Project": "MyWorkload"
  }
}
```

### Development Account Request

```json
{
  "account_name": "MyApp-Development",
  "account_email": "myapp-dev@company.com",
  "organizational_unit": "Workloads/Non-Production",
  "account_customizations_name": "development-baseline",
  "custom_fields": {
    "Environment": "Development", 
    "Owner": "Development Team",
    "CostCenter": "Engineering-002",
    "Project": "MyApp",
    "AutoShutdown": "true",
    "MaxMonthlyCost": "500"
  }
}
```

### Sandbox Account Request

```json
{
  "account_name": "Innovation-Sandbox",
  "account_email": "sandbox-innovation@company.com", 
  "organizational_unit": "Workloads/Sandbox",
  "account_customizations_name": "sandbox-baseline",
  "custom_fields": {
    "Environment": "Sandbox",
    "Owner": "Innovation Team", 
    "CostCenter": "Research-001",
    "Project": "Innovation Lab",
    "AutoShutdown": "true",
    "MaxMonthlyCost": "200",
    "AllowedServices": "ec2,s3,lambda,dynamodb"
  }
}
```

## 🔧 Account Customization Templates

### Production Baseline (`production-baseline`)

Features:
- ✅ Enhanced monitoring (CloudWatch, X-Ray)
- ✅ Backup automation (AWS Backup)
- ✅ Multi-AZ deployments enforced
- ✅ Encryption at rest required
- ✅ VPC Flow Logs enabled
- ✅ Config rules for compliance
- ❌ Administrative access restricted

### Development Baseline (`development-baseline`)

Features:
- ✅ Basic monitoring (CloudWatch)
- ✅ Cost controls and budgets
- ✅ Auto-shutdown policies
- ✅ Developer tool access
- ✅ Relaxed security policies
- ✅ Experimentation allowed

### Sandbox Baseline (`sandbox-baseline`)

Features:
- ✅ Aggressive cost controls
- ✅ Time-based auto-shutdown
- ✅ Limited service access
- ✅ Educational resources
- ✅ Self-service capabilities
- ⚠️ Minimal compliance requirements

## 📝 Step-by-Step Account Creation

### 1. Prepare Account Request

```bash
# Create account request file
cat > account-requests/myapp-prod.json << EOF
{
  "account_name": "MyApp-Production",
  "account_email": "myapp-prod@company.com",
  "organizational_unit": "Workloads/Production",
  "account_customizations_name": "production-baseline",
  "custom_fields": {
    "Environment": "Production",
    "Owner": "MyApp Team",
    "CostCenter": "ENG-001",
    "Project": "MyApp"
  }
}
EOF
```

### 2. Validate Account Request

```bash
# Validate JSON syntax
python3 -m json.tool account-requests/myapp-prod.json

# Check email uniqueness
aws organizations list-accounts --query 'Accounts[?Email==`myapp-prod@company.com`]'
```

### 3. Submit Request

```bash
# Add to Git repository
git add account-requests/myapp-prod.json
git commit -m "Add production account for MyApp"
git push origin main
```

### 4. Monitor Provisioning

```bash
# Check AFT pipeline status
aws codepipeline get-pipeline-state --name aft-account-provisioning-pipeline

# Monitor CloudWatch logs
aws logs tail /aws/lambda/aft-account-provisioning --follow
```

## 🏢 Organizational Unit Mapping

```
Root/
├── Core/                          # Management accounts only
│   ├── Log Archive               
│   ├── Audit                     
│   └── AFT Management            
├── Workloads/                     # Application accounts
│   ├── Production/               # OU: "Workloads/Production"
│   ├── Non-Production/           # OU: "Workloads/Non-Production" 
│   └── Sandbox/                  # OU: "Workloads/Sandbox"
└── Security/                      # Security-specific accounts
    ├── Security Tools/           # OU: "Security/Security Tools"
    └── Incident Response/        # OU: "Security/Incident Response"
```

## 🚨 Account Request Validation Rules

### Required Fields:
- ✅ `account_name`: Unique, descriptive name
- ✅ `account_email`: Valid, unique email address  
- ✅ `organizational_unit`: Valid OU path
- ✅ `account_customizations_name`: Existing baseline name

### Validation Checks:
- **Email uniqueness**: No duplicate email addresses
- **OU existence**: Target OU must exist
- **Baseline validation**: Customization template must exist
- **Naming conventions**: Follow organizational standards
- **Cost center validation**: Must be valid cost center code

## 💰 Cost Management

### Budget Configuration

Each account gets automatic budgets based on environment:

```json
{
  "Production": {
    "monthly_budget": 5000,
    "alert_threshold": 80,
    "force_stop_threshold": 95
  },
  "Development": {
    "monthly_budget": 1000, 
    "alert_threshold": 70,
    "force_stop_threshold": 90
  },
  "Sandbox": {
    "monthly_budget": 200,
    "alert_threshold": 60, 
    "force_stop_threshold": 85
  }
}
```

## 🔐 Security Configurations

### Account-Level Security

All accounts receive baseline security configurations:

- **CloudTrail**: Organization-wide trail enabled
- **Config**: Compliance rules activated  
- **GuardDuty**: Threat detection enabled
- **Security Hub**: Centralized findings
- **IAM**: Least privilege access
- **VPC**: Default security groups locked down

### Environment-Specific Security

**Production Accounts:**
- Multi-factor authentication required
- Admin access restricted to break-glass procedures
- All data encrypted at rest and in transit
- Network segmentation enforced

**Development/Sandbox Accounts:**
- Relaxed access for development needs
- Cost-based restrictions instead of security
- Educational security notifications
- Self-service capabilities enabled

## 📊 Monitoring and Alerts

### Account Health Dashboard

Monitor account provisioning status:

```bash
# Check account creation status
aws organizations list-create-account-status

# Monitor AFT Lambda function
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/aft-

# Check Control Tower compliance
aws controltower get-landing-zone-operation --operation-identifier <operation-id>
```

### Common Issues and Solutions

**"Email address already in use"**
```bash
# Check existing accounts
aws organizations list-accounts --query 'Accounts[?Email==`your-email@company.com`]'
```

**"Organizational Unit not found"**
```bash  
# List available OUs
aws organizations list-organizational-units-for-parent --parent-id <root-ou-id>
```

**"Account customization failed"**
```bash
# Check Lambda logs
aws logs tail /aws/lambda/aft-account-provisioning --start-time 1h
```

## 🎯 Best Practices

### 1. Email Management
- Use consistent email patterns: `project-environment@company.com`
- Consider email aliases for management
- Document email assignments

### 2. Naming Conventions  
- Include project and environment: `MyApp-Production`
- Avoid special characters and spaces
- Keep names descriptive but concise

### 3. Tagging Strategy
- Always include: Environment, Owner, CostCenter, Project
- Use consistent tag values across accounts
- Enable cost allocation tags

### 4. Security Considerations
- Request minimum required permissions
- Use time-limited sandbox accounts
- Regular access reviews for production accounts
- Monitor cross-account access patterns

## 📞 Support and Documentation

- **AFT Documentation**: https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html
- **Account Factory**: https://docs.aws.amazon.com/controltower/latest/userguide/account-factory.html  
- **Organizations**: https://docs.aws.amazon.com/organizations/
- **Internal Wiki**: [Add your internal documentation links]

Ready to create your first account? Follow the examples above and customize based on your organization's needs! 🚀
