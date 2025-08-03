#!/bin/bash

# Import existing Azure resources into Terraform state
# This script imports the resources that were kept after cleanup

set -e

echo "🔄 Importing existing Azure resources into Terraform state..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP_NAME="sentinel-kql-dev-dev-rg"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo -e "${BLUE}📋 Using subscription: ${SUBSCRIPTION_ID}${NC}"
echo -e "${BLUE}📋 Using resource group: ${RESOURCE_GROUP_NAME}${NC}"

# Set Azure authentication for Terraform
echo -e "${YELLOW}🔐 Setting up Azure authentication for Terraform...${NC}"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
export ARM_USE_CLI=true

# Get storage account key for backend access
echo -e "${YELLOW}🔑 Getting storage account key for backend access...${NC}"
ACCOUNT_KEY=$(az storage account keys list --resource-group terraform-state-rg --account-name sentinelkqlstate22 --query '[0].value' -o tsv)
export ARM_ACCESS_KEY=$ACCOUNT_KEY

echo -e "${BLUE}🔑 ARM_SUBSCRIPTION_ID: ${ARM_SUBSCRIPTION_ID}${NC}"
echo -e "${BLUE}🔑 ARM_TENANT_ID: ${ARM_TENANT_ID}${NC}"
echo -e "${GREEN}✅ Storage account key configured${NC}"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}⚙️ Initializing Terraform...${NC}"
    terraform init \
        -backend-config="resource_group_name=terraform-state-rg" \
        -backend-config="storage_account_name=sentinelkqlstate22" \
        -backend-config="container_name=tfstate" \
        -backend-config="key=sentinel-kql-testing.terraform.tfstate"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Terraform initialization failed${NC}"
        echo -e "${YELLOW}💡 Trying to create backend storage container...${NC}"
        
        # Try to create the container if it doesn't exist
        az storage container create \
            --name tfstate \
            --account-name sentinelkqlstate22 \
            --auth-mode login
        
        # Try initialization again
        terraform init \
            -backend-config="resource_group_name=terraform-state-rg" \
            -backend-config="storage_account_name=sentinelkqlstate22" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=sentinel-kql-testing.terraform.tfstate"
    fi
fi

# Function to import resource if it doesn't exist in state
import_if_not_exists() {
    local terraform_address=$1
    local azure_resource_id=$2
    local resource_name=$3
    
    echo -e "${BLUE}🔍 Checking if $resource_name exists in state...${NC}"
    
    if terraform state show "$terraform_address" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $resource_name already exists in Terraform state${NC}"
    else
        echo -e "${YELLOW}📥 Importing $resource_name...${NC}"
        if terraform import "$terraform_address" "$azure_resource_id"; then
            echo -e "${GREEN}✅ Successfully imported $resource_name${NC}"
        else
            echo -e "${RED}❌ Failed to import $resource_name${NC}"
            return 1
        fi
    fi
}

# Import Resource Group
echo -e "${BLUE}🏗️ Importing Resource Group...${NC}"
import_if_not_exists \
    "azurerm_resource_group.main" \
    "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}" \
    "Resource Group"

# Import Log Analytics Workspace
echo -e "${BLUE}📊 Importing Log Analytics Workspace...${NC}"
LAW_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.OperationalInsights/workspaces/sentinel-kql-dev-law"
import_if_not_exists \
    "azurerm_log_analytics_workspace.main" \
    "$LAW_ID" \
    "Log Analytics Workspace"

# Import Storage Account
echo -e "${BLUE}💾 Importing Storage Account...${NC}"
STORAGE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/sentinelkqldevlogs"
import_if_not_exists \
    "azurerm_storage_account.logs" \
    "$STORAGE_ID" \
    "Storage Account"

# Import Sentinel (if it exists)
echo -e "${BLUE}🛡️ Checking for Microsoft Sentinel...${NC}"
SENTINEL_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.OperationalInsights/workspaces/sentinel-kql-dev-law/providers/Microsoft.SecurityInsights/onboardingStates/default"
import_if_not_exists \
    "azurerm_sentinel_log_analytics_workspace_onboarding.main" \
    "$SENTINEL_ID" \
    "Microsoft Sentinel"

# Import Virtual Network (if it exists)
echo -e "${BLUE}🌐 Checking for Virtual Network...${NC}"
VNET_ID="/subscriptions/${RESOURCE_GROUP_NAME}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/sentinel-kql-dev-vnet"
if az network vnet show --resource-group "$RESOURCE_GROUP_NAME" --name "sentinel-kql-dev-vnet" >/dev/null 2>&1; then
    import_if_not_exists \
        "azurerm_virtual_network.main" \
        "$VNET_ID" \
        "Virtual Network"
        
    # Import Subnet
    SUBNET_ID="${VNET_ID}/subnets/internal"
    import_if_not_exists \
        "azurerm_subnet.internal" \
        "$SUBNET_ID" \
        "Subnet"
else
    echo -e "${YELLOW}⚠️ Virtual Network not found, skipping...${NC}"
fi

# Import Key Vault (if it exists and enabled)
echo -e "${BLUE}🔐 Checking for Key Vault...${NC}"
if az keyvault show --resource-group "$RESOURCE_GROUP_NAME" --name "kv-sentinelkqldev" >/dev/null 2>&1; then
    KV_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.KeyVault/vaults/kv-sentinelkqldev"
    import_if_not_exists \
        "azurerm_key_vault.main[0]" \
        "$KV_ID" \
        "Key Vault"
else
    echo -e "${YELLOW}⚠️ Key Vault not found, skipping...${NC}"
fi

# Import VM (if it exists and enabled)
echo -e "${BLUE}💻 Checking for Virtual Machine...${NC}"
if az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "sentinel-kql-dev-testvm" >/dev/null 2>&1; then
    VM_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Compute/virtualMachines/sentinel-kql-dev-testvm"
    import_if_not_exists \
        "azurerm_windows_virtual_machine.test[0]" \
        "$VM_ID" \
        "Virtual Machine"
        
    # Import Network Interface
    NIC_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/networkInterfaces/sentinel-kql-dev-testvm-nic"
    import_if_not_exists \
        "azurerm_network_interface.test[0]" \
        "$NIC_ID" \
        "Network Interface"
else
    echo -e "${YELLOW}⚠️ Virtual Machine not found, skipping...${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Import process completed!${NC}"
echo -e "${BLUE}📋 You can now run 'terraform plan' to see the current state${NC}"
echo -e "${BLUE}📋 Run 'terraform apply' to apply any configuration changes${NC}"
