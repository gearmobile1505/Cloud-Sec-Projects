# GitHub Actions Setup for CIS Benchmark Checker

This document explains how to set up GitHub Actions to automate your CIS benchmark checking, infrastructure deployment, and security scanning.

## 🚀 Overview

The GitHub Actions workflows automate:

1. **CIS Compliance Checking** - Automated AWS and Kubernetes compliance scans
2. **Infrastructure Deployment** - Deploy/test/destroy infrastructure automatically  
3. **Security Scanning** - Code security, dependency checking, secrets detection
4. **Code Quality** - Linting for Python, Terraform, and Shell scripts

## 🔧 Setup Requirements

### 1. AWS Authentication

Choose one of these methods:

#### Option A: OIDC (Recommended)
```bash
# Create an OIDC provider and role in AWS
# This allows GitHub Actions to assume AWS roles securely
```

#### Option B: Access Keys
```bash
# Create access keys and store in GitHub secrets
```

### 2. Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

```bash
# AWS Authentication (choose one method)
AWS_ROLE_ARN=arn:aws:iam::123456789012:role/GitHubActionsRole  # For OIDC
# OR
AWS_ACCESS_KEY_ID=AKIA...                                       # For access keys
AWS_SECRET_ACCESS_KEY=...                                       # For access keys

# EKS Configuration
EKS_CLUSTER_NAME=your-eks-cluster-name                         # Optional

# Notifications (optional)
SLACK_WEBHOOK=https://hooks.slack.com/services/...             # For Slack notifications
```

### 3. AWS IAM Permissions

The GitHub Actions role/user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity",
        "ec2:Describe*",
        "iam:Get*",
        "iam:List*",
        "cloudtrail:Describe*",
        "cloudtrail:GetTrail*",
        "config:Describe*",
        "config:Get*",
        "s3:GetBucket*",
        "s3:ListBucket*",
        "kms:Describe*",
        "kms:List*",
        "logs:Describe*",
        "eks:Describe*",
        "eks:List*"
      ],
      "Resource": "*"
    }
  ]
}
```

For infrastructure deployment, additional permissions needed:
```json
{
  "Effect": "Allow", 
  "Action": [
    "ec2:*",
    "iam:*",
    "eks:*",
    "cloudtrail:*",
    "config:*",
    "s3:*",
    "kms:*",
    "logs:*"
  ],
  "Resource": "*"
}
```

## 📋 Workflow Files

### 1. CIS Compliance Check (`.github/workflows/cis-compliance-check.yml`)

**Triggers:**
- Push to main branch
- Pull requests  
- Manual trigger with options
- Daily schedule (6 AM UTC)

**Features:**
- Runs AWS CIS Foundations Benchmark checks
- Runs Kubernetes CIS Benchmark checks
- Generates JSON and HTML reports
- Comments on PRs with results
- Creates issues for scheduled failures
- Slack notifications

**Usage:**
```bash
# Manual trigger with options
# Go to Actions → CIS Benchmark Compliance Check → Run workflow
# Choose environment: dev/staging/prod
# Choose controls: specific or all
# Enable/disable Slack notifications
```

### 2. Deploy and Test Infrastructure (`.github/workflows/deploy-test-infrastructure.yml`)

**Triggers:**
- Manual trigger only

**Features:**
- Deploys complete test infrastructure with Terraform
- Runs comprehensive compliance tests
- Automatically destroys dev environments
- Uploads test results and Terraform outputs

**Usage:**
```bash
# Go to Actions → Deploy and Test CIS Infrastructure → Run workflow
# Choose: deploy, test-only, or destroy
# Choose environment: dev or staging
# Choose whether to create non-compliant resources
```

### 3. Security and Lint (`.github/workflows/security-and-lint.yml`)

**Triggers:**
- Push to main/develop
- Pull requests
- Weekly schedule (Monday 2 AM UTC)

**Features:**
- Bandit (Python security analysis)
- Safety (dependency vulnerability checking)
- Checkov (Infrastructure security scanning)
- TruffleHog (secrets detection)
- Terraform validation and linting
- Shell script linting (ShellCheck)
- Python code quality (Black, flake8, pylint)

## 🎯 Usage Examples

### Daily Compliance Monitoring

The workflows automatically:
1. Run daily compliance checks at 6 AM UTC
2. Create GitHub issues if failures detected
3. Send Slack notifications (if configured)

### Pull Request Validation

On every PR:
1. Security scanning runs automatically
2. Code quality checks run
3. CIS compliance results posted as PR comments

### Manual Testing

```bash
# Deploy test infrastructure
Actions → Deploy and Test CIS Infrastructure → Run workflow
- Environment: dev
- Action: deploy  
- Create non-compliant: true

# Run compliance tests on existing infrastructure
Actions → CIS Benchmark Compliance Check → Run workflow
- Environment: dev
- Controls: all
- Slack notification: true

# Destroy test infrastructure
Actions → Deploy and Test CIS Infrastructure → Run workflow
- Environment: dev
- Action: destroy
```

## 📊 Reports and Artifacts

Each workflow generates artifacts:

### CIS Compliance Reports
- `aws-cis-results-{run_number}.json`
- `aws-cis-report-{run_number}.html`
- `k8s-cis-results-{run_number}.json`

### Security Reports
- `bandit-report.json` (Python security)
- `checkov-report.json` (Infrastructure security)

### Infrastructure Reports
- `terraform-plan-{run_number}` (Terraform plan)
- `terraform-outputs-{run_number}.json` (Resource details)

## 🔔 Notifications

### Slack Integration
1. Create a Slack webhook URL
2. Add to GitHub secrets as `SLACK_WEBHOOK`
3. Notifications sent for:
   - Compliance check failures
   - Infrastructure deployment status
   - Security scan results

### GitHub Issues
Automatic issue creation for:
- Daily compliance check failures
- Critical security findings
- Infrastructure deployment failures

## 🛠️ Customization

### Adding New Compliance Checks

Edit `.github/workflows/cis-compliance-check.yml`:
```yaml
- name: Run Custom Compliance Check
  run: |
    cd cis-benchmark-checker/scripts
    python3 your_custom_checker.py --output json > ../custom_results.json
```

### Modifying Infrastructure

Edit `.github/workflows/deploy-test-infrastructure.yml`:
```yaml
- name: Create terraform.tfvars
  run: |
    cat > terraform.tfvars << EOF
    # Add your custom variables here
    custom_setting = "value"
    EOF
```

### Adding Security Tools

Edit `.github/workflows/security-and-lint.yml`:
```yaml
- name: Run Custom Security Tool
  run: |
    # Install and run your tool
    pip install your-security-tool
    your-security-tool scan .
```

## 📚 Best Practices

1. **Use OIDC** for AWS authentication when possible
2. **Test workflows** in a development branch first
3. **Monitor costs** - GitHub Actions and AWS resources incur charges
4. **Review artifacts** regularly and clean up old ones
5. **Keep secrets secure** - rotate credentials regularly
6. **Use branch protection** with required status checks

## 🔍 Troubleshooting

### Common Issues

**AWS Authentication Fails:**
```bash
# Check secrets are set correctly
# Verify IAM permissions
# Test AWS CLI access locally first
```

**Terraform Deployment Fails:**
```bash
# Check terraform.tfvars generation
# Verify AWS resource limits
# Review Terraform plan before apply
```

**Compliance Tests Fail:**
```bash
# Check if infrastructure is fully deployed
# Verify EKS cluster is ready
# Review compliance tool outputs
```

### Debug Mode

Add to workflow for debugging:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## 📈 Monitoring

Monitor your workflows:
1. **Actions tab** - View run history and logs
2. **Insights** - Analyze workflow performance
3. **Security tab** - Review security alerts
4. **Issues** - Track compliance failures

## 💡 Advanced Features

### Matrix Builds
Test multiple environments:
```yaml
strategy:
  matrix:
    environment: [dev, staging, prod]
    region: [us-east-1, us-west-2]
```

### Conditional Execution
```yaml
if: github.event_name == 'schedule' && github.ref == 'refs/heads/main'
```

### Caching
Speed up workflows:
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.terraform
    key: terraform-${{ hashFiles('**/*.tf') }}
```

This automation setup transforms your manual CIS benchmark checking into a fully automated, continuous compliance monitoring system! 🚀
