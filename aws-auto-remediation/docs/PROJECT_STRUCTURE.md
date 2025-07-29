# aws-auto-remedaition - Project Structure

## Overview

The project is a collection of automation scripts and tools designed specifically for AWS security management and incident response. The project has been restructured to follow a CLI-first approach, removing unnecessary abstractions and focusing on practical security tools that can be easily understood, maintained, and extended.

## Directory Structure

```
aws-auto-remedaition/
├── automation/                    # Python automation scripts
│   ├── security_group_remediation.py  # Security group auditing and remediation
│   └── README.md                      # Detailed command reference
├── scripts/                           # Shell scripts for automation
│   ├── emergency_remediation.sh       # VPC lockdown for security incidents
│   ├── compliance_check.sh            # Security compliance checks
│   └── daily_security_check.sh        # Routine security audits
├── tf/                               # Terraform for testing infrastructure
│   ├── main.tf                       # Main infrastructure definitions
│   ├── variables.tf                  # Variable definitions
│   ├── outputs.tf                    # Output definitions
│   └── terraform.tfvars.example      # Example configuration
├── docs/                             # Documentation
│   ├── PROJECT_STRUCTURE.md          # This file
│   └── USAGE.md                      # Usage guide
├── requirements.txt                   # Python dependencies
└── README.md                         # Main project documentation
```

## Core Components

### Automation Scripts (`automation/`)

**security_group_remediation.py**
- **Purpose**: Comprehensive security group auditing and remediation
- **Architecture**: Self-contained script using direct boto3 calls (no abstraction layers)
- **Key Features**:
  - Find overly permissive security groups (0.0.0.0/0 access)
  - Generate detailed security reports with risk assessment
  - Automated remediation with safe replacement CIDRs
  - Bulk operations with comprehensive dry-run support
  - Risk prioritization (high/medium/low based on port exposure)
- **Dependencies**: boto3 only (no custom abstractions)
- **Usage**: CLI-based with argparse for all operations

### Shell Scripts (`scripts/`)

**emergency_remediation.sh**
- **Purpose**: Emergency VPC lockdown during active security incidents
- **Key Features**:
  - Multi-layer VPC lockdown (security groups, NACLs, routes)
  - EC2 instance and EIP management
  - Dry-run capability with detailed preview
  - Automated restoration guide generation
  - Safety checks and confirmations
- **Dependencies**: aws-cli, jq
- **Usage**: CLI with safety flags

**compliance_check.sh**
- **Purpose**: Regular security compliance auditing
- **Key Features**:
  - CIS benchmark compliance checking
  - Automated report generation
  - Multi-framework support
- **Dependencies**: aws-cli, jq

**daily_security_check.sh**
- **Purpose**: Routine security monitoring
- **Key Features**:
  - Daily security posture assessment
  - Automated alerting integration
  - Trend analysis support
- **Dependencies**: aws-cli, jq

### Testing Infrastructure (`tf/`)

The Terraform configuration provides testing infrastructure for validating security tools:

- **VPC and networking components** for testing network security
- **Security groups with various configurations** for testing remediation
- **EC2 instances** for testing emergency response procedures
- **IAM roles and policies** for testing access controls


