#!/bin/bash

# Security Group Testing Setup Script
# This script helps you set up the test infrastructure and run security tests

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

# Check if we're in the right directory
if [[ ! -f "terraform/main.tf" ]]; then
    print_error "Please run this script from the aws-auto-remediation directory"
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d' ' -f2)
        print_status "Terraform installed: $TERRAFORM_VERSION"
    else
        print_error "Terraform not installed. Install from: https://terraform.io/downloads"
        exit 1
    fi
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
        print_status "AWS CLI installed: $AWS_VERSION"
        
        # Check credentials
        if aws sts get-caller-identity &> /dev/null; then
            AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
            AWS_REGION=$(aws configure get region || echo "us-east-1")
            print_status "AWS credentials configured - Account: $AWS_ACCOUNT, Region: $AWS_REGION"
        else
            print_error "AWS credentials not configured. Run: aws configure"
            exit 1
        fi
    else
        print_error "AWS CLI not installed. Install from: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # Check Python dependencies
    if python3 -c "import boto3" 2>/dev/null; then
        print_status "Python boto3 installed"
    else
        print_warning "Installing boto3..."
        pip3 install boto3 botocore
        print_status "Python dependencies installed"
    fi
}

# Function to setup Terraform configuration
setup_terraform() {
    print_header "Setting Up Terraform Configuration"
    
    cd terraform
    
    # Copy tfvars if it doesn't exist
    if [[ ! -f "terraform.tfvars" ]]; then
        print_info "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Try to get user's public IP
        if command -v curl &> /dev/null; then
            USER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "")
            if [[ -n "$USER_IP" ]]; then
                print_info "Detected your public IP: $USER_IP"
                # Update the tfvars file with user's IP
                sed -i.bak "s/192.168.1.0\/24/${USER_IP}\/32/g" terraform.tfvars
                print_status "Updated terraform.tfvars with your IP: ${USER_IP}/32"
            fi
        fi
        
        print_warning "Please review and edit terraform.tfvars before proceeding:"
        print_info "nano terraform.tfvars"
        echo ""
        read -p "Press Enter to continue after reviewing terraform.tfvars..."
    else
        print_status "terraform.tfvars already exists"
    fi
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    print_status "Terraform initialized"
    
    cd ..
}

# Function to deploy test infrastructure
deploy_infrastructure() {
    print_header "Deploying Test Infrastructure"
    
    cd terraform
    
    print_info "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    echo ""
    print_warning "About to create AWS resources. Review the plan above."
    print_info "The following security groups will be created with INTENTIONALLY INSECURE configurations:"
    echo "  • High Risk: SSH + RDP open to internet"
    echo "  • Medium Risk: Database ports open to internet"  
    echo "  • Extreme Risk: All protocols open to internet"
    echo "  • Low Risk: Properly configured web server"
    echo "  • Secure: Best practice configuration"
    echo ""
    
    read -p "Deploy infrastructure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        print_status "Infrastructure deployed successfully"
        
        # Save security group IDs for easy reference
        terraform output -json security_group_ids > ../security_group_ids.json
        print_status "Security group IDs saved to security_group_ids.json"
    else
        print_info "Deployment cancelled"
        rm -f tfplan
        cd ..
        return
    fi
    
    cd ..
}

# Function to run security tests
run_security_tests() {
    print_header "Running Security Group Tests"
    
    if [[ ! -f "security_group_ids.json" ]]; then
        print_error "Security group IDs not found. Deploy infrastructure first."
        return
    fi
    
    print_info "Test 1: Finding all open security groups..."
    python3 automation/security_group_remediation.py find
    echo ""
    
    print_info "Test 2: Generating detailed security report..."
    python3 automation/security_group_remediation.py report --output test_security_report.json
    print_status "Report saved to test_security_report.json"
    echo ""
    
    print_info "Test 3: Testing SSH-specific detection..."
    python3 automation/security_group_remediation.py find --ports 22
    echo ""
    
    print_info "Test 4: Testing database port detection..."
    python3 automation/security_group_remediation.py find --ports "3306,5432,6379,27017"
    echo ""
    
    # Get high risk security group ID for individual testing
    HIGH_RISK_SG=$(cat security_group_ids.json | python3 -c "import sys, json; print(json.load(sys.stdin)['high_risk'])")
    
    if [[ -n "$HIGH_RISK_SG" ]]; then
        print_info "Test 5: Testing individual remediation (DRY RUN) on high-risk SG: $HIGH_RISK_SG"
        python3 automation/security_group_remediation.py remediate "$HIGH_RISK_SG" --dry-run
        echo ""
    fi
    
    print_info "Test 6: Testing bulk remediation (DRY RUN)..."
    python3 automation/security_group_remediation.py bulk-remediate --dry-run
    echo ""
    
    print_status "All security tests completed!"
    print_info "Review the results above to verify your tools are working correctly."
}

# Function to run AWS CLI tests
run_aws_cli_tests() {
    print_header "Running AWS CLI Security Tests"
    
    print_info "Test 1: Listing all security groups..."
    python3 automation/aws_resource_manager.py ec2 --operation describe_security_groups
    echo ""
    
    print_info "Test 2: Finding security groups with SSH open to anywhere..."
    aws ec2 describe-security-groups \
        --filters "Name=ip-permission.from-port,Values=22" \
                  "Name=ip-permission.cidr,Values=0.0.0.0/0" \
        --query 'SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName,Description:Description}' \
        --output table
    echo ""
    
    print_info "Test 3: Getting VPC information..."
    python3 automation/aws_resource_manager.py ec2 --operation describe_vpcs
    echo ""
}

# Function to cleanup resources
cleanup_infrastructure() {
    print_header "Cleaning Up Test Infrastructure"
    
    cd terraform
    
    print_warning "This will destroy ALL test resources created by Terraform."
    print_info "Make sure you've saved any test results you need."
    echo ""
    
    read -p "Destroy infrastructure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform destroy -auto-approve
        print_status "Infrastructure destroyed successfully"
        
        # Clean up local files
        cd ..
        rm -f security_group_ids.json test_security_report.json
        print_status "Cleanup completed"
    else
        print_info "Cleanup cancelled"
    fi
    
    cd ..
}

# Function to show test results summary
show_summary() {
    print_header "Test Summary"
    
    if [[ -f "test_security_report.json" ]]; then
        print_info "Security Report Summary:"
        cat test_security_report.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"  Total Security Groups Found: {data['TotalSecurityGroups']}\")
print(f\"  High Risk: {data['Summary']['HighRisk']}\")
print(f\"  Medium Risk: {data['Summary']['MediumRisk']}\")
print(f\"  Low Risk: {data['Summary']['LowRisk']}\")
"
        echo ""
    fi
    
    if [[ -f "security_group_ids.json" ]]; then
        print_info "Created Security Groups:"
        cat security_group_ids.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
for name, sg_id in data.items():
    print(f\"  {name}: {sg_id}\")
"
        echo ""
    fi
    
    print_info "Available Commands:"
    echo "  1. Deploy infrastructure: ./test_setup.sh deploy"
    echo "  2. Run security tests: ./test_setup.sh test"
    echo "  3. Run AWS CLI tests: ./test_setup.sh aws-test"
    echo "  4. Cleanup resources: ./test_setup.sh cleanup"
    echo "  5. Show summary: ./test_setup.sh summary"
    echo ""
}

# Main function
main() {
    case "${1:-}" in
        "prerequisites"|"prereq")
            check_prerequisites
            ;;
        "setup")
            check_prerequisites
            setup_terraform
            ;;
        "deploy")
            check_prerequisites
            setup_terraform
            deploy_infrastructure
            ;;
        "test")
            check_prerequisites
            run_security_tests
            ;;
        "aws-test")
            check_prerequisites
            run_aws_cli_tests
            ;;
        "cleanup"|"destroy")
            cleanup_infrastructure
            ;;
        "summary")
            show_summary
            ;;
        "all")
            check_prerequisites
            setup_terraform
            deploy_infrastructure
            run_security_tests
            show_summary
            ;;
        *)
            print_header "Security Group Testing Setup"
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  prerequisites  - Check if all required tools are installed"
            echo "  setup         - Set up Terraform configuration"
            echo "  deploy        - Deploy test infrastructure"
            echo "  test          - Run security group tests"
            echo "  aws-test      - Run AWS CLI tests"
            echo "  cleanup       - Destroy test infrastructure"
            echo "  summary       - Show test results summary"
            echo "  all           - Run complete setup and testing cycle"
            echo ""
            echo "Examples:"
            echo "  $0 prerequisites  # Check requirements"
            echo "  $0 deploy        # Set up test infrastructure"
            echo "  $0 test          # Run security tests"
            echo "  $0 cleanup       # Clean up when done"
            echo ""
            ;;
    esac
}

# Run main function with all arguments
main "$@"
