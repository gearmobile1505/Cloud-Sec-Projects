# Kubernetes CIS Testing - Step-by-Step Guide

This guide provides complete step-by-step instructions for deploying Kubernetes test resources, running CIS compliance checks, and cleaning up resources.

## 📋 Prerequisites

### 1. System Requirements
- **Operating System**: Linux, macOS, or Windows with WSL
- **Python**: 3.7 or higher
- **Available Memory**: 4GB+ recommended for EKS cluster

### 2. Required Tools Installation

#### Install kubectl
```bash
# macOS
brew install kubectl

# Linux (Ubuntu/Debian)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows
choco install kubernetes-cli

# Verify installation
kubectl version --client
```

#### Install AWS CLI (for EKS)
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Windows
# Download and run AWS CLI MSI installer from aws.amazon.com

# Verify installation
aws --version
```

#### Install Terraform (for EKS deployment)
```bash
# macOS
brew install terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform version
```

### 3. Configure AWS Credentials
```bash
# Configure AWS credentials
aws configure

# Required information:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region (e.g., us-east-1)
# - Default output format (json)

# Verify credentials
aws sts get-caller-identity
```

### 4. Install Python Dependencies
```bash
# Navigate to project directory
cd /Users/marcaelissanders/Desktop/Cloud-Sec-Projects/cis-benchmark-checker

# Install Python dependencies
cd scripts
pip install -r requirements.txt

# Verify installation
python3 test_installation.py
```

---

## 🚀 Phase 1: Deploy EKS Test Infrastructure

### Step 1: Prepare Terraform Configuration
```bash
# Navigate to Terraform directory
cd ../tf

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars (use your preferred editor)
nano terraform.tfvars
```

#### Configure terraform.tfvars:
```hcl
# Basic settings
aws_region   = "us-east-1"
environment  = "test"
project_name = "cis-k8s-test"

# Enable EKS and violations
create_non_compliant_resources = true
enable_eks_cluster            = true
enable_flow_logs              = true
enable_config                 = true

# Unique bucket name (replace with your unique name)
cloudtrail_bucket_name = "your-unique-cis-test-bucket-12345"
```

### Step 2: Initialize and Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review planned infrastructure
terraform plan

# Deploy infrastructure (this will take 15-20 minutes)
terraform apply

# When prompted, type 'yes' to confirm
```

### Step 3: Configure kubectl for EKS
```bash
# Get EKS cluster name from Terraform output
export CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
export AWS_REGION=$(terraform output -raw region)

# Update kubeconfig for EKS cluster
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster connection
kubectl cluster-info
kubectl get nodes
```

**Expected Output:**
```
Kubernetes control plane is running at https://xxx.eks.us-east-1.amazonaws.com
CoreDNS is running at https://xxx.eks.us-east-1.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-xxx.ec2.internal    Ready    <none>   5m    v1.28.x
ip-10-0-2-xxx.ec2.internal    Ready    <none>   5m    v1.28.x
```

---

## 🧪 Phase 2: Deploy Kubernetes Test Resources

### Step 4: Deploy Insecure Kubernetes Manifests
```bash
# Deploy test resources with CIS violations
./k8s-deploy.sh deploy
```

**Expected Output:**
```
✅ Successfully connected to Kubernetes cluster
✅ Deploying insecure workloads with CIS violations...
pod/insecure-pod created
deployment.apps/insecure-deployment created
service/insecure-service created
✅ Insecure workloads deployed

✅ Deploying insecure RBAC configurations...
clusterrole.rbac.authorization.k8s.io/overly-permissive-role created
clusterrolebinding.rbac.authorization.k8s.io/overly-permissive-binding created
✅ Insecure RBAC configurations deployed

✅ Deploying namespaces without network policies...
namespace/unprotected-namespace created
pod/unprotected-pod created
✅ Unprotected namespaces deployed
```

### Step 5: Verify Resource Deployment
```bash
# Check deployed resources
kubectl get pods --all-namespaces
kubectl get namespaces
kubectl get clusterroles | grep -E "(overly-permissive|wildcard)"
kubectl get clusterrolebindings | grep -E "(overly-permissive|excessive)"
```

**Expected Output:**
```
NAMESPACE                     NAME                READY   STATUS    RESTARTS   AGE
default                       insecure-pod        1/1     Running   0          2m
default                       insecure-deployment-xxx   1/1     Running   0          2m
unprotected-namespace         unprotected-pod     1/1     Running   0          2m
another-unprotected-namespace web-app-xxx         1/1     Running   0          2m
```

---

## 🔍 Phase 3: Run Kubernetes CIS Compliance Tests

### Step 6: Test Installation and Connectivity
```bash
# Navigate to scripts directory
cd ../scripts

# Test Kubernetes connectivity and tools
python3 test_installation.py
```

### Step 7: List Available Kubernetes CIS Controls
```bash
# List all Kubernetes CIS controls
python3 k8s_cis_checker.py list
```

**Expected Output:**
```
1.2.1: Ensure that the --anonymous-auth argument is set to false (HIGH)
5.1.1: Ensure that the cluster-admin role is only used where required (MEDIUM)
5.1.3: Minimize wildcard use in Roles and ClusterRoles (MEDIUM)
5.2.2: Minimize the admission of containers wishing to share the host process ID namespace (HIGH)
5.2.3: Minimize the admission of containers wishing to share the host IPC namespace (HIGH)
5.2.4: Minimize the admission of containers wishing to share the host network namespace (HIGH)
5.2.5: Minimize the admission of containers with allowPrivilegeEscalation (HIGH)
5.3.2: Ensure that all Namespaces have Network Policies defined (MEDIUM)
5.7.4: The default namespace should not be used (LOW)
```

### Step 8: Run Specific CIS Control Tests
```bash
# Test RBAC controls
python3 k8s_cis_checker.py check --controls "5.1.1,5.1.3"

# Test pod security controls
python3 k8s_cis_checker.py check --controls "5.2.2,5.2.3,5.2.4,5.2.5"

# Test network policy controls
python3 k8s_cis_checker.py check --controls "5.3.2"

# Test namespace usage
python3 k8s_cis_checker.py check --controls "5.7.4"
```

### Step 9: Run Comprehensive CIS Compliance Check
```bash
# Run all implemented Kubernetes CIS checks
python3 k8s_cis_checker.py check --format text

# Generate JSON report
python3 k8s_cis_checker.py check --format json --output ../reports/k8s-cis-report.json
```

**Expected Violations Found:**
```
Control: 5.1.3
Status: NON_COMPLIANT
Resource: ClusterRole::overly-permissive-role
Reason: Role uses wildcards in: verbs, resources, apiGroups
Remediation: Replace wildcards with specific permissions

Control: 5.2.2
Status: NON_COMPLIANT  
Resource: Pod::insecure-pod
Namespace: default
Reason: Pod shares host PID namespace
Remediation: Set hostPID: false in pod specification

Control: 5.2.3
Status: NON_COMPLIANT
Resource: Pod::insecure-pod  
Namespace: default
Reason: Pod shares host IPC namespace
Remediation: Set hostIPC: false in pod specification

Control: 5.7.4
Status: NON_COMPLIANT
Resource: Pod::insecure-pod
Namespace: default
Reason: Pod running in default namespace
Remediation: Move workloads to dedicated namespaces
```

### Step 10: Test Unified CIS Checker
```bash
# Test unified checker for Kubernetes
python3 unified_cis_checker.py k8s list

# Run unified Kubernetes checks
python3 unified_cis_checker.py k8s check --format json --output ../reports/unified-k8s-report.json
```

### Step 11: Use Automated Testing Script
```bash
# Use the Kubernetes deployment script for automated testing
cd ../tf
./k8s-deploy.sh test
```

**This will:**
1. Deploy all test resources
2. Wait for pods to be ready
3. Run comprehensive CIS checks
4. Generate reports

---

## 📊 Phase 4: Analyze Results and Validate Detection

### Step 12: Review Compliance Reports
```bash
# View text report
cd ../scripts
python3 k8s_cis_checker.py check --format text | less

# Analyze JSON report for specific violations
cat ../reports/k8s-cis-report.json | jq '.summary'

# Count violations by type
cat ../reports/k8s-cis-report.json | jq '.results[] | select(.status == "NON_COMPLIANT") | .control_id' | sort | uniq -c
```

### Step 13: Validate Specific Violations
```bash
# Check for host namespace violations
kubectl get pods -o yaml | grep -E "(hostPID|hostIPC|hostNetwork):"

# Check for RBAC wildcards
kubectl get clusterroles -o yaml | grep -A5 -B5 "\*"

# Check for workloads in default namespace
kubectl get pods -n default

# Check for namespaces without network policies
kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | xargs -I {} sh -c 'echo "Namespace: {}"; kubectl get networkpolicies -n {} --no-headers 2>/dev/null || echo "No network policies found"'
```

### Step 14: Test Remediation Scenarios
```bash
# Create a compliant pod for comparison
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: kube-system
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: secure-container
    image: nginx:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
          - ALL
    resources:
      limits:
        memory: "256Mi"
        cpu: "500m"
      requests:
        memory: "128Mi"
        cpu: "250m"
EOF

# Re-run checks to see the difference
python3 k8s_cis_checker.py check --controls "5.7.4"
```

---

## 📈 Phase 5: Advanced Testing Scenarios

### Step 15: Test with Different Kubernetes Contexts
```bash
# If you have multiple clusters, test context switching
kubectl config get-contexts

# Switch context (if available)
kubectl config use-context different-cluster

# Run checks against different cluster
python3 k8s_cis_checker.py check --context different-cluster
```

### Step 16: Test Namespace Filtering
```bash
# Test with specific kubeconfig
python3 k8s_cis_checker.py check --kubeconfig ~/.kube/config --format json

# Modify config.yaml to exclude certain namespaces
cat ../scripts/config.yaml | grep -A10 kubernetes
```

### Step 17: Performance Testing
```bash
# Time the CIS checks
time python3 k8s_cis_checker.py check

# Test with verbose logging
python3 k8s_cis_checker.py check --verbose
```

---

## 🧹 Phase 6: Cleanup Resources

### Step 18: Clean Up Kubernetes Test Resources
```bash
# Navigate to terraform directory
cd ../tf

# Remove Kubernetes test manifests
./k8s-deploy.sh cleanup

# Or manually delete resources
kubectl delete -f k8s-manifests/insecure-workloads.yaml --ignore-not-found=true
kubectl delete -f k8s-manifests/insecure-rbac.yaml --ignore-not-found=true
kubectl delete -f k8s-manifests/no-network-policies.yaml --ignore-not-found=true

# Verify cleanup
kubectl get pods --all-namespaces | grep -E "(insecure|unprotected)"
kubectl get clusterroles | grep -E "(overly-permissive|wildcard)"
```

### Step 19: Destroy EKS Infrastructure
```bash
# Destroy all AWS infrastructure (including EKS cluster)
terraform destroy

# When prompted, type 'yes' to confirm
# This will take 10-15 minutes
```

**⚠️ Warning**: This will permanently delete the EKS cluster and all associated AWS resources.

### Step 20: Verify Complete Cleanup
```bash
# Verify EKS cluster is deleted
aws eks list-clusters --region us-east-1

# Check that kubectl context is no longer valid
kubectl cluster-info

# Clean up kubeconfig entries (optional)
kubectl config delete-context arn:aws:eks:us-east-1:ACCOUNT:cluster/test-test-eks-cluster
```

---

## 🔧 Known Issues & Troubleshooting

### Common Setup Issues

#### 1. Python Import Errors
If you see `ImportError: cannot import name 'CISChecker'`, this is expected. The actual class name is `CISBenchmarkChecker`. The test script has been updated to handle this correctly.

#### 2. EKS Version Compatibility
The default EKS version has been updated to 1.31 for better compatibility and latest features. If you encounter version-related issues:
- Ensure your AWS CLI supports EKS 1.31
- Check that your kubectl version is compatible (1.30+ recommended)

#### 3. SSH Key Generation
The Terraform configuration now automatically generates SSH keys for EKS nodes instead of requiring pre-existing keys. This eliminates the "file not found" errors.

#### 4. Directory Navigation
**Important**: Always run Terraform commands from the `tf/` directory:
```bash
cd /path/to/cis-benchmark-checker/tf
terraform init
terraform apply
```

#### 5. Terraform State Issues
If you encounter state lock issues or corrupted state:
```bash
# Check for running processes
ps aux | grep terraform

# If needed, force unlock (use the lock ID from error message)
terraform force-unlock <LOCK_ID>

# Refresh state
terraform refresh
```

#### 6. Recent Updates & Fixes Applied
**Note**: The following issues have been identified and fixed as of July 27, 2025:
- **Project naming**: Changed from `cis-k8s-test` to `cisk8stest` to avoid AWS tag validation issues
- **IAM Policy deprecation**: Removed deprecated `AmazonEKSServicePolicy` for EKS 1.15+
- **Config dependencies**: Fixed AWS Config resource dependency order
- **Security groups**: Added basic security group for EKS node group connectivity
- **SSH key generation**: Automated SSH key creation using TLS provider
- **EKS version**: Updated to Kubernetes 1.31 for latest features

These fixes ensure a smooth deployment experience on your first run.

---

## 📋 Validation Checklist

After completing the guide, verify:

- [ ] EKS cluster deployed successfully
- [ ] kubectl can connect to cluster
- [ ] Test pods are running in default namespace
- [ ] RBAC violations detected (wildcards, excessive permissions)
- [ ] Pod security violations detected (host namespaces, privilege escalation)
- [ ] Network policy violations detected (missing policies)
- [ ] Default namespace usage detected
- [ ] JSON and text reports generated
- [ ] All test resources cleaned up
- [ ] EKS cluster destroyed
- [ ] AWS costs stopped

## 📊 Expected Test Results Summary

**Total Violations Expected**: 8-12 findings
- **5.1.1**: 1-2 findings (cluster-admin usage)
- **5.1.3**: 2-3 findings (RBAC wildcards)  
- **5.2.2**: 1 finding (host PID namespace)
- **5.2.3**: 1 finding (host IPC namespace)
- **5.2.4**: 1 finding (host network namespace)
- **5.2.5**: 1-2 findings (privilege escalation)
- **5.3.2**: 2 findings (missing network policies)
- **5.7.4**: 2-3 findings (default namespace usage)

**Compliance Percentage**: 15-25% (intentionally low due to test violations)

---

## 🎯 Next Steps

After completing this guide:

1. **Customize for your environment**: Modify the CIS controls to match your organization's requirements
2. **Integrate into CI/CD**: Add the Kubernetes CIS checks to your deployment pipelines
3. **Schedule regular scans**: Set up automated scanning of your production Kubernetes clusters
4. **Extend coverage**: Add more CIS controls based on your security needs
5. **Create dashboards**: Integrate reports with monitoring and compliance dashboards

This completes the comprehensive Kubernetes CIS testing workflow! 🎉
