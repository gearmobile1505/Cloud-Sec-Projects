# Outputs for Azure Sentinel KQL Testing Infrastructure

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Log Analytics Workspace
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id_value" {
  description = "Workspace ID for connecting agents"
  value       = azurerm_log_analytics_workspace.main.workspace_id
  sensitive   = true
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

# Storage Account
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.logs.name
}

output "storage_account_primary_access_key" {
  description = "Primary access key for storage account"
  value       = azurerm_storage_account.logs.primary_access_key
  sensitive   = true
}

# Virtual Network
output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

# Test VM Information
output "test_vm_name" {
  description = "Name of the test VM"
  value       = var.create_test_vms ? azurerm_windows_virtual_machine.test[0].name : null
}

output "test_vm_public_ip" {
  description = "Public IP address of the test VM"
  value       = var.create_test_vms ? azurerm_public_ip.test_vm[0].ip_address : null
}

output "test_vm_private_ip" {
  description = "Private IP address of the test VM"
  value       = var.create_test_vms ? azurerm_network_interface.test_vm[0].private_ip_address : null
}

# Key Vault
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main[0].name : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main[0].vault_uri : null
}

# Network Security Group
output "network_security_group_name" {
  description = "Name of the network security group"
  value       = azurerm_network_security_group.test.name
}

# Connection Information
output "sentinel_workspace_connection_info" {
  description = "Information for connecting to Sentinel workspace"
  value = {
    workspace_name  = azurerm_log_analytics_workspace.main.name
    resource_group  = azurerm_resource_group.main.name
    location        = azurerm_resource_group.main.location
    subscription_id = data.azurerm_client_config.current.subscription_id
  }
}

# KQL Testing URLs
output "log_analytics_query_url" {
  description = "Direct URL to Log Analytics query interface"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/logs/resourceId/%2Fsubscriptions%2F${data.azurerm_client_config.current.subscription_id}%2FresourceGroups%2F${azurerm_resource_group.main.name}%2Fproviders%2FMicrosoft.OperationalInsights%2Fworkspaces%2F${azurerm_log_analytics_workspace.main.name}"
}

output "sentinel_url" {
  description = "Direct URL to Sentinel workspace"
  value       = var.enable_sentinel ? "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/blade/Microsoft_Azure_Security_Insights/WorkspaceSelectorBlade/subscriptionId/${data.azurerm_client_config.current.subscription_id}/resourceGroup/${azurerm_resource_group.main.name}/workspaceName/${azurerm_log_analytics_workspace.main.name}" : null
}

# Cost Estimation
output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost in USD (approximate)"
  value = {
    log_analytics_data_ingestion = "~$2-10 per GB ingested"
    log_analytics_retention      = "~$0.10 per GB per month for retention > 31 days"
    sentinel                     = "~$2-4 per GB ingested"
    test_vm                      = var.create_test_vms ? "~$30-50 per month for Standard_B2s" : "Not created"
    storage_account              = "~$1-5 per month"
    key_vault                    = var.enable_key_vault ? "~$1-3 per month" : "Not created"
    total_estimated              = "$35-75 per month (depending on data volume)"
  }
}
