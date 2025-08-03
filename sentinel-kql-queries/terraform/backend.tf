# Backend configuration for Terraform state management
# GitHub Actions will dynamically create and configure the backend storage

terraform {
  backend "azurerm" {
    # Configuration will be provided dynamically by GitHub Actions workflow:
    # - resource_group_name: "terraform-state-rg" 
    # - storage_account_name: "sentinelkqlstate22" (persistent storage account)
    # - container_name: "tfstate"
    # - key: "sentinel-kql-testing.terraform.tfstate"
    # 
    # The workflow will update this file with the actual storage account name
    # and authenticate using ARM environment variables
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "sentinelkqlstate22"
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
