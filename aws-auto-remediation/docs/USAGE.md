# AWS Resource Manager Usage Guide

This guide covers the usage of automation scripts and tools in the AWS Resource Manager project.

## Automation Scripts

All Python automation scripts are located in the `automation/` directory and provide CLI interfaces for security management tasks.

### Security Group Remediation

The `security_group_remediation.py` script provides comprehensive security group auditing and remediation capabilities.

#### Finding Overly Permissive Security Groups

```bash
cd automation
python security_group_remediation.py find
```

#### Generating Security Reports

```bash
# Generate detailed JSON report
python security_group_remediation.py report --output security_report.json

# Generate human-readable report
python security_group_remediation.py report --format human
```

#### Remediating Security Groups

```bash
# Dry run remediation (recommended first)
python security_group_remediation.py remediate sg-12345678 --dry-run

# Apply remediation
python security_group_remediation.py remediate sg-12345678 --replacement-cidrs 10.0.0.0/8,172.16.0.0/12

# Bulk remediation with dry run
python security_group_remediation.py bulk-remediate --dry-run
```

#### AWS Profile and Region Configuration

```bash
# Use specific AWS profile
python security_group_remediation.py find --profile production

# Use specific region
python security_group_remediation.py find --region us-west-2

# Combine profile and region
python security_group_remediation.py find --profile production --region eu-west-1
```

## Shell Scripts

Shell scripts are located in the `scripts/` directory and provide automation for common security operations.

### Emergency Response

The `emergency_remediation.sh` script provides comprehensive VPC lockdown capabilities for active security incidents.

```bash
cd scripts

# Dry run emergency lockdown
./emergency_remediation.sh --vpc-id vpc-12345678 --dry-run

# Execute emergency lockdown
./emergency_remediation.sh --vpc-id vpc-12345678 --confirm

# Lockdown with custom replacement CIDR
./emergency_remediation.sh --vpc-id vpc-12345678 --replacement-cidr 10.0.0.0/16 --confirm
```

### Daily Security Checks

```bash
# Run daily security audit
./daily_security_check.sh

# Run with custom configuration
./daily_security_check.sh --config custom-config.yaml
```

### Compliance Checking

```bash
# Run compliance check
./compliance_check.sh

# Check specific compliance framework
./compliance_check.sh --framework cis --level 1
```

## Common Patterns

### Security Auditing Workflow

1. **Daily Monitoring**:
   ```bash
   ./scripts/daily_security_check.sh
   ```

2. **Detailed Analysis**:
   ```bash
   cd automation
   python security_group_remediation.py report --output daily_report.json
   ```

3. **Remediation Planning**:
   ```bash
   python security_group_remediation.py bulk-remediate --dry-run
   ```

4. **Apply Changes**:
   ```bash
   python security_group_remediation.py bulk-remediate
   ```

### Incident Response Workflow

1. **Immediate Assessment**:
   ```bash
   cd automation
   python security_group_remediation.py find --ports all
   ```

2. **Emergency Lockdown**:
   ```bash
   cd scripts
   ./emergency_remediation.sh --vpc-id vpc-affected --dry-run
   ./emergency_remediation.sh --vpc-id vpc-affected --confirm
   ```

3. **Post-Incident Review**:
   ```bash
   cd automation
   python security_group_remediation.py report --output incident_report.json
   ```

## Output Formats

### JSON Reports
All tools support JSON output for integration with other systems:
```bash
python security_group_remediation.py report --output report.json --format json
```

### Human-Readable Reports
For manual review:
```bash
python security_group_remediation.py report --format human
```

### Logging
All tools provide comprehensive logging:
```bash
python security_group_remediation.py find --log-level DEBUG 2> debug.log
```

## Error Handling

All scripts include comprehensive error handling and will:
- Validate AWS credentials before execution
- Perform dry-run validations
- Provide detailed error messages
- Log all operations for audit trails

## Best Practices

1. **Always Use Dry Run First**: Test changes before applying them
2. **Monitor Logs**: Review log output for any issues
3. **Backup Configurations**: Save current state before making changes
4. **Use Appropriate Profiles**: Ensure you're working in the correct AWS account
5. **Review Reports**: Analyze reports before bulk operations
