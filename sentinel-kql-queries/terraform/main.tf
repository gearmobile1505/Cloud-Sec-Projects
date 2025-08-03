# Azure Sentinel KQL Testing Infrastructure
# This Terraform configuration creates Azure resources to test Sentinel KQL queries
# It includes Log Analytics Workspace, Sentinel, and various Azure services to generate test data

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {}

# Data sources
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = "Sentinel-KQL-Testing"
    CreatedBy   = "Terraform"
    Purpose     = "KQL-Query-Testing"
  }

  resource_prefix = "${var.project_name}-${var.environment}"
}
