# AWS Security Automation

A collection of automation scripts and tools for AWS security management and remediation. This project focuses on practical CLI tools for security auditing and emergency response scenarios.

## Features

- **Security Group Remediation**: Automated detection and remediation of overly permissive security groups
- **Emergency Response**: Comprehensive VPC lockdown capabilities for active security incidents
- **CLI-First Design**: All tools designed for command-line usage and automation
- **Comprehensive Logging**: Built-in logging for all operations
- **Dry-Run Support**: Test changes before applying them
- **Multiple AWS Profiles**: Support for different AWS credential profiles

## Project Structure

```
aws-auto-remediation/
├── automation/                    # Python automation scripts
│   ├── security_group_remediation.py
│   └── README.md                 # Detailed command reference
├── scripts/                      # Shell scripts for automation
│   ├── emergency_remediation.sh  # VPC lockdown for security incidents
│   ├── compliance_check.sh       # Security compliance checks
│   └── daily_security_check.sh   # Routine security audits
├── tf/                          # Terraform infrastructure (testing)
├── docs/                        # Documentation
└── requirements.txt             # Python dependencies
```

## Prerequisites

- Python 3.7 or higher
- boto3 library
- AWS credentials configured (via AWS CLI, environment variables, or IAM roles)
- jq (for shell scripts)

## Installation

1. Install required dependencies:
```bash
pip install -r requirements.txt
```

2. Configure AWS credentials using one of these methods:
   - AWS CLI: `aws configure`
   - Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - IAM roles (when running on EC2)

## Quick Start

### Security Group Auditing
```bash
# Find all overly permissive security groups
cd automation
python security_group_remediation.py find

# Generate detailed security report
python security_group_remediation.py report --output security_report.json

# Remediate specific security group (dry run)
python security_group_remediation.py remediate sg-12345678 --dry-run
```

### Emergency Response
```bash
# Emergency VPC lockdown (dry run)
cd scripts
./emergency_remediation.sh --vpc-id vpc-12345678 --dry-run

# Full lockdown for active incident
./emergency_remediation.sh --vpc-id vpc-12345678 --confirm
```

## Documentation

- **[Automation Scripts](automation/README.md)**: Detailed command reference for Python tools
- **[Emergency Procedures](scripts/README.md)**: Guide for emergency response scripts

## Security Features

### Security Group Management
- Detect overly permissive rules (0.0.0.0/0 access)
- Automated remediation with safe defaults
- Risk assessment and prioritization
- Bulk operations with safety checks

### Emergency Response
- Multi-layer VPC lockdown
- Security group isolation
- Network ACL restrictions
- Route table modifications
- Automated restoration guides

## Examples

### Daily Security Audit
```bash
# Run comprehensive security check
./scripts/daily_security_check.sh

# Check specific security group compliance
cd automation
python security_group_remediation.py find --ports 22,3389,1433
```

### Incident Response
```bash
# Immediate lockdown of compromised VPC
./scripts/emergency_remediation.sh --vpc-id vpc-affected --confirm

# Review and remediate security groups
cd automation
python security_group_remediation.py bulk-remediate --dry-run
```

### Lambda Functions
```bash
# List all Lambda functions
python aws_resource_manager.py lambda

# Get function configuration
python aws_resource_manager.py lambda --operation get_function --params '{"FunctionName": "my-function"}'
```

For more detailed documentation, see the complete README.md file.
