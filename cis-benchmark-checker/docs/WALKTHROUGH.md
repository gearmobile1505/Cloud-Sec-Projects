# 🚀 CIS Benchmark Checker - Complete Step-by-Step Walkthrough

This is your **complete guide** from setup to running CIS compliance checks. Follow these steps in order for a successful deployment and testing experience.

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- [ ] AWS Account with appropriate permissions
- [ ] Python 3.7+ installed
- [ ] AWS CLI installed and configured
- [ ] Git (optional, for cloning)
- [ ] Terraform (optional, for test infrastructure)

---

## 🏁 **PHASE 1: Initial Setup**

### Step 1: Verify Prerequisites
```bash
# Check Python version (should be 3.7+)
python3 --version

# Check AWS CLI
aws --version

# Verify AWS credentials
aws sts get-caller-identity
```

### Step 2: Navigate to Project Directory
```bash
cd ./Cloud-Sec-Projects/cis-benchmark-checker
```

### Step 3: Install Python Dependencies
```bash
# Install required packages
pip install -r requirements.txt

# Verify installation
python3 -c "import boto3; print('✓ boto3 installed successfully')"
```

### Step 4: Configure AWS Credentials (if not done)
```bash
# Option A: Use AWS CLI configuration
aws configure

# Option B: Set environment variables
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_DEFAULT_REGION=us-east-1

# Option C: Use AWS profiles
aws configure --profile production
```

---

## 🧪 **PHASE 2: Test Infrastructure (Optional but Recommended)**

### Step 5: Deploy Test Infrastructure
```bash
# Navigate to terraform directory
cd tf

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration (optional - defaults work fine)
# nano terraform.tfvars

# Initialize Terraform
./deploy.sh init

# Deploy infrastructure
./deploy.sh apply
# Type 'yes' when prompted
```

**What this creates:**
- ✅ Compliant AWS resources (CloudTrail, VPC Flow Logs, etc.)
- ❌ Non-compliant resources (open security groups for testing)
- 📊 Complete test environment for all CIS controls

---

## 🔍 **PHASE 3: Basic CIS Compliance Checks**

### Step 6: Return to Main Directory
```bash
cd ..
```

### Step 7: List Available Controls
```bash
# See all available CIS controls
python3 cis_checker.py list
```

### Step 8: Run First Compliance Check
```bash
# Test critical controls
python3 cis_checker.py check --controls "1.12,5.2" --format text

# Expected output:
# ✓ or ✗ for each control with detailed explanation
```

### Step 9: Generate JSON Report
```bash
# Create detailed JSON report
python3 cis_checker.py check --controls "1.12,3.1,5.2,5.5" --format json --output first_check_report.json

# View the report
cat first_check_report.json | jq '.'
```

---

## 🤖 **PHASE 4: Automation Script Testing**

### Step 10: Test Automation Script
```bash
# Run automation script with dry-run
./run_cis_checks.sh --controls "1.12,3.1,5.2" --dry-run

# Run actual check
./run_cis_checks.sh --controls "1.12,3.1,5.2"
```

### Step 11: Full Compliance Scan
```bash
# Run comprehensive check on all implemented controls
./run_cis_checks.sh

# Check the generated reports
ls -la reports/
```

---

## 📊 **PHASE 5: Advanced Testing**

### Step 12: Test Against Deployed Infrastructure
```bash
# If you deployed test infrastructure in Phase 2
cd tf
./deploy.sh test
cd ..
```

### Step 13: Test Extended Controls
```bash
# Run extended CIS checker
python3 extended_cis.py check --controls "1.5,3.8,5.5" --format text
```

### Step 14: Multi-Format Reports
```bash
# Generate different report formats
python3 cis_checker.py check --format json --output compliance_report.json
python3 cis_checker.py check --format text --output compliance_report.txt

# View reports
cat compliance_report.txt
jq '.summary' compliance_report.json
```

---

## 🔧 **PHASE 6: Production Setup (Optional)**

### Step 15: Configure for Production Use
```bash
# Copy and customize configuration
cp config.yaml config-production.yaml
# Edit with your production settings

# Test with production profile
python3 cis_checker.py check --profile production --region us-west-2
```

### Step 16: Setup Scheduled Automation
```bash
# Test S3 upload and SNS notifications (replace with your resources)
./run_cis_checks.sh \
  --s3-bucket your-compliance-bucket \
  --sns-topic arn:aws:sns:us-east-1:123456789:compliance-alerts \
  --dry-run
```

### Step 17: Deploy Lambda Function (Optional)
```bash
# Package Lambda function
zip -r lambda_function.zip lambda_function.py

# Deploy using AWS CLI or CloudFormation
# See lambda_function.py for CloudFormation template
```

---

## 🧹 **PHASE 7: Cleanup**

### Step 18: Clean Up Test Infrastructure
```bash
# Remove test infrastructure to avoid charges
cd tf
./deploy.sh destroy
# Type 'yes' when prompted

cd ..
```

### Step 19: Clean Up Reports (Optional)
```bash
# Clean up test reports
rm -rf reports/
mkdir reports  # Recreate empty directory
```

---

## ✅ **Verification Checklist**

After completing all phases, you should have:

- [ ] **Successfully installed** all dependencies
- [ ] **Configured AWS credentials** properly
- [ ] **Deployed test infrastructure** (if chosen)
- [ ] **Run basic CIS checks** with both success and failure results
- [ ] **Generated reports** in multiple formats
- [ ] **Tested automation script** with various options
- [ ] **Verified compliance detection** against known good/bad resources
- [ ] **Cleaned up test resources** to avoid unnecessary charges

---

## 🎯 **Expected Results Summary**

### What Should Work (✅):
- **CIS 3.1**: CloudTrail enabled in all regions
- **CIS 3.2**: CloudTrail log file validation enabled  
- **CIS 3.4**: CloudTrail integrated with CloudWatch
- **CIS 3.7**: CloudTrail logs encrypted with KMS
- **CIS 5.3**: Default security group restricts all traffic
- **CIS 5.5**: VPC flow logging enabled

### What Should Fail (❌) - If Test Infrastructure Deployed:
- **CIS 5.2**: Security groups allow ingress from 0.0.0.0/0 to admin ports

### Sample Success Output:
```
CIS Benchmark Compliance Check Results
=====================================
✓ CIS 3.1: CloudTrail enabled in all regions - COMPLIANT
✓ CIS 5.5: VPC flow logging enabled - COMPLIANT  
✗ CIS 5.2: Security groups allow unrestricted access - NON_COMPLIANT

Summary: 2 compliant, 1 non-compliant
```

---

## 🆘 **Troubleshooting Quick Fixes**

### Issue: AWS Credentials Not Found
```bash
aws configure list
aws sts get-caller-identity
```

### Issue: Python Dependencies Missing
```bash
pip install --upgrade boto3 PyYAML argparse
```

### Issue: Permission Denied
```bash
# Check IAM permissions - you need read access to:
# EC2, IAM, CloudTrail, Config, S3, KMS, Logs
```

### Issue: No Resources Found
```bash
# Verify you're checking the correct region
python3 cis_checker.py check --region us-east-1
```

---

## 📞 **Getting Help**

If you encounter issues:

1. **Check the logs**: Enable verbose mode with `--verbose`
2. **Review documentation**: Check `README.md` and `USAGE.md`
3. **Verify permissions**: Ensure IAM permissions are correct
4. **Test connectivity**: Run `aws sts get-caller-identity`
5. **Check region**: Some resources are region-specific

---

## 🎉 **Success!**

You now have a **fully functional CIS Benchmark Checker** with:
- ✅ **Complete compliance checking** for AWS environments
- 🤖 **Automated scanning and reporting**
- 📊 **Multiple output formats** (JSON, text, HTML)
- 🔧 **Production-ready automation scripts**
- 🧪 **Test infrastructure** for validation
- 📋 **Comprehensive documentation** and examples

**Next Steps**: 
- Customize for your environment
- Set up scheduled compliance scans
- Integrate with your monitoring systems
- Expand to multi-account scenarios

---

*This walkthrough ensures you have everything needed to successfully deploy and use the CIS Benchmark Checker in your AWS environment! 🚀*
