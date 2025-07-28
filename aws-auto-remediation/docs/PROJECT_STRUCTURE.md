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

## Design Principles

### Simplicity-First Approach
- Direct boto3 usage without abstraction layers
- Self-contained scripts that are easy to understand and debug
- Minimal dependencies beyond the AWS SDK
- Clear, readable code over complex architectures

### CLI-First Design
- All tools designed for command-line usage and automation
- Scriptable with consistent argument patterns
- Clear help text and usage examples
- Consistent output formats (JSON/human-readable)

### Safety-First Operations
- Dry-run capability for all destructive operations
- Comprehensive logging and audit trails
- Safety confirmations for dangerous operations
- Backup and restoration guidance

### Modular Architecture
- Independent tools that can be used separately
- Clear separation of concerns between Python and shell scripts
- No dependencies between automation scripts
- Easy to extend without affecting existing tools

## Dependencies

### Python Dependencies
- **boto3**: AWS SDK for Python
- **botocore**: Core functionality for boto3
- Standard library modules only (no external dependencies beyond boto3)

### System Dependencies
- **aws-cli**: For shell scripts
- **jq**: For JSON processing in shell scripts
- **bash**: Shell scripting environment

## Security Considerations

### Credentials Management
- Support for AWS profiles
- Environment variable configuration
- IAM role-based access
- No hardcoded credentials

### Permissions Required
- **EC2**: Describe and modify security groups, NACLs, route tables
- **VPC**: Describe and modify VPC components
- **IAM**: Read access for compliance checking
- **CloudTrail**: Read access for audit logging

### Audit Trail
- Comprehensive logging for all operations
- JSON output for integration with SIEM systems
- Operation timestamps and user tracking
- Before/after state capture

## Extension Points

### Adding New Automation Scripts
1. Create new Python script in `automation/`
2. Follow the established CLI pattern with argparse
3. Use direct boto3 calls (no abstraction layer)
4. Include comprehensive logging and error handling
5. Support dry-run operations

### Adding New Shell Scripts
1. Create new shell script in `scripts/`
2. Follow safety-first design principles
3. Include dry-run capability
4. Add comprehensive error checking
5. Document usage and dependencies

### Adding New Documentation
- Update this PROJECT_STRUCTURE.md for structural changes
- Update USAGE.md for new commands or workflows
- Update main README.md for significant feature additions

## Migration Notes

This project has been significantly restructured from a more complex architecture to focus on practical security automation:

### What Was Removed
- **AWSResourceManager abstraction layer**: Eliminated unnecessary wrapper around boto3
- **tests/ directory**: Removed unit tests for simplified maintenance
- **examples/ directory**: Removed in favor of comprehensive CLI help and documentation
- **setup.py**: Removed package setup as tools are designed for direct execution

### What Was Simplified
- **security_group_remediation.py**: Now uses direct boto3 calls instead of inheritance
- **Documentation**: Focused on practical usage rather than API documentation
- **Dependencies**: Reduced to boto3 + standard library only

### Benefits of New Architecture
- **Easier to understand**: No abstraction layers to navigate
- **Easier to debug**: Direct AWS API calls with clear error messages
- **Easier to maintain**: Fewer files and dependencies
- **Easier to extend**: Clear patterns for adding new automation scripts
- **Security-focused**: All tools designed for specific security use cases

### Backward Compatibility
- All CLI interfaces remain the same
- All functionality is preserved
- Scripts can be run from the same locations
- Output formats are unchanged

The simplified architecture makes the tools more accessible to security teams who need to quickly understand, modify, or extend the automation capabilities during incident response scenarios.
