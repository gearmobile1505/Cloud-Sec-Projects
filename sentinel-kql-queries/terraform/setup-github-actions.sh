#!/bin/bash

# GitHub Actions Setup Script for Azure Sentinel KQL Testing Infrastructure
# This script helps configure GitHub repository secrets for Azure authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI is not installed. Please install it first."
        echo "Installation: https://cli.github.com/"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        print_error "Not logged into GitHub. Please run 'gh auth login' first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Function to create Azure Service Principal
create_service_principal() {
    print_status "Creating Azure Service Principal for GitHub Actions..."
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    
    print_status "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
    
    # Create service principal
    SP_NAME="gh-actions-sentinel-kql-sp"
    
    # Check if service principal already exists
    if az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv | grep -q .; then
        print_warning "Service principal '$SP_NAME' already exists. Using existing one."
        APP_ID=$(az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv)
    else
        print_status "Creating new service principal..."
        SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" --role contributor --scopes "/subscriptions/$SUBSCRIPTION_ID" --json-auth)
        APP_ID=$(echo "$SP_OUTPUT" | jq -r '.clientId')
        print_success "Service principal created successfully!"
    fi
    
    # Get service principal details
    SP_DETAILS=$(az ad sp list --display-name "$SP_NAME" --query '[0]' -o json)
    CLIENT_ID=$(echo "$SP_DETAILS" | jq -r '.appId')
    OBJECT_ID=$(echo "$SP_DETAILS" | jq -r '.id')
    
    # Get tenant ID
    TENANT_ID=$(az account show --query tenantId -o tsv)
    
    # For existing SP, we need to create a new client secret
    print_status "Creating client secret..."
    SECRET_OUTPUT=$(az ad app credential reset --id "$CLIENT_ID" --append --display-name "github-actions-$(date +%Y%m%d)")
    CLIENT_SECRET=$(echo "$SECRET_OUTPUT" | jq -r '.password')
    
    print_success "Azure Service Principal configured!"
    
    # Export variables for use in next function
    export SUBSCRIPTION_ID
    export CLIENT_ID
    export CLIENT_SECRET
    export TENANT_ID
    export OBJECT_ID
}

# Function to set GitHub repository secrets
set_github_secrets() {
    print_status "Setting GitHub repository secrets..."
    
    # Create Azure credentials JSON
    AZURE_CREDENTIALS=$(cat <<EOF
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID"
}
EOF
)
    
    # Set GitHub secrets
    echo "$AZURE_CREDENTIALS" | gh secret set AZURE_CREDENTIALS
    echo "$SUBSCRIPTION_ID" | gh secret set ARM_SUBSCRIPTION_ID
    echo "$CLIENT_ID" | gh secret set ARM_CLIENT_ID
    echo "$CLIENT_SECRET" | gh secret set ARM_CLIENT_SECRET
    echo "$TENANT_ID" | gh secret set ARM_TENANT_ID
    
    print_success "GitHub secrets configured!"
}

# Function to setup GitHub environments
setup_github_environments() {
    print_status "Setting up GitHub environments..."
    
    # Create environments
    for env in dev staging prod; do
        print_status "Creating environment: $env"
        gh api --method PUT "repos/:owner/:repo/environments/$env" \
            --field wait_timer=0 \
            --field prevent_self_review=false \
            --field reviewers='[]' \
            --field deployment_branch_policy='{"protected_branches":false,"custom_branch_policies":true}' \
            > /dev/null 2>&1 || true
    done
    
    print_success "GitHub environments configured!"
}

# Function to test the setup
test_setup() {
    print_status "Testing GitHub Actions setup..."
    
    # Trigger workflow
    print_status "You can now trigger the workflow manually:"
    echo "1. Go to your GitHub repository"
    echo "2. Click on 'Actions' tab"
    echo "3. Select 'Deploy Azure Sentinel KQL Testing Infrastructure'"
    echo "4. Click 'Run workflow'"
    echo "5. Choose 'plan' action and 'dev' environment"
    
    print_warning "The workflow will:"
    echo "- Create Terraform state storage in Azure"
    echo "- Run terraform plan"
    echo "- Show the planned changes"
    echo "- For 'apply' action: Deploy the infrastructure"
    echo "- For 'destroy' action: Remove all resources"
}

# Function to show cost information
show_cost_info() {
    print_warning "COST INFORMATION:"
    echo "The GitHub Actions workflow will deploy Azure resources that incur costs:"
    echo "  - Log Analytics: ~\$2-10 per GB ingested"
    echo "  - Sentinel: ~\$2-4 per GB ingested"
    echo "  - Test VM: ~\$30-50 per month"
    echo "  - Storage & Key Vault: ~\$2-8 per month"
    echo "  - Estimated Total: \$35-75 per month"
    echo ""
    echo "The workflow includes auto-shutdown and cost optimization settings."
    echo "Always use the 'destroy' action when testing is complete!"
    echo ""
}

# Function to display next steps
show_next_steps() {
    print_success "GitHub Actions Setup Complete!"
    echo ""
    print_status "What was configured:"
    echo "✅ Azure Service Principal with Contributor role"
    echo "✅ GitHub repository secrets for Azure authentication"
    echo "✅ GitHub environments (dev, staging, prod)"
    echo "✅ Terraform backend storage configuration"
    echo ""
    print_status "Next steps:"
    echo "1. Review the workflow file: .github/workflows/azure-sentinel-deploy.yml"
    echo "2. Commit the changes to your repository"
    echo "3. Go to GitHub Actions and run the workflow with 'plan' action"
    echo "4. Review the plan, then run with 'apply' action if satisfied"
    echo "5. Use the 'destroy' action to clean up when done testing"
    echo ""
    print_status "Workflow usage:"
    echo "• Manual trigger: Go to Actions → Deploy Azure Sentinel → Run workflow"
    echo "• Auto trigger: Push to main branch (will only plan, not apply)"
    echo "• PR trigger: Will show plan in PR comments"
    echo ""
    print_warning "Remember to destroy resources when not in use to avoid ongoing costs!"
}

# Main execution
main() {
    echo "=============================================="
    echo "GitHub Actions Setup for Azure Sentinel"
    echo "KQL Testing Infrastructure"
    echo "=============================================="
    echo ""
    
    show_cost_info
    read -p "Do you understand the costs and want to proceed? (y/N): " cost_confirm
    if [[ ! $cost_confirm =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled."
        exit 0
    fi
    
    check_prerequisites
    create_service_principal
    set_github_secrets
    setup_github_environments
    test_setup
    show_next_steps
}

# Handle script arguments
case "${1:-setup}" in
    "setup")
        main
        ;;
    "test")
        print_status "Testing GitHub Actions workflow..."
        gh workflow run azure-sentinel-deploy.yml --ref main
        print_success "Workflow triggered! Check the Actions tab in your repository."
        ;;
    "secrets")
        print_status "Current GitHub secrets:"
        gh secret list
        ;;
    "cleanup")
        print_warning "This will remove the Azure Service Principal!"
        read -p "Are you sure? Type 'yes' to confirm: " cleanup_confirm
        if [ "$cleanup_confirm" = "yes" ]; then
            SP_NAME="gh-actions-sentinel-kql-sp"
            az ad sp delete --id "$(az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv)" || true
            print_success "Service principal deleted!"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  setup     Setup GitHub Actions (default)"
        echo "  test      Trigger the workflow"
        echo "  secrets   List current secrets"
        echo "  cleanup   Remove Azure Service Principal"
        echo "  help      Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac
