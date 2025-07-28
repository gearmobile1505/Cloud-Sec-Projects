#!/bin/bash
# CIS Benchmark Test Infrastructure Deployment Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

usage() {
    cat << EOF
CIS Benchmark Test Infrastructure Deployment

Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    init        Initialize Terraform
    plan        Show planned infrastructure changes
    apply       Deploy the test infrastructure
    destroy     Destroy the test infrastructure
    test        Run CIS compliance checks against the infrastructure
    k8s-deploy  Deploy Kubernetes test resources
    k8s-test    Run Kubernetes CIS compliance checks
    k8s-cleanup Clean up Kubernetes test resources
    status      Show current infrastructure status

OPTIONS:
    --auto-approve    Skip confirmation prompts (for apply/destroy)
    --help           Show this help message

EXAMPLES:
    # Initialize and deploy infrastructure
    $0 init
    $0 apply

    # Test CIS compliance against deployed infrastructure
    $0 test

    # Deploy Kubernetes test resources
    $0 k8s-deploy

    # Run Kubernetes CIS compliance checks
    $0 k8s-test

    # Clean up Kubernetes test resources
    $0 k8s-cleanup

    # Clean up when done
    $0 destroy

EOF
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is required but not installed"
        print_info "Install from: https://terraform.io/downloads"
        exit 1
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is required but not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        print_error "AWS credentials not configured"
        print_info "Run 'aws configure' to set up credentials"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is required but not installed"
        print_info "Install from: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    print_status "Prerequisites satisfied"
}

terraform_init() {
    print_info "Initializing Terraform..."
    cd "$SCRIPT_DIR"
    
    if terraform init; then
        print_status "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        exit 1
    fi
}

terraform_plan() {
    print_info "Planning infrastructure changes..."
    cd "$SCRIPT_DIR"
    
    if ! terraform plan; then
        print_error "Terraform plan failed"
        exit 1
    fi
}

terraform_apply() {
    print_info "Deploying test infrastructure..."
    cd "$SCRIPT_DIR"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        print_warning "terraform.tfvars not found"
        print_info "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_info "Please review and customize terraform.tfvars, then run this command again"
        exit 1
    fi
    
    local auto_approve=""
    if [[ "$1" == "--auto-approve" ]]; then
        auto_approve="-auto-approve"
    fi
    
    if terraform apply $auto_approve; then
        print_status "Infrastructure deployed successfully"
        print_info ""
        print_info "Infrastructure is ready for CIS compliance testing!"
        print_info "Run '$0 test' to test CIS compliance against this infrastructure"
    else
        print_error "Infrastructure deployment failed"
        exit 1
    fi
}

terraform_destroy() {
    print_info "Destroying test infrastructure..."
    cd "$SCRIPT_DIR"
    
    local auto_approve=""
    if [[ "$1" == "--auto-approve" ]]; then
        auto_approve="-auto-approve"
    fi
    
    if terraform destroy $auto_approve; then
        print_status "Infrastructure destroyed successfully"
    else
        print_error "Infrastructure destruction failed"
        exit 1
    fi
}

terraform_status() {
    print_info "Checking infrastructure status..."
    cd "$SCRIPT_DIR"
    
    if terraform show -json | jq -r '.values.outputs' &>/dev/null; then
        print_status "Infrastructure is deployed"
        
        # Show key outputs
        if command -v jq &> /dev/null; then
            print_info "Key Information:"
            echo "  Account ID: $(terraform output -raw account_id 2>/dev/null || echo 'N/A')"
            echo "  Region: $(terraform output -raw region 2>/dev/null || echo 'N/A')"
            echo "  VPC ID: $(terraform output -raw vpc_id 2>/dev/null || echo 'N/A')"
            echo "  CloudTrail ARN: $(terraform output -raw cloudtrail_arn 2>/dev/null || echo 'N/A')"
        fi
    else
        print_warning "No infrastructure found or Terraform not initialized"
    fi
}

run_cis_tests() {
    print_info "Running CIS compliance tests against deployed infrastructure..."
    cd "$PROJECT_DIR"
    
    # Check if infrastructure is deployed
    if ! terraform -chdir=tf show -json | jq -r '.values.outputs' &>/dev/null; then
        print_error "No infrastructure found. Deploy first with '$0 apply'"
        exit 1
    fi
    
    local region
    region=$(terraform -chdir=tf output -raw region 2>/dev/null || echo "us-east-1")
    
    print_info "Testing against region: $region"
    
    # Test critical controls
    print_info "Testing critical CIS controls..."
    if python3 scripts/cis_checker.py check --region "$region" --controls "1.12,3.1,5.2,5.5" --format text; then
        print_status "Critical controls test completed"
    else
        print_warning "Some critical controls failed (this may be expected for testing)"
    fi
    
    # Run comprehensive test
    print_info "Running comprehensive CIS compliance check..."
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="./reports/tf_test_report_${timestamp}.json"
    
    mkdir -p ./reports
    
    if python3 scripts/cis_checker.py check --region "$region" --format json --output "$report_file"; then
        print_status "Comprehensive test completed"
        print_info "Report saved to: $report_file"
        
        # Display summary
        if command -v jq &> /dev/null; then
            print_info "Test Summary:"
            local compliant non_compliant
            compliant=$(jq -r '.summary.compliant' "$report_file")
            non_compliant=$(jq -r '.summary.non_compliant' "$report_file")
            
            echo "  Compliant: $compliant"
            echo "  Non-Compliant: $non_compliant"
            
            if [[ "$non_compliant" -gt 0 ]]; then
                print_info "Non-compliant controls (expected for testing):"
                jq -r '.results[] | select(.status == "NON_COMPLIANT") | "  - \(.control_id): \(.reason)"' "$report_file"
            fi
        fi
    else
        print_error "Comprehensive test failed"
        exit 1
    fi
    
    print_status "CIS compliance testing completed"
}

deploy_k8s_resources() {
    print_info "Deploying Kubernetes test resources..."
    
    if [ -f "$SCRIPT_DIR/k8s-deploy.sh" ]; then
        if "$SCRIPT_DIR/k8s-deploy.sh" deploy; then
            print_status "Kubernetes test resources deployed successfully"
        else
            print_error "Failed to deploy Kubernetes test resources"
            exit 1
        fi
    else
        print_error "k8s-deploy.sh not found"
        exit 1
    fi
}

cleanup_k8s_resources() {
    print_info "Cleaning up Kubernetes test resources..."
    
    if [ -f "$SCRIPT_DIR/k8s-deploy.sh" ]; then
        if "$SCRIPT_DIR/k8s-deploy.sh" cleanup; then
            print_status "Kubernetes test resources cleaned up successfully"
        else
            print_error "Failed to clean up Kubernetes test resources"
            exit 1
        fi
    else
        print_error "k8s-deploy.sh not found"
        exit 1
    fi
}

run_k8s_cis_tests() {
    print_info "Running Kubernetes CIS compliance tests..."
    
    if [ -f "$SCRIPT_DIR/k8s-deploy.sh" ]; then
        if "$SCRIPT_DIR/k8s-deploy.sh" check; then
            print_status "Kubernetes CIS checks completed"
        else
            print_error "Kubernetes CIS checks failed"
            exit 1
        fi
    else
        print_error "k8s-deploy.sh not found"
        exit 1
    fi
}

# Parse command line arguments
AUTO_APPROVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        init)
            COMMAND="init"
            shift
            ;;
        plan)
            COMMAND="plan"
            shift
            ;;
        apply)
            COMMAND="apply"
            shift
            ;;
        destroy)
            COMMAND="destroy"
            shift
            ;;
        test)
            COMMAND="test"
            shift
            ;;
        k8s-deploy)
            COMMAND="k8s-deploy"
            shift
            ;;
        k8s-test)
            COMMAND="k8s-test"
            shift
            ;;
        k8s-cleanup)
            COMMAND="k8s-cleanup"
            shift
            ;;
        status)
            COMMAND="status"
            shift
            ;;
        --auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${COMMAND:-}" ]]; then
    print_error "No command specified"
    usage
    exit 1
fi

# Main execution
print_info "CIS Benchmark Test Infrastructure Manager"
print_info "========================================"

check_prerequisites

case $COMMAND in
    init)
        terraform_init
        ;;
    plan)
        terraform_plan
        ;;
    apply)
        if [[ "$AUTO_APPROVE" == "true" ]]; then
            terraform_apply "--auto-approve"
        else
            terraform_apply
        fi
        ;;
    destroy)
        if [[ "$AUTO_APPROVE" == "true" ]]; then
            terraform_destroy "--auto-approve"
        else
            terraform_destroy
        fi
        ;;
    test)
        run_cis_tests
        ;;
    k8s-deploy)
        deploy_k8s_resources
        ;;
    k8s-test)
        run_k8s_cis_tests
        ;;
    k8s-cleanup)
        cleanup_k8s_resources
        ;;
    status)
        terraform_status
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
