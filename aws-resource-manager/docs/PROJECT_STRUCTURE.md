# Project Structure

```
aws-resource-manager/
├── aws_resource_manager.py          # Main flexible AWS SDK wrapper
├── security_group_remediation.py   # Security group remediation tool
├── README.md                        # Main documentation
├── requirements.txt                 # Python dependencies
├── setup.py                        # Package setup
├── .gitignore                      # Git ignore rules
│
├── examples/                       # Usage examples
│   ├── ec2_example.py             # EC2 operations
│   ├── s3_example.py              # S3 operations
│   ├── lambda_example.py          # Lambda operations
│   └── security_group_examples.py # Security group examples
│
├── scripts/                        # Automation scripts
│   ├── daily_security_check.sh    # Daily security audit
│   ├── emergency_remediation.sh   # Emergency security lockdown
│   └── compliance_check.sh        # Compliance verification
│
├── tests/                          # Unit tests
│   ├── test_aws_resource_manager.py      # Main tool tests
│   └── test_security_remediation.py      # Security tool tests
│
├── docs/                           # Documentation
│   ├── USAGE.md                   # Usage guide
│   ├── SECURITY_REMEDIATION.md    # Security remediation guide
│   └── PROJECT_STRUCTURE.md       # This file
│
├── reports/                        # Generated reports (created by scripts)
│   ├── security_report_YYYYMMDD.json
│   └── critical_open_sgs_YYYYMMDD.json
│
└── compliance/                     # Compliance reports (created by scripts)
    ├── compliance_report_YYYYMMDD_HHMMSS.json
    ├── ssh_rdp_violations_YYYYMMDD_HHMMSS.json
    ├── database_violations_YYYYMMDD_HHMMSS.json
    └── mgmt_violations_YYYYMMDD_HHMMSS.json
```

## File Descriptions

### Core Files
- **aws_resource_manager.py**: Flexible wrapper for any AWS service
- **security_group_remediation.py**: Specialized security group management

### Examples
- **security_group_examples.py**: Comprehensive security group examples
- **ec2_example.py**, **s3_example.py**, **lambda_example.py**: Service-specific examples

### Automation Scripts
- **daily_security_check.sh**: Automated daily security auditing
- **emergency_remediation.sh**: Quick emergency security lockdown
- **compliance_check.sh**: Regular compliance verification

### Testing
- **test_security_remediation.py**: Security tool unit tests
- **test_aws_resource_manager.py**: Main tool unit tests

### Documentation
- **SECURITY_REMEDIATION.md**: Comprehensive security guide
- **USAGE.md**: General usage documentation
- **PROJECT_STRUCTURE.md**: Project organization guide
