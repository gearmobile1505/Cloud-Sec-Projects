# CIS Benchmark Checker for AWS

Automated compliance checking against the CIS AWS Foundations Benchmark v1.5.0. This tool provides comprehensive security posture assessment using AWS native services and APIs.

## 🚀 Quick Start

```bash
# 1. Install dependencies
cd scripts
pip install -r requirements.txt

# 2. Configure AWS credentials
aws configure

# 3. Run first compliance check
python3 cis_checker.py check --controls "1.12,5.2"

# 4. Deploy test infrastructure (optional)
cd ../tf && ./deploy.sh apply

# 5. Test against infrastructure
./deploy.sh test
```

## 📖 Documentation

- **[📋 Complete Usage Guide](docs/USAGE.md)** - Comprehensive documentation and examples
- **[🚀 Step-by-Step Walkthrough](docs/WALKTHROUGH.md)** - End-to-end setup guide
- **[🧪 Test Infrastructure Guide](tf/README.md)** - Terraform test environment

## 🏗️ Project Structure

```
cis-benchmark-checker/
├── scripts/                 # Python scripts and automation
│   ├── cis_checker.py      # Main CIS compliance checker
│   ├── extended_cis.py     # Extended compliance checks
│   ├── lambda_function.py  # AWS Lambda deployment
│   ├── run_cis_checks.sh   # Automation script
│   ├── config.yaml         # Configuration file
│   └── requirements.txt    # Python dependencies
├── docs/                   # Documentation
│   ├── USAGE.md           # Comprehensive usage guide
│   └── WALKTHROUGH.md     # Step-by-step setup guide
├── tf/                     # Test infrastructure
│   ├── *.tf               # Terraform configuration
│   ├── deploy.sh          # Deployment automation
│   └── README.md          # Infrastructure documentation
└── reports/               # Output directory for reports
```

## 🎯 Features

- **Comprehensive CIS Controls**: 25+ automated compliance checks
- **Multiple Deployment Options**: CLI, Lambda, or scheduled automation
- **Rich Reporting**: JSON, text, and HTML formats
- **AWS Integration**: Security Hub, Config, CloudTrail, SNS, S3
- **Test Infrastructure**: Complete Terraform environment for validation
- **Production Ready**: Error handling, logging, and configuration management

## 📋 Supported CIS Controls

### Identity and Access Management (IAM)
- **1.12** - No root user access key exists ⚠️ **CRITICAL**
- **1.13** - MFA enabled for root user ⚠️ **CRITICAL**
- **1.3-1.11** - Password policies, key rotation, credential management

### Logging (CloudTrail & Config)
- **3.1** - CloudTrail enabled in all regions
- **3.2** - CloudTrail log file validation enabled
- **3.3-3.8** - S3 security, CloudWatch integration, encryption

### Networking (VPC)
- **5.2** - Security groups don't allow ingress from 0.0.0.0/0 to admin ports
- **5.3** - Default security group restricts all traffic
- **5.5** - VPC flow logging enabled

## 💻 Basic Usage

```bash
cd scripts

# List all available controls
python3 cis_checker.py list

# Check critical controls
python3 cis_checker.py check --controls "1.12,5.2"

# Generate JSON report
python3 cis_checker.py check --format json --output ../reports/compliance.json

# Use automation script
./run_cis_checks.sh --controls "1.12,3.1,5.2"
```

> **📘 For detailed usage examples, automation, and advanced features:** See [docs/USAGE.md](docs/USAGE.md)

## 🗂️ Getting Started

**New users:** Start with the [📋 Complete Walkthrough](docs/WALKTHROUGH.md) for step-by-step instructions.

**Experienced users:** Check the [📘 Usage Guide](docs/USAGE.md) for comprehensive documentation.

**Want to test?** Deploy the [🧪 Test Infrastructure](tf/README.md) to validate the tool.

## � Documentation

- **[📋 WALKTHROUGH](docs/WALKTHROUGH.md)** - Complete step-by-step setup guide
- **[📘 USAGE](docs/USAGE.md)** - Detailed usage instructions and examples  
- **[🧪 TEST INFRASTRUCTURE](tf/README.md)** - Terraform test environment
- **[📚 DOCS INDEX](DOCS.md)** - Documentation navigation guide

## 📄 License

This project is licensed under the MIT License.

---

**Ready to start?** → [Complete Walkthrough](docs/WALKTHROUGH.md) | [Usage Guide](docs/USAGE.md)
