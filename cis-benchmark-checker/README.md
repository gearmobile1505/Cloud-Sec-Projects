# CIS Benchmark Checker for AWS & Kubernetes

## ⚠️ IMPORTANT: Update IP Addresses Before Deployment

**BEFORE deploying infrastructure, update `tf/kubernetes.tf`:**
```bash
# 1. Get your IP
curl ifconfig.me

# 2. Edit tf/kubernetes.tf and replace ALL instances of:
cidr_blocks = ["YOUR_IP_ADDRESS/32"]  # Replace with your actual IP

# 3. Or run the setup helper:
./setup.sh
```

## 🚀 Quick Start

```bash
# 1. Clone and setup
git clone <repository>
cd cis-benchmark-checker/scripts
pip install -r requirements.txt

# 2. Configure AWS credentials  
aws configure

# 3. Test your setup
python3 test_installation.py

# 4. Run compliance checks
python3 unified_cis_checker.py kubernetes check
python3 cis_checker.py check --controls "1.3,1.4"

# 5. Deploy test infrastructure (optional)
cd ../tf && terraform init && terraform plan
# Update YOUR_IP_ADDRESS in kubernetes.tf before applying!
terraform apply
```

## ⚠️ Important: Update IP Addresses

Before deploying infrastructure, update `tf/kubernetes.tf`:
```terraform
cidr_blocks = ["YOUR_IP_ADDRESS/32"]  # Replace with your actual IP
```

Find your IP: `curl ifconfig.me`

## 📖 Documentation

- **[📋 Complete Usage Guide](docs/USAGE.md)** - Comprehensive documentation and examples
- **[🚀 Step-by-Step Walkthrough](docs/WALKTHROUGH.md)** - End-to-end setup guide
- **[🧪 Test Infrastructure Guide](tf/README.md)** - Terraform test environment

## 🏗️ Project Structure

```
cis-benchmark-checker/
├── scripts/                      # Python scripts and automation
│   ├── cis_checker.py           # AWS CIS compliance checker
│   ├── k8s_cis_checker.py       # Kubernetes CIS compliance checker
│   ├── unified_cis_checker.py   # Unified checker for both platforms
│   ├── extended_cis.py          # Extended compliance checks
│   ├── lambda_function.py       # AWS Lambda deployment
│   ├── run_cis_checks.sh        # AWS automation script
│   ├── config.yaml              # Configuration file
│   └── requirements.txt         # Python dependencies
├── docs/                        # Documentation
│   ├── USAGE.md                # Comprehensive usage guide
│   └── WALKTHROUGH.md          # Step-by-step setup guide
├── tf/                          # Test infrastructure
│   ├── *.tf                    # Terraform configuration (AWS + EKS)
│   ├── kubernetes.tf           # EKS cluster with CIS violations
│   ├── k8s-manifests/          # Kubernetes test manifests
│   │   ├── insecure-workloads.yaml
│   │   ├── insecure-rbac.yaml
│   │   └── no-network-policies.yaml
│   ├── deploy.sh               # Main deployment automation
│   ├── k8s-deploy.sh           # Kubernetes-specific deployment
│   └── README.md               # Infrastructure documentation
└── reports/                     # Output directory for reports
```

## 🎯 Features

- **Multi-Platform Support**: AWS and Kubernetes CIS benchmark checking
- **Comprehensive CIS Controls**: 25+ AWS and 15+ Kubernetes automated compliance checks
- **Multiple Deployment Options**: CLI, Lambda, or scheduled automation
- **Rich Reporting**: JSON, text, and HTML formats
- **Cloud Integration**: AWS Security Hub, Config, CloudTrail, SNS, S3
- **Kubernetes Integration**: Native Kubernetes API integration and RBAC analysis
- **Test Infrastructure**: Complete Terraform environment with EKS for validation
- **Production Ready**: Error handling, logging, and configuration management

## 📋 Supported CIS Controls

### AWS Identity and Access Management (IAM)
- **1.12** - No root user access key exists ⚠️ **CRITICAL**
- **1.13** - MFA enabled for root user ⚠️ **CRITICAL**
- **1.3-1.11** - Password policies, key rotation, credential management

### AWS Logging (CloudTrail & Config)
- **3.1** - CloudTrail enabled in all regions
- **3.2** - CloudTrail log file validation enabled
- **3.3-3.8** - S3 security, CloudWatch integration, encryption

### AWS Networking (VPC)
- **5.2** - Security groups don't allow ingress from 0.0.0.0/0 to admin ports
- **5.3** - Default security group restricts all traffic
- **5.5** - VPC flow logging enabled

### Kubernetes Master Node Security
- **1.2.1** - API server anonymous authentication disabled ⚠️ **HIGH**
- **1.2.2** - Basic authentication disabled ⚠️ **HIGH**
- **1.2.5** - Kubelet certificate authority configured ⚠️ **HIGH**

### Kubernetes RBAC and Service Accounts
- **5.1.1** - Cluster-admin role usage minimized 🔶 **MEDIUM**
- **5.1.3** - Wildcard use in Roles minimized 🔶 **MEDIUM**

### Kubernetes Pod Security Policies
- **5.2.2** - Host PID namespace sharing disabled ⚠️ **HIGH**
- **5.2.3** - Host IPC namespace sharing disabled ⚠️ **HIGH**
- **5.2.4** - Host network namespace sharing disabled ⚠️ **HIGH**
- **5.2.5** - Privilege escalation disabled ⚠️ **HIGH**

### Kubernetes Network Policies
- **5.3.2** - Network policies defined for all namespaces 🔶 **MEDIUM**
- **5.7.4** - Default namespace usage minimized 🔷 **LOW**

## 💻 Basic Usage

```bash
cd scripts

# AWS CIS Checks
# List all available AWS controls
python3 cis_checker.py list

# Check critical AWS controls
python3 cis_checker.py check --controls "1.12,5.2"

# Generate JSON report for AWS
python3 cis_checker.py check --format json --output ../reports/aws-compliance.json

# Kubernetes CIS Checks
# List all available Kubernetes controls
python3 k8s_cis_checker.py list

# Check Kubernetes RBAC and pod security
python3 k8s_cis_checker.py check --controls "5.1.1,5.2.2,5.2.3"

# Generate JSON report for Kubernetes
python3 k8s_cis_checker.py check --format json --output ../reports/k8s-compliance.json

# Unified Checker (Both Platforms)
# Check AWS and Kubernetes from single interface
python3 unified_cis_checker.py aws check --controls "1.12,5.2"
python3 unified_cis_checker.py k8s check --controls "5.1.1,5.2.2"

# Use automation script for AWS
./run_cis_checks.sh --controls "1.12,3.1,5.2"
```

> **📘 For detailed usage examples, automation, and advanced features:** See [docs/USAGE.md](docs/USAGE.md)

## 🗂️ Getting Started

**New users:** Start with the [Complete Walkthrough](docs/WALKTHROUGH.md) for step-by-step instructions.

**Experienced users:** Check the [Usage Guide](docs/USAGE.md) for comprehensive documentation.

**Want to test?** Deploy the [Test Infrastructure](tf/README.md) to validate the tool.

## � Documentation

- **[📋 WALKTHROUGH](docs/WALKTHROUGH.md)** - Complete step-by-step setup guide
- **[📘 USAGE](docs/USAGE.md)** - Detailed usage instructions and examples  
- **[🧪 TEST INFRASTRUCTURE](tf/README.md)** - Terraform test environment
- **[📚 DOCS INDEX](DOCS.md)** - Documentation navigation guide

## 📄 License

This project is licensed under the MIT License.

---

**Ready to start?** → [Complete Walkthrough](docs/WALKTHROUGH.md) | [Usage Guide](docs/USAGE.md)
