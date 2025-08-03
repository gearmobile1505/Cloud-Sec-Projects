#!/bin/bash

# Verify Terraform Backend Setup
# This script checks if the required Azure resources exist for Terraform state storage

set -e

echo "=============================================="
echo "Terraform Backend Verification"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "\n${YELLOW}[INFO]${NC} Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Not logged into Azure CLI. Run 'az login' first."
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)
echo -e "${GREEN}[SUCCESS]${NC} Authenticated to subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Expected values
RESOURCE_GROUP="rg-sentinel-kql-terraform"
STORAGE_ACCOUNT="tfstatesentinelkql"
CONTAINER_NAME="tfstate"

echo -e "\n${YELLOW}[INFO]${NC} Checking for resource group: $RESOURCE_GROUP"
if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Resource group '$RESOURCE_GROUP' exists"
    LOCATION=$(az group show --name "$RESOURCE_GROUP" --query location --output tsv)
    echo -e "           Location: $LOCATION"
else
    echo -e "${RED}[ERROR]${NC} Resource group '$RESOURCE_GROUP' not found"
    echo -e "         Create it in Azure Portal or run:"
    echo -e "         az group create --name '$RESOURCE_GROUP' --location 'East US'"
    exit 1
fi

echo -e "\n${YELLOW}[INFO]${NC} Checking for storage account: $STORAGE_ACCOUNT"
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Storage account '$STORAGE_ACCOUNT' exists"
    
    # Get storage account details
    STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query '[0].value' --output tsv)
    echo -e "           Resource Group: $RESOURCE_GROUP"
    echo -e "           Account Name: $STORAGE_ACCOUNT"
    echo -e "           Access Key: ${STORAGE_KEY:0:10}... (truncated)"
else
    echo -e "${RED}[ERROR]${NC} Storage account '$STORAGE_ACCOUNT' not found in resource group '$RESOURCE_GROUP'"
    echo -e "         Create it in Azure Portal or run the commands below"
    exit 1
fi

echo -e "\n${YELLOW}[INFO]${NC} Checking for blob container: $CONTAINER_NAME"
if az storage container show --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --account-key "$STORAGE_KEY" &>/dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Blob container '$CONTAINER_NAME' exists"
else
    echo -e "${YELLOW}[WARNING]${NC} Blob container '$CONTAINER_NAME' not found"
    echo -e "${YELLOW}[INFO]${NC} Creating blob container..."
    
    if az storage container create --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --account-key "$STORAGE_KEY" --public-access off; then
        echo -e "${GREEN}[SUCCESS]${NC} Created blob container '$CONTAINER_NAME'"
    else
        echo -e "${RED}[ERROR]${NC} Failed to create blob container"
        exit 1
    fi
fi

echo -e "\n${GREEN}[SUCCESS]${NC} All Terraform backend resources are ready!"

echo -e "\n=============================================="
echo -e "Terraform Backend Configuration"
echo -e "=============================================="
echo -e "Resource Group:    $RESOURCE_GROUP"
echo -e "Storage Account:   $STORAGE_ACCOUNT"
echo -e "Container:         $CONTAINER_NAME"
echo -e "Key:               terraform.tfstate"

echo -e "\n=============================================="
echo -e "GitHub Secrets Needed"
echo -e "=============================================="
echo -e "TERRAFORM_BACKEND_RESOURCE_GROUP: $RESOURCE_GROUP"
echo -e "TERRAFORM_BACKEND_STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
echo -e "TERRAFORM_BACKEND_ACCESS_KEY: $STORAGE_KEY"

echo -e "\n${YELLOW}[INFO]${NC} Setting GitHub secrets for Terraform backend..."

# Set GitHub secrets for the backend
if command -v gh &> /dev/null; then
    echo "$RESOURCE_GROUP" | gh secret set TERRAFORM_BACKEND_RESOURCE_GROUP
    echo "$STORAGE_ACCOUNT" | gh secret set TERRAFORM_BACKEND_STORAGE_ACCOUNT  
    echo "$STORAGE_KEY" | gh secret set TERRAFORM_BACKEND_ACCESS_KEY
    
    echo -e "${GREEN}[SUCCESS]${NC} GitHub secrets configured for Terraform backend!"
else
    echo -e "${YELLOW}[WARNING]${NC} GitHub CLI (gh) not found. Set these secrets manually:"
    echo -e "  gh secret set TERRAFORM_BACKEND_RESOURCE_GROUP --body '$RESOURCE_GROUP'"
    echo -e "  gh secret set TERRAFORM_BACKEND_STORAGE_ACCOUNT --body '$STORAGE_ACCOUNT'"
    echo -e "  gh secret set TERRAFORM_BACKEND_ACCESS_KEY --body '$STORAGE_KEY'"
fi

echo -e "\n${GREEN}[SUCCESS]${NC} Terraform backend verification complete!"
echo -e "${YELLOW}[NEXT STEP]${NC} You can now run 'terraform init' or trigger the GitHub Actions workflow"
