# Backend configuration for Terraform state management
# GitHub Actions will use Azure Storage Backend with environment variables

terraform {
  backend "azurerm" {
    # Configuration provided via environment variables in GitHub Actions:
    # ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
    # TFSTATE_RESOURCE_GROUP_NAME, TFSTATE_STORAGE_ACCOUNT_NAME, TFSTATE_CONTAINER_NAME
    resource_group_name  = "rg-sentinel-kql-terraform"
    storage_account_name = "tfstatesentinelkql"
    container_name       = "tfstate"
    key                  = "sentinel-kql-testing.terraform.tfstate"
  }
}

# Option 2: Local Backend (Default - for testing only)
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# Option 3: Terraform Cloud Backend
# terraform {
#   backend "remote" {
#     organization = "your-org-name"
#     workspaces {
#       name = "sentinel-kql-testing"
#     }
#   }
# }

# To set up Azure Storage Backend:
# 1. Create a storage account and container for Terraform state
# 2. Uncomment the azurerm backend configuration above
# 3. Run: terraform init -reconfigure
# 4. Set ARM_ACCESS_KEY environment variable or use Azure CLI authentication

# Example commands to create storage backend:
# az group create --name rg-sentinel-kql-terraform --location "East US"
# az storage account create --resource-group rg-sentinel-kql-terraform --name tfstatesentinelkql --sku Standard_LRS --encryption-services blob
# az storage container create --name tfstate --account-name tfstatesentinelkql
