# CIS Benchmark Checker

Automated CIS compliance testing for AWS and Kubernetes with GitHub Actions workflows and test infrastructure.

## ✨ Features

- AWS CIS Benchmark checks (IAM, EC2, CloudTrail, etc.)
- Kubernetes CIS Benchmark checks for EKS clusters
- Automated test infrastructure deployment via Terraform
- GitHub Actions workflows for CI/CD integration
- JSON/HTML report generation

## 🚀 Quick Start

### Method 1: GitHub Actions (Recommended)

1. **Fork the repository**
2. **Configure GitHub Secrets:**
   ```
   AWS_ACCESS_KEY_ID: Your AWS access key
   AWS_SECRET_ACCESS_KEY: Your AWS secret key
   ```
3. **Run the workflow:**
   - Go to Actions → "Deploy and Test CIS Infrastructure"
   - Click "Run workflow"
   - Infrastructure deploys, CIS checks run, reports generated

### Method 2: Local Usage

```bash
# Install dependencies
pip install -r requirements.txt

# Configure AWS
aws configure

# Run checks
python3 cis_checker.py check --format json
python3 k8s_cis_checker.py --cluster-name your-cluster-name
```

## 🏗️ Test Infrastructure

The GitHub Actions workflow deploys:
- EKS Cluster (v1.31) with worker nodes
- VPC with public/private subnets
- Security groups with intentional misconfigurations
- IAM roles and policies for testing
- Kubernetes manifests for CIS testing

**Cost:** ~$0.50-1.00/hour while running

## 🔧 Custom Infrastructure

To use with your own infrastructure:

1. **AWS Environment:**
   ```bash
   export AWS_PROFILE=your-profile
   python3 cis_checker.py check --regions us-east-1,us-west-2
   ```

2. **Existing EKS Cluster:**
   ```bash
   aws eks update-kubeconfig --name your-cluster-name
   python3 k8s_cis_checker.py --cluster-name your-cluster-name
   ```

3. **Custom Terraform:**
   - Modify `tf/terraform.tfvars` with your values
   - Update `tf/backend.tf` with your S3 bucket
   - Deploy: `terraform apply`

## 📊 Report Formats

- **JSON:** `--format json` (machine readable)
- **HTML:** `--format html` (visual reports)
- **STDOUT:** Default console output

## 🧹 Cleanup

GitHub Actions automatically destroys test infrastructure after checks complete. For manual cleanup:

```bash
cd tf/
terraform destroy -auto-approve
```

## 🔧 Configuration

Key files:
- `scripts/cis_checker.py` - AWS CIS checks
- `scripts/k8s_cis_checker.py` - Kubernetes CIS checks  
- `tf/` - Terraform infrastructure
- `.github/workflows/` - Automation workflows

## ⚠️ Security Note

Test infrastructure includes intentionally vulnerable configurations for compliance validation. Always use in isolated environments.
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
