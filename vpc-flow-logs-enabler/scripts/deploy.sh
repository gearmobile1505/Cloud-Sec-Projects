#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting VPC Flow Logs Enabler deployment...${NC}"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed.${NC}" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}Python 3 is required but not installed.${NC}" >&2; exit 1; }

# Validate terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}terraform.tfvars file not found. Please create it based on terraform.tfvars.example${NC}"
    exit 1
fi

echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

echo -e "${YELLOW}Planning deployment...${NC}"
terraform plan -out=tfplan

echo -e "${YELLOW}Applying changes...${NC}"
terraform apply tfplan

echo -e "${GREEN}Deployment completed successfully!${NC}"

# Display important outputs
echo -e "${GREEN}Important information:${NC}"
terraform output
