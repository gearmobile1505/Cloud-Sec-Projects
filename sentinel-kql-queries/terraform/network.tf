# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${local.resource_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Subnets
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefixes["default"]]
}

resource "azurerm_subnet" "security" {
  name                 = "security"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefixes["security"]]
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.test.id
}

# Public IP for test VM
resource "azurerm_public_ip" "test_vm" {
  count               = var.create_test_vms ? 1 : 0
  name                = "${local.resource_prefix}-vm-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Network Interface for test VM
resource "azurerm_network_interface" "test_vm" {
  count               = var.create_test_vms ? 1 : 0
  name                = "${local.resource_prefix}-vm-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test_vm[0].id
  }

  tags = local.common_tags
}

# Network Watcher (use existing one - only 1 allowed per subscription per region)
# Azure automatically creates a default Network Watcher named "NetworkWatcher_<region>"
data "azurerm_network_watcher" "main" {
  name                = "NetworkWatcher_${replace(lower(var.location), " ", "")}"
  resource_group_name = "NetworkWatcherRG"
}

# Alternative: Create Network Watcher only if none exists (commented due to limit)
# resource "azurerm_network_watcher" "main" {
#   name                = "${local.resource_prefix}-nw"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   tags = local.common_tags
# }

# Network Watcher Flow Log
# Note: Commented out due to Azure provider compatibility issues
# Flow logs can be enabled manually in Azure portal if needed for advanced network monitoring
/*
resource "azurerm_network_watcher_flow_log" "main" {
  count                = var.enable_flow_logs ? 1 : 0
  network_watcher_name = data.azurerm_network_watcher.main.name
  resource_group_name  = data.azurerm_network_watcher.main.resource_group_name
  name                 = "${local.resource_prefix}-flowlog"

  target_resource_id = azurerm_network_security_group.test.id
  storage_account_id = azurerm_storage_account.logs.id
  enabled            = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.main.location
    workspace_resource_id = azurerm_log_analytics_workspace.main.id
    interval_in_minutes   = 10
  }

  tags = local.common_tags
}
*/

# Note: NSG diagnostic settings are configured in log-analytics.tf to avoid duplication
