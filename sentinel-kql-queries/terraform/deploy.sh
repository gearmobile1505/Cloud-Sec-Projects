#!/bin/bash

# Azure Sentinel KQL Testing Infrastructure Deployment Script
# This script automates the deployment of the testing environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        echo "Installation instructions: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        echo "Installation instructions: https://www.terraform.io/downloads"
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Function to setup terraform variables
setup_variables() {
    if [ ! -f "terraform.tfvars" ]; then
        print_status "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        
        print_warning "Please edit terraform.tfvars with your desired configuration before proceeding."
        print_status "Key settings to review:"
        echo "  - project_name: Unique name for your resources"
        echo "  - location: Azure region (e.g., 'East US')"
        echo "  - vm_admin_username: Username for test VM"
        echo "  - tags: Resource tags for organization"
        
        read -p "Press Enter to continue after editing terraform.tfvars..."
    else
        print_status "Using existing terraform.tfvars file"
    fi
}

# Function to initialize terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    
    if [ $? -eq 0 ]; then
        print_success "Terraform initialized successfully!"
    else
        print_error "Terraform initialization failed!"
        exit 1
    fi
}

# Function to plan deployment
plan_deployment() {
    print_status "Creating deployment plan..."
    terraform plan -out=tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Deployment plan created successfully!"
        echo ""
        print_warning "Review the plan above carefully before proceeding."
        read -p "Do you want to continue with the deployment? (y/N): " confirm
        
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_status "Deployment cancelled by user."
            exit 0
        fi
    else
        print_error "Failed to create deployment plan!"
        exit 1
    fi
}

# Function to apply terraform
apply_terraform() {
    print_status "Deploying infrastructure..."
    terraform apply tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure deployed successfully!"
        echo ""
        print_status "Retrieving connection information..."
        terraform output
    else
        print_error "Deployment failed!"
        exit 1
    fi
}

# Function to display cost information
show_cost_info() {
    print_warning "COST INFORMATION:"
    echo "This infrastructure will incur Azure charges:"
    echo "  - Log Analytics: ~\$2-10 per GB ingested"
    echo "  - Sentinel: ~\$2-4 per GB ingested"
    echo "  - Test VM: ~\$30-50 per month"
    echo "  - Storage & Key Vault: ~\$2-8 per month"
    echo "  - Estimated Total: \$35-75 per month"
    echo ""
    echo "To minimize costs:"
    echo "  - Set log_analytics_daily_quota_gb = 1 in terraform.tfvars"
    echo "  - Use auto_shutdown for VMs"
    echo "  - Run 'terraform destroy' when not in use"
    echo ""
}

# Function to show next steps
show_next_steps() {
    print_success "Deployment Complete!"
    echo ""
    print_status "Next Steps:"
    echo "1. Access your Sentinel workspace using the URL from terraform output"
    echo "2. Wait 10-15 minutes for initial data ingestion"
    echo "3. Test KQL queries in Log Analytics workspace"
    echo "4. Review the sample analytics rules in Sentinel"
    echo ""
    echo "Useful commands:"
    echo "  terraform output                    # Show connection info"
    echo "  terraform destroy                   # Clean up resources"
    echo "  az monitor log-analytics query      # Query from CLI"
    echo ""
    print_warning "Remember to run 'terraform destroy' when finished to avoid ongoing costs!"
}

# Main execution
main() {
    echo "=============================================="
    echo "Azure Sentinel KQL Testing Infrastructure"
    echo "Deployment Script"
    echo "=============================================="
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "main.tf" ]; then
        print_error "Please run this script from the terraform directory."
        exit 1
    fi
    
    # Show cost warning
    show_cost_info
    read -p "Do you understand the costs and want to proceed? (y/N): " cost_confirm
    if [[ ! $cost_confirm =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled."
        exit 0
    fi
    
    # Run deployment steps
    check_prerequisites
    setup_variables
    init_terraform
    plan_deployment
    apply_terraform
    show_next_steps
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "destroy")
        print_warning "This will destroy all resources and cannot be undone!"
        read -p "Are you sure? Type 'yes' to confirm: " destroy_confirm
        if [ "$destroy_confirm" = "yes" ]; then
            terraform destroy
            print_success "Resources destroyed!"
        else
            print_status "Destroy cancelled."
        fi
        ;;
    "plan")
        check_prerequisites
        terraform plan
        ;;
    "status")
        terraform show
        ;;
    "outputs")
        terraform output
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  deploy     Deploy the infrastructure (default)"
        echo "  destroy    Destroy all resources"
        echo "  plan       Show deployment plan"
        echo "  status     Show current state"
        echo "  outputs    Show connection information"
        echo "  help       Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac
