# AWS Resource Manager Automation Scripts

This directory contains the core Python automation scripts for AWS resource management and security remediation.

## Scripts

### `aws_resource_manager.py`
**Core AWS resource management functionality**

A comprehensive tool for managing AWS resources across multiple services with CLI interface.

**Key Features:**
- Multi-service support (EC2, S3, Lambda, DynamoDB, IAM, etc.)
- Dynamic operation discovery
- Flexible parameter handling
- Error handling and validation
- JSON output formatting

**Usage Examples:**
```bash
# List EC2 instances
python3 automation/aws_resource_manager.py ec2 --operation describe_instances

# List S3 buckets  
python3 automation/aws_resource_manager.py s3

# Get Lambda function details
python3 automation/aws_resource_manager.py lambda --operation get_function --params '{"FunctionName": "my-function"}'

# List available operations for a service
python3 automation/aws_resource_manager.py s3 --list-operations
```

### `security_group_remediation.py`
**Security group auditing and remediation tool**

Specialized tool for finding, analyzing, and remediating security group vulnerabilities.

**Key Features:**
- Find open/vulnerable security groups
- Generate detailed security reports
- Dry-run and actual remediation
- Risk level classification
- Bulk operations
- Custom port scanning

**Command Reference:**

#### Basic Syntax:
```bash
python3 automation/security_group_remediation.py [global_options] <command> [command_options]
```

#### Global Options:
- `--region <region>` - AWS region (default: us-east-1)
- `--profile <profile>` - AWS profile name (optional)

#### Available Commands:

**1. Find Open Security Groups**
```bash
python3 automation/security_group_remediation.py find [options]
```
Options:
- `--ports <ports>` - Comma-separated ports to check (default: common risky ports)
- `--output <file>` - Save results to JSON file

Examples:
```bash
# Find all security groups with common risky ports open
python3 automation/security_group_remediation.py find

# Find groups with SSH and RDP open
python3 automation/security_group_remediation.py find --ports "22,3389"

# Find groups with database ports open
python3 automation/security_group_remediation.py find --ports "3306,5432,6379,27017"

# Find ALL open security groups (any port)
python3 automation/security_group_remediation.py find --ports "all"

# Save results to file
python3 automation/security_group_remediation.py find --output security_audit.json

# Specify region
python3 automation/security_group_remediation.py --region us-west-2 find
```

**2. Remediate Specific Security Group**
```bash
python3 automation/security_group_remediation.py remediate <group_id> [options]
```
Required:
- `<group_id>` - Security group ID (e.g., sg-12345678)

Options:
- `--dry-run` - Show changes without applying them (RECOMMENDED for testing)
- `--cidrs <cidrs>` - Comma-separated replacement CIDRs (default: private networks)

Examples:
```bash
# Dry-run remediation (safe - shows what would change)
python3 automation/security_group_remediation.py remediate sg-12345678 --dry-run

# Actual remediation (be careful!)
python3 automation/security_group_remediation.py remediate sg-12345678

# Use custom replacement CIDRs
python3 automation/security_group_remediation.py remediate sg-12345678 --cidrs "10.0.0.0/8,172.16.0.0/12" --dry-run
```

**3. Bulk Remediate All Open Security Groups**
```bash
python3 automation/security_group_remediation.py bulk-remediate [options]
```
Options:
- `--dry-run` - Show changes without applying them (RECOMMENDED)
- `--cidrs <cidrs>` - Comma-separated replacement CIDRs
- `--ports <ports>` - Only remediate specific ports

Examples:
```bash
# Dry-run bulk remediation (safe)
python3 automation/security_group_remediation.py bulk-remediate --dry-run

# Remediate only SSH and RDP
python3 automation/security_group_remediation.py bulk-remediate --ports "22,3389" --dry-run

# Use custom CIDRs for all remediations
python3 automation/security_group_remediation.py bulk-remediate --cidrs "10.0.0.0/8,192.168.0.0/16" --dry-run
```

**4. Generate Security Report**
```bash
python3 automation/security_group_remediation.py report [options]
```
Options:
- `--output <file>` - Save report to JSON file

Examples:
```bash
# Generate and display report
python3 automation/security_group_remediation.py report

# Save report to file
python3 automation/security_group_remediation.py report --output security_report.json
```

#### Common Use Cases:

**Security Audit Workflow:**
```bash
# 1. Generate comprehensive report
python3 automation/security_group_remediation.py report --output audit_report.json

# 2. Find critical vulnerabilities (SSH/RDP)
python3 automation/security_group_remediation.py find --ports "22,3389"

# 3. Find database exposures
python3 automation/security_group_remediation.py find --ports "3306,5432,1433,27017,6379"
```

**Safe Remediation Workflow:**
```bash
# 1. Dry-run to see what would change
python3 automation/security_group_remediation.py bulk-remediate --dry-run

# 2. Test specific security group first
python3 automation/security_group_remediation.py remediate sg-12345678 --dry-run

# 3. Apply to specific group (when ready)
python3 automation/security_group_remediation.py remediate sg-12345678
```

**Multi-Region Audit:**
```bash
# Check different regions
python3 automation/security_group_remediation.py --region us-east-1 find
python3 automation/security_group_remediation.py --region us-west-2 find
python3 automation/security_group_remediation.py --region eu-west-1 find
```

#### Important Notes:

**Default Behavior:**
- **Risky ports checked by default:** 22, 3389, 1433, 3306, 5432, 6379, 27017, 9200, 5601
- **Default replacement CIDRs:** 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 (private networks)
- **Always start with `--dry-run`** to preview changes

**Safety Tips:**
1. **Always use `--dry-run` first** to see what will change
2. **Test on non-production environments** first
3. **Save audit reports** before making changes
4. **Remediate one security group at a time** initially

**Prerequisites:**
- AWS credentials configured (`aws configure` or IAM role)
- Required permissions: EC2 security group read/write access
- Python dependencies: `boto3`, `botocore`

## Package Structure

This directory is structured as a Python package with:
- `__init__.py` - Package initialization and exports
- Core automation scripts
- Proper imports for use in other modules

## Integration

These scripts are integrated with:
- **Tests**: `../tests/` directory
- **Examples**: `../examples/` directory  
- **Shell Scripts**: `../scripts/` directory
- **Terraform**: `../tf/` directory

## Dependencies

Required Python packages (see `../requirements.txt`):
- `boto3>=1.26.0`
- `botocore>=1.29.0`
- `typing-extensions>=4.0.0`

## Development

When adding new scripts:
1. Place them in this `automation/` directory
2. Update `__init__.py` exports if needed
3. Add corresponding tests in `../tests/`
4. Update documentation in `../docs/`
5. Create examples in `../examples/`

## Error Handling

All scripts include comprehensive error handling for:
- AWS credential issues
- Network connectivity problems
- Invalid parameters
- Service-specific errors
- Rate limiting

## Security Considerations

- Scripts follow AWS security best practices
- Support for IAM roles and policies
- Dry-run capabilities for safety
- Audit logging for compliance
- No hardcoded credentials
