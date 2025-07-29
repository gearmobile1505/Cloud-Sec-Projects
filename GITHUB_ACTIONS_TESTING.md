# GitHub Actions Testing Guide

This guide provides step-by-step instructions to test all the GitHub Actions workflows for the CIS Benchmark Checker project.

## 🎯 Testing Overview

We'll test the following workflows:
1. **Security and Lint** - Automated code quality and security scanning
2. **CIS Compliance Check** - Compliance monitoring workflows
3. **Deploy and Test Infrastructure** - Infrastructure deployment automation

## 🔧 Prerequisites

### 1. GitHub Repository Setup
- [ ] Fork or have admin access to the repository
- [ ] Ensure you're on the `github-actions-testing` branch
- [ ] Have GitHub Actions enabled in repository settings

### 2. AWS Account Setup (for infrastructure tests)
- [ ] AWS account with appropriate permissions
- [ ] AWS CLI configured locally for verification
- [ ] Decide between OIDC or Access Key authentication

### 3. Optional Integrations
- [ ] Slack workspace and webhook URL (for notifications)
- [ ] Email notifications configured

## 📋 Test Plan

### Phase 1: Basic Workflow Validation ✅

#### Test 1.1: Security and Lint Workflow
**Objective:** Verify code quality and security scanning works

**Steps:**
1. **Trigger the workflow:**
   ```bash
   # Method 1: Push to trigger automatically
   git add .
   git commit -m "test: trigger security and lint workflow"
   git push origin github-actions-testing
   
   # Method 2: Create a PR to main branch
   # This will trigger the workflow on pull_request event
   ```

2. **Monitor the workflow:**
   - Go to **Actions** tab in GitHub
   - Look for "Security Scan and Lint" workflow
   - Watch all 4 jobs run:
     - ✅ Security Scanning
     - ✅ Terraform Validation  
     - ✅ Shell Script Validation
     - ✅ Python Code Quality

3. **Expected Results:**
   ```
   ✅ Bandit finds Python security issues (if any)
   ✅ Safety checks dependencies for vulnerabilities
   ✅ Checkov scans Terraform for misconfigurations
   ✅ TruffleHog scans for secrets
   ✅ Terraform files validate successfully
   ✅ Shell scripts pass ShellCheck
   ✅ Python code quality checks run
   ✅ Security reports uploaded as artifacts
   ```

4. **Verification:**
   - Download artifacts from the workflow run
   - Check `security-reports-{run_number}` contains:
     - `bandit-report.json`
     - `checkov-report.json`
   - Review any findings in the reports

**Expected Issues (these are normal):**
- Some Python linting warnings (Black formatting, flake8 style)
- Checkov may flag intentionally insecure test configurations
- Bandit may flag test code with hardcoded values

---

### Phase 2: GitHub Secrets Setup 🔐

**Before testing compliance and infrastructure workflows, set up required secrets:**

#### Test 2.1: Configure AWS Authentication

**Option A: Access Keys (Simpler)**
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   ```
   AWS_ACCESS_KEY_ID = AKIA...
   AWS_SECRET_ACCESS_KEY = your-secret-key
   ```

**Option B: OIDC (More Secure)**
1. Create an OIDC provider in AWS IAM
2. Create a role that GitHub can assume
3. Add secret:
   ```
   AWS_ROLE_ARN = arn:aws:iam::123456789012:role/GitHubActionsRole
   ```

#### Test 2.2: Optional Secrets
```
EKS_CLUSTER_NAME = your-existing-cluster-name (optional)
SLACK_WEBHOOK = https://hooks.slack.com/services/... (optional)
```

---

### Phase 3: CIS Compliance Testing 🛡️

#### Test 3.1: Manual Compliance Check
**Objective:** Test compliance checking against existing AWS resources

**Steps:**
1. **Trigger manually:**
   - Go to **Actions** → **CIS Benchmark Compliance Check**
   - Click **Run workflow**
   - Select:
     - `Branch: github-actions-testing`
     - `Environment: dev`
     - `Controls: (leave empty for all)`
     - `Send Slack notification: true` (if configured)

2. **Monitor execution:**
   ```
   ✅ AWS credentials configure successfully
   ✅ Python dependencies install
   ✅ CIS AWS compliance checks run
   ✅ Kubernetes compliance checks run (if EKS available)
   ✅ Results uploaded as artifacts
   ✅ Summary posted to workflow
   ```

3. **Expected Results:**
   - Workflow completes (may have compliance failures - that's normal!)
   - Artifacts contain:
     - `aws-cis-results-{run_number}.json`
     - `k8s-cis-results-{run_number}.json` (if EKS available)
   - GitHub Step Summary shows compliance status
   - Slack notification sent (if configured)

#### Test 3.2: PR Comment Integration
**Steps:**
1. **Create a test PR:**
   ```bash
   # Make a small change to trigger workflow
   echo "# Test change" >> test-change.md
   git add test-change.md
   git commit -m "test: trigger PR compliance check"
   git push origin github-actions-testing
   ```

2. **Create PR:**
   - Go to GitHub and create PR from `github-actions-testing` to `main`
   - Watch for automatic workflow trigger

3. **Expected Results:**
   - Compliance check runs automatically
   - Results posted as PR comment
   - Security scan results also appear

---

### Phase 4: Infrastructure Deployment Testing 🏗️

**⚠️ WARNING: This creates real AWS resources that cost money!**

#### Test 4.1: Development Infrastructure Deployment
**Objective:** Test full infrastructure deployment and testing cycle

**Steps:**
1. **Deploy infrastructure:**
   - Go to **Actions** → **Deploy and Test CIS Infrastructure**
   - Click **Run workflow**
   - Select:
     - `Branch: github-actions-testing`
     - `Environment: dev`
     - `Action: deploy`
     - `Create non-compliant resources: true`

2. **Monitor deployment (~15-20 minutes):**
   ```
   ✅ Terraform initializes successfully
   ✅ Terraform plan shows resources to create
   ✅ Infrastructure deploys (VPC, EKS, Security Groups, etc.)
   ✅ Compliance tests run against new infrastructure
   ✅ Test results uploaded
   ✅ Infrastructure automatically destroyed (for dev environment)
   ```

3. **Expected Results:**
   - Complete infrastructure deployment
   - Compliance tests find intentional violations
   - Test artifacts contain detailed results
   - Infrastructure cleanly destroyed

#### Test 4.2: Test-Only Mode
**Steps:**
1. **Run tests against existing infrastructure:**
   - **Actions** → **Deploy and Test CIS Infrastructure**
   - Select: `Action: test-only`
   - This runs compliance tests without deploying new infrastructure

---

### Phase 5: Automated Triggers Testing 🤖

#### Test 5.1: Scheduled Workflow (Optional)
**Note:** Scheduled workflows only run on the default branch (main)

**Steps:**
1. **Merge to main to test schedule:**
   ```bash
   # After all tests pass, merge the PR
   # Wait for scheduled run (daily at 6 AM UTC)
   ```

2. **Or modify schedule for testing:**
   ```yaml
   # In .github/workflows/cis-compliance-check.yml
   schedule:
     - cron: '*/15 * * * *'  # Every 15 minutes for testing
   ```

#### Test 5.2: Issue Creation on Failure
**Steps:**
1. **Force a failure:**
   - Temporarily break a compliance check
   - Let scheduled workflow run
   - Verify issue gets created automatically

---

## 🧪 Test Results Checklist

### Security and Lint Workflow ✅
- [ ] All 4 jobs complete successfully
- [ ] Security reports generated and uploaded
- [ ] No critical vulnerabilities in legitimate code
- [ ] Terraform configurations validate
- [ ] Shell scripts pass ShellCheck

### CIS Compliance Workflow ✅
- [ ] AWS authentication works
- [ ] Compliance checks execute successfully
- [ ] JSON and HTML reports generated
- [ ] PR comments appear with results
- [ ] Slack notifications work (if configured)
- [ ] Issues created for scheduled failures

### Infrastructure Deployment ✅
- [ ] Terraform deployment succeeds
- [ ] EKS cluster deploys and becomes ready
- [ ] Compliance tests run against new infrastructure
- [ ] Infrastructure destruction completes cleanly
- [ ] No resources left behind in AWS
- [ ] Cost impact understood and acceptable

## 🔍 Troubleshooting Common Issues

### AWS Authentication Fails
```bash
# Check secrets are set correctly
# Verify IAM permissions
# Test locally first:
aws sts get-caller-identity
```

### Terraform Deployment Fails
```bash
# Common issues:
# - Resource limits (VPC limit, EIP limit)
# - Insufficient IAM permissions
# - Region availability zones
# - Naming conflicts
```

### Compliance Tests Fail
```bash
# Normal for test infrastructure with intentional violations
# Review the specific failed checks
# Verify tools can access AWS resources
```

### Workflow Doesn't Trigger
```bash
# Check:
# - Branch protection rules
# - Workflow file syntax (YAML validation)
# - Repository settings (Actions enabled)
# - File paths in trigger conditions
```

## 📊 Monitoring and Validation

### GitHub Actions Insights
- Go to **Insights** → **Actions** to see:
  - Workflow run frequency
  - Success/failure rates
  - Performance metrics

### AWS Cost Monitoring
- Monitor AWS billing during infrastructure tests
- Expected costs:
  - EKS cluster: ~$0.10/hour
  - NAT Gateway: ~$0.045/hour
  - Other resources: minimal

### Artifact Review
Download and review all artifacts:
- Security scan results
- Compliance reports (JSON/HTML)
- Terraform plans and outputs

## 🎯 Success Criteria

### Phase 1 Success ✅
- [ ] All security and lint jobs pass
- [ ] No blocking security vulnerabilities
- [ ] Code quality issues identified and documented

### Phase 2 Success ✅
- [ ] AWS authentication configured
- [ ] Secrets properly secured
- [ ] Optional integrations working

### Phase 3 Success ✅
- [ ] Compliance checks run successfully
- [ ] Results properly formatted and stored
- [ ] PR integration working
- [ ] Notifications functioning

### Phase 4 Success ✅
- [ ] Infrastructure deploys without errors
- [ ] Compliance tests execute on new infrastructure
- [ ] Cleanup completes successfully
- [ ] No AWS resources left behind

### Overall Success ✅
- [ ] All workflows operational
- [ ] Documentation accurate
- [ ] Team trained on usage
- [ ] Production deployment plan ready

## 🚀 Next Steps After Testing

### 1. Production Deployment
```bash
# Merge to main branch
git checkout main
git merge github-actions-testing
git push origin main

# Set up branch protection rules
# Configure required status checks
```

### 2. Team Onboarding
- Share this testing guide with team
- Train on workflow usage and troubleshooting
- Establish monitoring procedures

### 3. Ongoing Maintenance
- Regular review of security scan results
- Update dependencies and tools
- Monitor AWS costs and optimize as needed
- Review and update compliance controls

---

## 📞 Support and Resources

### Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS IAM for GitHub Actions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)

### Troubleshooting
- Check workflow logs in GitHub Actions tab
- Review AWS CloudTrail for permission issues
- Use GitHub Discussions for community support

### Emergency Procedures
- **Stuck Infrastructure:** Manual cleanup via AWS Console
- **Cost Runaway:** AWS Budget alerts and manual resource termination
- **Security Incident:** Immediate secret rotation and access review

Happy testing! 🎉 This comprehensive automation will significantly improve your security posture and compliance monitoring capabilities.
