# CIS Benchmark Test Infrastructure

Terraform configuration for AWS and EKS test infrastructure with intentional CIS compliance violations for testing.

## 🚀 GitHub Actions Deployment

This infrastructure is automatically deployed via GitHub Actions workflow. No manual Terraform commands needed.

1. **Fork the repository**
2. **Add GitHub Secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. **Run workflow:** "Deploy and Test CIS Infrastructure"

## �️ Infrastructure Deployed

### AWS Resources
- **EKS Cluster** (v1.31) with worker nodes  
- **VPC** with public/private subnets and NAT Gateway
- **Security Groups** with intentional misconfigurations
- **CloudTrail** with CloudWatch integration
- **IAM Roles** for testing permissions

### Kubernetes Resources  
- Insecure workloads for CIS testing
- RBAC configurations
- Network policy violations

## 💰 Cost

Approximately $0.50-1.00/hour while running. GitHub Actions automatically destroys infrastructure after testing.

## 🔧 Manual Deployment

For custom deployments:

```bash
# Configure backend
cp backend.tf.example backend.tf
# Edit backend.tf with your S3 bucket

# Deploy
terraform init
terraform plan
terraform apply

# Cleanup
terraform destroy -auto-approve
```

## ⚠️ Security Note

Contains intentionally vulnerable configurations for CIS compliance testing. Use only in isolated test environments.
- ✅ **S3 delivery channel** for configuration history

### IAM (CIS 1.x)
- ✅ **Password policy** compliant with CIS requirements (1.5-1.11)
- ✅ **Test IAM users** with access keys for testing
- ❌ **Potentially old access keys** for testing key rotation checks

### S3 Buckets
- ✅ **Private S3 buckets** with proper access controls
- ❌ **Public S3 bucket** for testing public access detection

### EKS Cluster (Kubernetes CIS Testing)
- ❌ **EKS Cluster** with public endpoint access (CIS violation)
- ❌ **Missing encryption** configuration (CIS violation)
- ❌ **Missing audit logging** (CIS violation)
- ❌ **Insecure Security Groups** with 0.0.0.0/0 access
- ❌ **Overly permissive IAM policies** with wildcard permissions

### Kubernetes Test Manifests
- ❌ **Pods with host namespace sharing** (CIS 5.2.2, 5.2.3, 5.2.4 violations)
- ❌ **Containers with privilege escalation** (CIS 5.2.5 violations)
- ❌ **Workloads in default namespace** (CIS 5.7.4 violations)
- ❌ **Overly permissive RBAC** with wildcards (CIS 5.1.3 violations)
- ❌ **Excessive cluster-admin usage** (CIS 5.1.1 violations)
- ❌ **Namespaces without network policies** (CIS 5.3.2 violations)

## 🚀 Quick Start (Tested Configuration)

```bash
# 1. Update your IP address in kubernetes.tf (REQUIRED!)
curl ifconfig.me  # Get your IP
# Edit kubernetes.tf and replace YOUR_IP_ADDRESS/32 with your actual IP

# 2. Initialize and plan
terraform init
terraform plan

# 3. Deploy infrastructure
terraform apply

# 4. Connect to EKS cluster
aws eks update-kubeconfig --region us-east-1 --name cisk8stest-eks-cluster
kubectl get nodes

# 5. Test CIS compliance
cd ../scripts
python3 unified_cis_checker.py kubernetes check
python3 cis_checker.py check --controls "1.3,1.4"

# 6. Cleanup when done
terraform destroy
```

## 📊 Expected Results

When you run the CIS checker against this infrastructure, you should see:

### ✅ Compliant Controls
- **CIS 3.1** - CloudTrail enabled in all regions
- **CIS 3.2** - CloudTrail log file validation enabled
- **CIS 3.4** - CloudTrail integrated with CloudWatch Logs
- **CIS 3.7** - CloudTrail logs encrypted with KMS
- **CIS 3.8** - KMS key rotation enabled
- **CIS 5.3** - Default security group restricts all traffic
- **CIS 5.5** - VPC flow logging enabled

### ❌ Non-Compliant Controls (if enabled)
- **CIS 5.2** - Security groups allow ingress from 0.0.0.0/0 to admin ports
- **CIS 1.3/1.4** - Access keys potentially unused/old (time-dependent)

## 🔧 Configuration Options

### terraform.tfvars
```hcl
# Basic settings
aws_region   = "us-east-1"
environment  = "test"
project_name = "cis-benchmark-test"

# Feature flags
create_non_compliant_resources = true  # Create violation resources
enable_flow_logs              = true   # Enable VPC Flow Logs
enable_config                 = true   # Enable AWS Config

# Unique bucket name (optional)
cloudtrail_bucket_name = "your-unique-bucket-name"
```

### Key Variables

- **`create_non_compliant_resources`** - Set to `true` to create intentionally non-compliant resources for testing violations
- **`enable_flow_logs`** - Enable VPC Flow Logs (CIS 5.5)
- **`enable_config`** - Enable AWS Config service (CIS 3.5)
- **`cloudtrail_bucket_name`** - Custom bucket name (auto-generated if not specified)

## 💰 Cost Considerations

This test infrastructure will incur AWS charges:

- **VPC & Networking**: Minimal cost
- **CloudTrail**: ~$2/month for management events
- **VPC Flow Logs**: ~$0.50/GB of log data
- **AWS Config**: ~$2/month + $0.003/configuration item
- **S3 Storage**: Minimal for logs
- **KMS**: $1/month per key

**Estimated monthly cost: $5-15** depending on usage.

## 🧹 Cleanup

To avoid ongoing charges, destroy the infrastructure when testing is complete:

```bash
cd tf
terraform destroy
```

**Warning**: This will permanently delete all created resources and data.

## 🔍 Testing Scenarios

### Scenario 1: Basic Compliance Check
```bash
# Test core CIS controls
cd ../scripts
python3 cis_checker.py check --controls "1.12,3.1,5.2"
```

### Scenario 2: Full Infrastructure Scan
```bash
# Comprehensive check of all implemented controls
./run_cis_checks.sh
```

### Scenario 3: Violation Detection
```bash
# Ensure non-compliant resources are detected
python3 cis_checker.py check --controls "5.2" --format json | jq '.results[] | select(.status == "NON_COMPLIANT")'
```

### Scenario 4: Automation Testing
```bash
# Test automation script with S3 upload (requires S3 bucket)
./run_cis_checks.sh --s3-bucket your-reports-bucket --dry-run
```

## 📝 Validation Checklist

After deployment, verify:
- [ ] CloudTrail is logging to S3 and CloudWatch
- [ ] VPC Flow Logs are being generated
- [ ] Security groups contain the expected rules
- [ ] AWS Config is recording configuration changes
- [ ] KMS key rotation is enabled
- [ ] S3 buckets have correct public access settings

## 🐛 Troubleshooting

### Common Issues

1. **Bucket name conflicts**
   ```bash
   # Use a unique bucket name in terraform.tfvars
   cloudtrail_bucket_name = "your-unique-name-${random_id}"
   ```

2. **AWS Config permissions**
   ```bash
   # Ensure your AWS user has Config permissions
   aws iam list-attached-user-policies --user-name your-username
   ```

3. **Region-specific resources**
   ```bash
   # Some resources are region-specific
   terraform plan -var="aws_region=us-west-2"
   ```

## 🔗 Integration with CIS Checker

This infrastructure is designed to work seamlessly with the CIS Benchmark Checker:

```bash
# Test against the infrastructure
cd ../scripts
python3 cis_checker.py check --region us-east-1

# Use automation script
./run_cis_checks.sh --region us-east-1 --output-dir ../reports
```

## 📚 Additional Resources

- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Config Rules](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)
- [CloudTrail Best Practices](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/best-practices-security.html)

## 🔧 Recent Updates

- **EKS Version**: Updated to Kubernetes 1.31 for latest features and security patches
- **SSH Key Management**: Terraform now automatically generates SSH keys for EKS nodes
- **Enhanced Outputs**: Added comprehensive EKS cluster outputs for easier access
- **Provider Updates**: Added TLS provider for automatic SSH key generation
