#!/bin/bash

# Terraform Validation Script for Azure Sentinel KQL Testing Infrastructure
# This script validates the Terraform configuration before deployment

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

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "main.tf" ]; then
        print_error "Please run this script from the terraform directory."
        echo "Current directory: $(pwd)"
        echo "Expected files: main.tf, variables.tf, etc."
        exit 1
    fi
    print_success "Running from correct directory"
}

# Function to check terraform installation
check_terraform() {
    print_status "Checking Terraform installation..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        echo "Please install Terraform: https://www.terraform.io/downloads"
        exit 1
    fi
    
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_success "Terraform version: $TERRAFORM_VERSION"
}

# Function to validate terraform syntax
validate_syntax() {
    print_status "Validating Terraform syntax..."
    
    # Format check
    print_status "Checking code formatting..."
    if terraform fmt -check -recursive; then
        print_success "Code formatting is correct"
    else
        print_warning "Code formatting needs adjustment. Run 'terraform fmt -recursive' to fix."
    fi
    
    # Initialize (required for validation)
    print_status "Initializing Terraform..."
    if terraform init -backend=false > /dev/null 2>&1; then
        print_success "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        terraform init -backend=false
        exit 1
    fi
    
    # Validate configuration
    print_status "Validating configuration..."
    if terraform validate; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform validation failed"
        exit 1
    fi
}

# Function to check required files
check_required_files() {
    print_status "Checking required files..."
    
    REQUIRED_FILES=(
        "main.tf"
        "variables.tf"
        "outputs.tf"
        "log-analytics.tf"
        "network.tf"
        "compute.tf"
        "sentinel.tf"
        "backend.tf"
        "terraform.tfvars.example"
        "README.md"
    )
    
    MISSING_FILES=()
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_success "✓ $file"
        else
            print_error "✗ $file (missing)"
            MISSING_FILES+=("$file")
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -eq 0 ]; then
        print_success "All required files present"
    else
        print_error "Missing files: ${MISSING_FILES[*]}"
        exit 1
    fi
}

# Function to validate terraform.tfvars
check_tfvars() {
    print_status "Checking terraform.tfvars configuration..."
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Using terraform.tfvars.example for validation."
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars.temp
            TFVARS_FILE="terraform.tfvars.temp"
        else
            print_error "terraform.tfvars.example not found"
            exit 1
        fi
    else
        TFVARS_FILE="terraform.tfvars"
    fi
    
    # Basic validation of key variables
    REQUIRED_VARS=(
        "project_name"
        "environment"
        "location"
    )
    
    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^$var\s*=" "$TFVARS_FILE"; then
            VALUE=$(grep "^$var\s*=" "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')
            print_success "✓ $var = $VALUE"
        else
            print_error "✗ $var (not set in $TFVARS_FILE)"
        fi
    done
    
    # Clean up temp file
    if [ "$TFVARS_FILE" = "terraform.tfvars.temp" ]; then
        rm terraform.tfvars.temp
    fi
}

# Function to check Azure provider constraints
check_azure_constraints() {
    print_status "Checking Azure-specific constraints..."
    
    # Check for common Azure naming issues
    if [ -f "terraform.tfvars" ]; then
        # Check project name length and format
        if grep -q "^project_name" terraform.tfvars; then
            PROJECT_NAME=$(grep "^project_name" terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
            if [ ${#PROJECT_NAME} -gt 20 ]; then
                print_warning "project_name '$PROJECT_NAME' is long (${#PROJECT_NAME} chars). May cause resource naming issues."
            fi
            
            if [[ ! $PROJECT_NAME =~ ^[a-zA-Z0-9-]+$ ]]; then
                print_warning "project_name '$PROJECT_NAME' contains special characters. May cause issues."
            fi
            
            print_success "✓ project_name validation passed"
        fi
        
        # Check location format
        if grep -q "^location" terraform.tfvars; then
            LOCATION=$(grep "^location" terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
            VALID_LOCATIONS=("East US" "West US 2" "Central US" "West Europe" "North Europe" "Southeast Asia")
            
            if [[ " ${VALID_LOCATIONS[@]} " =~ " ${LOCATION} " ]]; then
                print_success "✓ location '$LOCATION' is valid"
            else
                print_warning "location '$LOCATION' may not be a standard Azure region"
            fi
        fi
    fi
}

# Function to estimate costs
estimate_costs() {
    print_status "Estimating monthly costs..."
    
    echo "Based on terraform.tfvars configuration:"
    
    if [ -f "terraform.tfvars" ]; then
        # Check if VMs are enabled
        if grep -q "create_test_vms.*=.*true" terraform.tfvars; then
            VM_SIZE=$(grep "vm_size" terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "Standard_B2s")
            echo "  Test VM ($VM_SIZE): ~\$30-50/month"
        else
            echo "  Test VM: Disabled (\$0)"
        fi
        
        # Check Log Analytics quota
        if grep -q "log_analytics_daily_quota_gb" terraform.tfvars; then
            QUOTA=$(grep "log_analytics_daily_quota_gb" terraform.tfvars | cut -d'=' -f2 | tr -d ' ')
            LA_COST=$((QUOTA * 30 * 3))  # Rough estimate: $3/GB
            echo "  Log Analytics (${QUOTA}GB/day): ~\$${LA_COST}/month"
            echo "  Sentinel (${QUOTA}GB/day): ~\$${LA_COST}/month"
        else
            echo "  Log Analytics: ~\$30-90/month (depends on data volume)"
            echo "  Sentinel: ~\$30-90/month (depends on data volume)"
        fi
        
        echo "  Storage Account: ~\$1-5/month"
        echo "  Key Vault: ~\$1-3/month"
        echo "  Network resources: ~\$1-5/month"
        echo ""
        echo "  Estimated Total: \$35-150/month (varies by usage)"
    else
        echo "  terraform.tfvars not found - using default estimates"
        echo "  Estimated Total: \$35-75/month"
    fi
    
    print_warning "Remember to run 'terraform destroy' when testing is complete!"
}

# Function to run security checks
run_security_checks() {
    print_status "Running basic security checks..."
    
    # Check for hardcoded secrets
    print_status "Checking for potential secrets..."
    SECURITY_PATTERNS=(
        "password.*=.*['\"][^'\"]*['\"]"
        "secret.*=.*['\"][^'\"]*['\"]"
        "key.*=.*['\"][^'\"]*['\"]"
        "token.*=.*['\"][^'\"]*['\"]"
    )
    
    SECURITY_ISSUES=0
    for pattern in "${SECURITY_PATTERNS[@]}"; do
        if grep -r -i -E "$pattern" . --include="*.tf" --include="*.tfvars" 2>/dev/null; then
            print_warning "Potential hardcoded secret found (pattern: $pattern)"
            SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
        fi
    done
    
    if [ $SECURITY_ISSUES -eq 0 ]; then
        print_success "No obvious security issues found"
    else
        print_warning "$SECURITY_ISSUES potential security issues found"
    fi
    
    # Check for public access configurations
    print_status "Checking for public access configurations..."
    if grep -r "0.0.0.0/0" . --include="*.tf" 2>/dev/null; then
        print_warning "Found 0.0.0.0/0 (open to internet) in configuration"
    else
        print_success "No overly permissive network access found"
    fi
}

# Function to show validation summary
show_summary() {
    echo ""
    echo "=============================================="
    print_success "Terraform Validation Complete!"
    echo "=============================================="
    echo ""
    print_status "Summary:"
    echo "✅ Directory structure correct"
    echo "✅ Terraform syntax valid"
    echo "✅ Required files present"
    echo "✅ Configuration validated"
    echo "✅ Azure constraints checked"
    echo "✅ Security scan completed"
    echo "✅ Cost estimation provided"
    echo ""
    print_status "Next Steps:"
    echo "1. Review the cost estimates above"
    echo "2. Deploy with: terraform plan && terraform apply"
    echo "3. Or use GitHub Actions: See GITHUB_ACTIONS.md"
    echo "4. Test KQL queries in the deployed environment"
    echo "5. Run 'terraform destroy' when testing is complete"
    echo ""
    print_warning "Always review 'terraform plan' output before applying!"
}

# Main execution
main() {
    echo "=============================================="
    echo "Azure Sentinel KQL Testing Infrastructure"
    echo "Terraform Configuration Validator"
    echo "=============================================="
    echo ""
    
    check_directory
    check_terraform
    check_required_files
    validate_syntax
    check_tfvars
    check_azure_constraints
    run_security_checks
    estimate_costs
    show_summary
}

# Handle script arguments
case "${1:-validate}" in
    "validate")
        main
        ;;
    "format")
        print_status "Formatting Terraform files..."
        terraform fmt -recursive
        print_success "Formatting complete!"
        ;;
    "security")
        check_directory
        run_security_checks
        ;;
    "costs")
        check_directory
        estimate_costs
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  validate   Run full validation (default)"
        echo "  format     Format Terraform files"
        echo "  security   Run security checks only"
        echo "  costs      Show cost estimates only"
        echo "  help       Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac
