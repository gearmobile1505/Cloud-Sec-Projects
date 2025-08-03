# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "sentinel-kql-dev-dev-rg"
  location = var.location

  tags = local.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "sentinel-kql-dev-dev-law-qg0m374b"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.daily_quota_gb

  tags = local.common_tags
}

# Microsoft Sentinel
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "main" {
  count                        = var.enable_sentinel ? 1 : 0
  workspace_id                 = azurerm_log_analytics_workspace.main.id
  customer_managed_key_enabled = false
}

# Storage Account for logs and diagnostics
resource "azurerm_storage_account" "logs" {
  name                     = "logsentinelkqlqg0m374b"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable security features
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  tags = local.common_tags
}

# Advanced Threat Protection for Storage (Classic plan deprecated)
# The classic Defender for Storage plan is no longer available
# Use the new Defender for Storage plan via Azure Security Center instead
# resource "azurerm_advanced_threat_protection" "storage" {
#   count              = var.enable_storage_threats ? 1 : 0
#   target_resource_id = azurerm_storage_account.logs.id
#   enabled            = true
# }

# Network Security Group with intentional misconfigurations for testing
resource "azurerm_network_security_group" "test" {
  name                = "${local.resource_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Intentionally insecure rule for testing
  security_rule {
    name                       = "AllowSSHFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # Intentionally broad for testing
    destination_address_prefix = "*"
  }

  # Another test rule
  security_rule {
    name                       = "AllowRDPFromInternet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*" # Intentionally broad for testing
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Send NSG flow logs to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "${local.resource_prefix}-nsg-diagnostics"
  target_resource_id         = azurerm_network_security_group.test.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
