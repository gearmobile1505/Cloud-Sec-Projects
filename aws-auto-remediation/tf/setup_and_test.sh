#!/bin/bash
# Test Infrastructure Setup and Security Testing Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$SCRIPT_DIR"

print_header "Security Group Testing Infrastructure Setup"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured or invalid. Please run 'aws configure'."
    exit 1
fi

print_status "✅ AWS CLI configured"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    print_status "Install from: https://www.terraform.io/downloads.html"
    exit 1
fi

print_status "✅ Terraform installed"

# Check if Python dependencies are available
cd "$PROJECT_DIR"
if ! python3 -c "import boto3" &> /dev/null; then
    print_warning "boto3 not found. Installing..."
    pip3 install boto3 botocore
fi

print_status "✅ Python dependencies available"

# Get user's public IP for SSH restriction
print_status "Getting your public IP for SSH restriction..."
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "")

if [ -z "$PUBLIC_IP" ]; then
    print_warning "Could not determine your public IP automatically."
    read -p "Please enter your public IP address: " PUBLIC_IP
fi

print_status "Your public IP: $PUBLIC_IP"

# Prepare Terraform configuration
cd "$TF_DIR"

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    print_status "Creating terraform.tfvars..."
    cat > terraform.tfvars << EOF
# Security Group Testing Configuration
aws_region = "us-east-1"
project_name = "sec-test"
environment = "testing"

# Network configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# SSH access restricted to your IP
allowed_ssh_cidr = "$PUBLIC_IP/32"

# EC2 instance type (if enabling instances)
instance_type = "t3.micro"

# SSH public key (leave empty to disable instances)
public_key_content = ""
EOF
    print_status "✅ Created terraform.tfvars with your IP: $PUBLIC_IP/32"
else
    print_status "✅ terraform.tfvars already exists"
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate configuration
print_status "Validating Terraform configuration..."
terraform validate

# Show what will be created
print_header "Terraform Plan"
print_status "Planning infrastructure deployment..."
terraform plan

# Ask for confirmation
echo ""
print_warning "This will create AWS resources for testing security group remediation."
print_warning "Security groups are free, but be aware of any costs if you enable EC2 instances."
echo ""
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled."
    exit 0
fi

# Deploy infrastructure
print_header "Deploying Test Infrastructure"
print_status "Applying Terraform configuration..."
terraform apply -auto-approve

# Get outputs
print_header "Deployment Complete"
print_status "Infrastructure deployed successfully!"

echo ""
print_status "Security Group IDs created:"
terraform output security_group_summary

echo ""
print_header "Testing Security Remediation Tools"

# Change back to project directory for testing
cd "$PROJECT_DIR"

# Test 1: Find all open security groups
print_status "Test 1: Finding all open security groups..."
python3 automation/security_group_remediation.py find --output tf/test_results.json
echo ""

# Test 2: Generate security report
print_status "Test 2: Generating detailed security report..."
python3 automation/security_group_remediation.py report --output tf/security_report.json
echo ""

# Test 3: Test specific port scanning
print_status "Test 3: Scanning for high-risk ports (SSH, RDP)..."
python3 automation/security_group_remediation.py find --ports "22,3389"
echo ""

# Test 4: Test database port scanning
print_status "Test 4: Scanning for database ports..."
python3 automation/security_group_remediation.py find --ports "3306,5432,6379,27017"
echo ""

# Test 5: Dry-run remediation on high-risk group
print_status "Test 5: Testing dry-run remediation on high-risk security group..."
cd "$TF_DIR"
HIGH_RISK_SG=$(terraform output -raw high_risk_sg_id)
cd "$PROJECT_DIR"
python3 automation/security_group_remediation.py remediate "$HIGH_RISK_SG" --dry-run
echo ""

# Test 6: Bulk dry-run remediation
print_status "Test 6: Testing bulk dry-run remediation..."
python3 automation/security_group_remediation.py bulk-remediate --dry-run
echo ""

print_header "Test Results Summary"
print_status "✅ All tests completed successfully!"
print_status "📊 Reports saved to:"
print_status "   - tf/test_results.json (open security groups)"
print_status "   - tf/security_report.json (detailed security report)"

echo ""
print_header "Next Steps"
print_status "1. Review the test results in the JSON files"
print_status "2. Try actual remediation (without --dry-run) on test groups"
print_status "3. Experiment with different CIDR replacements"
print_status "4. Test the automation scripts in the scripts/ directory"

echo ""
print_header "Available Test Commands"
cd "$TF_DIR"
terraform output test_commands

echo ""
print_warning "🧹 Cleanup: When finished testing, run 'terraform destroy' in the tf/ directory"
print_warning "💰 Cost: Security groups are free, but clean up to avoid any unexpected charges"

echo ""
print_status "🎉 Security testing infrastructure is ready!"
print_status "📖 See tf/README.md for detailed testing scenarios and troubleshooting"
