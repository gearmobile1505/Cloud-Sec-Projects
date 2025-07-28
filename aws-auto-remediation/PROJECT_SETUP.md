# Project Setup and Directory Structure

This document explains the correct project structure and how to use the AWS Security Automation tools after our troubleshooting and consolidation process.

## Final Directory Structure

```
aws-auto-remediation/
├── automation/                    # Python automation scripts
│   ├── security_group_remediation.py  # Main remediation tool
│   └── README.md                      # Detailed command reference
├── scripts/                           # Shell scripts for automation
│   ├── emergency_remediation.sh       # VPC lockdown for security incidents
│   ├── compliance_check.sh            # Security compliance checks
│   └── daily_security_check.sh        # Routine security audits
├── tf/                               # Terraform infrastructure (testing)
│   ├── main.tf                       # Main infrastructure definition
│   ├── variables.tf                  # Input variables
│   ├── outputs.tf                    # Output definitions
│   ├── terraform.tfstate             # Current state (active deployment)
│   ├── terraform.tfvars              # Variable values
│   └── README.md                     # Terraform-specific documentation
├── docs/                             # Project documentation
│   ├── PROJECT_STRUCTURE.md          # Architecture documentation
│   └── USAGE.md                      # Usage examples
├── requirements.txt                  # Python dependencies
└── README.md                         # Main project documentation
```

## Working Directories

### For Terraform Operations
```bash
cd /Users/marcaelissanders/Desktop/Cloud-Sec-Projects/aws-auto-remediation/tf

# All terraform commands work from here:
terraform plan
terraform apply
terraform output
```

### For Security Group Remediation
```bash
cd /Users/marcaelissanders/Desktop/Cloud-Sec-Projects/aws-auto-remediation/tf

# All python commands work with relative paths:
python3 ../automation/security_group_remediation.py find
python3 ../automation/security_group_remediation.py bulk-remediate --dry-run
```

### For Emergency VPC Remediation
```bash
cd /Users/marcaelissanders/Desktop/Cloud-Sec-Projects/aws-auto-remediation

# Emergency script works from project root:
./scripts/emergency_remediation.sh --dry-run --vpc vpc-0c4f84d7379b8f939
```

## Key Fixes Applied

1. **Consolidated Directory Structure**: Moved all Terraform files to the correct location in `aws-auto-remediation`
2. **Fixed Relative Paths**: Updated all outputs.tf references to use correct relative paths (`../automation/`)
3. **Updated Documentation**: Fixed project name references from "aws-resource-manager" to "aws-auto-remediation"
4. **Verified Working Paths**: Tested all command paths to ensure they work correctly

## Current Infrastructure Status

- **VPC**: vpc-0c4f84d7379b8f939 (deployed and active)
- **Security Groups**: 5 test groups with various risk levels
- **Testing Infrastructure**: Fully deployed with permissive NACLs, route tables, and flow logs
- **State File**: Located at `aws-auto-remediation/tf/terraform.tfstate`

## Testing Commands (Verified Working)

```bash
# From tf/ directory:
cd /Users/marcaelissanders/Desktop/Cloud-Sec-Projects/aws-auto-remediation/tf

# Find risky security groups
python3 ../automation/security_group_remediation.py find --ports "22,3389"

# Bulk remediation (dry-run)
python3 ../automation/security_group_remediation.py bulk-remediate --dry-run

# Generate security report
python3 ../automation/security_group_remediation.py report --output security_report.json

# Test emergency VPC remediation
cd .. && ./scripts/emergency_remediation.sh --dry-run --vpc vpc-0c4f84d7379b8f939
```

All paths and commands have been verified to work correctly with the consolidated project structure.
