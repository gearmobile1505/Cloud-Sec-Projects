# Cloud Security Projects 🛡️

Automated security compliance tools for AWS and Kubernetes with GitHub Actions workflows.

## 🔍 Projects

- **[CIS Benchmark Checker](./cis-benchmark-checker/)** - AWS & Kubernetes CIS compliance automation with test infrastructure
- **[Sentinel KQL Queries](./sentinel-kql-queries/)** - Microsoft Sentinel threat hunting queries
- **[AWS Auto Remediation](./aws-auto-remediation/)** - Security remediation framework

## 🚀 Quick Start

### Option 1: Use GitHub Actions (Recommended)
1. Fork this repository
2. Add AWS credentials to GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Run "Deploy and Test CIS Infrastructure" workflow

### Option 2: Local Usage
```bash
cd cis-benchmark-checker/scripts
pip install -r requirements.txt
aws configure
python3 cis_checker.py check --format json
```

## � Requirements

- AWS CLI with configured credentials
- Python 3.9+
- Terraform 1.5+ (for infrastructure deployment)

## ⚠️ Security Notice

These tools deploy intentionally vulnerable test infrastructure for compliance testing. Always run in isolated test environments.
