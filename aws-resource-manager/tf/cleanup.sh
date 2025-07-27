#!/bin/bash
# Cleanup script for security testing infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header "Security Testing Infrastructure Cleanup"

cd "$SCRIPT_DIR"

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    print_warning "No Terraform state found. Infrastructure may already be destroyed."
    exit 0
fi

# Show what will be destroyed
print_status "Showing resources that will be destroyed..."
terraform plan -destroy

echo ""
print_warning "⚠️  This will permanently delete all test infrastructure including:"
print_warning "   - Test security groups"
print_warning "   - VPC and networking components"
print_warning "   - Any EC2 instances (if enabled)"
echo ""

read -p "Are you sure you want to destroy all test infrastructure? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

# Destroy infrastructure
print_header "Destroying Infrastructure"
print_status "Running terraform destroy..."
terraform destroy -auto-approve

# Clean up local files
print_status "Cleaning up local files..."
rm -f terraform.tfstate.backup
rm -f test_results.json
rm -f security_report.json
rm -f .terraform.lock.hcl

print_header "Cleanup Complete"
print_status "✅ All test infrastructure has been destroyed"
print_status "✅ Local test files cleaned up"
print_status "💰 No more AWS charges from test resources"

echo ""
print_status "🎉 Cleanup completed successfully!"
print_status "You can re-run './setup_and_test.sh' anytime to recreate the test environment."
