# Custom Service Control Policies Examples

This directory contains examples of custom Service Control Policies (SCPs) that can be added to your AWS Control Tower setup for additional governance and compliance requirements.

## 📋 Available SCP Examples

### 1. **Data Sovereignty Policies**
- EU-specific region restrictions
- Data residency requirements
- Cross-border data transfer controls

### 2. **Compliance Frameworks**
- PCI DSS compliance policies
- HIPAA healthcare regulations
- SOX financial controls
- GDPR privacy requirements

### 3. **Cost Management**
- Instance size restrictions
- Service usage limitations
- Reserved instance requirements
- Spot instance policies

### 4. **Security Hardening**
- Encryption requirements
- Network security controls
- IAM permission boundaries
- API logging enforcement

### 5. **Operational Controls**
- Change management requirements
- Backup and recovery policies
- Monitoring and alerting rules
- Resource tagging enforcement

## 🔧 Implementation Guide

### Step 1: Select Your Policies

Choose the appropriate SCP templates based on your requirements:

```bash
# Copy desired policy template
cp templates/pci-compliance-scp.json policies/
cp templates/eu-data-residency-scp.json policies/
```

### Step 2: Customize Policies

Edit the JSON files to match your specific requirements:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "eu-west-1",
            "eu-central-1",
            "eu-north-1"
          ]
        }
      }
    }
  ]
}
```

### Step 3: Apply with Terraform

Add your custom policies to the main SCP configuration:

```hcl
# In 03-scps/main.tf
resource "aws_organizations_policy" "custom_policy" {
  name        = "CustomCompliancePolicy"
  description = "Custom compliance requirements"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("../examples/scp-customizations/policies/custom-policy.json")
}

resource "aws_organizations_policy_attachment" "custom_attachment" {
  policy_id = aws_organizations_policy.custom_policy.id
  target_id = aws_organizations_organizational_unit.workloads_production.id
}
```

## 🏢 Policy Categories

### Regional Restrictions

**Use Case**: Data sovereignty and compliance requirements

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNonEURegions",
      "Effect": "Deny", 
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "eu-west-1",
            "eu-west-2", 
            "eu-central-1",
            "eu-north-1"
          ]
        },
        "ForAnyValue:StringNotEquals": {
          "aws:PrincipalServiceName": [
            "cloudformation.amazonaws.com",
            "config.amazonaws.com"
          ]
        }
      }
    }
  ]
}
```

### Instance Type Restrictions

**Use Case**: Cost control and standardization

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RestrictInstanceTypes",
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "ForAnyValue:StringNotEquals": {
          "ec2:InstanceType": [
            "t3.micro",
            "t3.small", 
            "t3.medium",
            "t3.large",
            "m5.large",
            "m5.xlarge",
            "c5.large",
            "c5.xlarge"
          ]
        }
      }
    }
  ]
}
```

### Encryption Requirements

**Use Case**: Security compliance and data protection

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RequireEncryptedStorage",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "ec2:Encrypted": "false"
        }
      }
    },
    {
      "Sid": "RequireEncryptedS3",
      "Effect": "Deny",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": [
            "AES256",
            "aws:kms"
          ]
        }
      }
    }
  ]
}
```

## 🎯 Best Practices

### 1. **Policy Testing**
```bash
# Test policies in non-production first
# Use AWS Policy Simulator for validation
# Monitor CloudTrail for denied actions
```

### 2. **Gradual Rollout**
```bash
# Start with warnings (allow but log)
# Progress to enforcement (deny)
# Monitor impact on applications
```

### 3. **Documentation**
```bash
# Document business justification
# Include emergency bypass procedures  
# Maintain change history
```

### 4. **Regular Review**
```bash
# Quarterly policy effectiveness review
# Annual compliance audit
# Update based on changing requirements
```

## 📊 Monitoring and Compliance

### CloudTrail Integration

Monitor SCP effectiveness through CloudTrail:

```json
{
  "eventName": "ConsoleLogin",
  "errorCode": "AccessDenied", 
  "errorMessage": "An explicit deny in a service control policy"
}
```

### Compliance Reporting

Generate compliance reports:

```bash
# Query denied actions
aws logs filter-log-events \
  --log-group-name CloudTrail/ManagementEvents \
  --filter-pattern "{ $.errorCode = \"AccessDenied\" && $.errorMessage = \"*service control policy*\" }"

# Export for compliance audit
aws logs export-task --log-group-name CloudTrail/ManagementEvents \
  --from-time 1640995200000 --to-time 1672531200000 \
  --destination compliance-exports
```

## 🚨 Emergency Procedures

### Temporary Policy Bypass

For emergency situations:

1. **Document the emergency**
2. **Get approval from security team**
3. **Temporarily detach policy**
4. **Perform required actions**
5. **Re-attach policy immediately**
6. **Conduct post-incident review**

### Emergency Terraform Commands

```bash
# Detach policy temporarily
terraform state rm aws_organizations_policy_attachment.emergency_bypass

# Reapply after emergency
terraform import aws_organizations_policy_attachment.emergency_bypass policy-id:target-id
terraform apply
```

## 📞 Support and Resources

- **AWS SCP Documentation**: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
- **Policy Examples**: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html
- **Compliance Frameworks**: See individual compliance directories
- **Internal Contacts**: [Add your organization's contacts]

Ready to implement custom governance policies for your organization! 🛡️
