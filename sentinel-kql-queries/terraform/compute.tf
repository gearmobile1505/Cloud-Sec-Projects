# Test Virtual Machine (Windows)
resource "azurerm_windows_virtual_machine" "test" {
  count               = var.create_test_vms ? 1 : 0
  name                = "${local.resource_prefix}-testvm"
  computer_name       = "sentinelkqltest"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B1s"  # Smallest size: 1 vCPU, 1 GB RAM
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.test_vm[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  # Use Standard disk to reduce costs
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = local.common_tags
}

# Second Test Virtual Machine (Windows) - 2 vCPU
resource "azurerm_windows_virtual_machine" "test2" {
  count               = var.create_test_vms ? 1 : 0
  name                = "${local.resource_prefix}-testvm2"
  computer_name       = "sentineltest2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B2s"  # 2 vCPU, 4 GB RAM
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.test_vm2[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  # Use Standard disk to reduce costs
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = local.common_tags
}

# VM Extension for Microsoft Monitoring Agent (Legacy)
resource "azurerm_virtual_machine_extension" "mma" {
  count                      = var.create_test_vms ? 1 : 0
  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.test[0].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    "workspaceId" = azurerm_log_analytics_workspace.main.workspace_id
  })

  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.main.primary_shared_key
  })

  tags = local.common_tags
}

# Azure Monitor Agent (Modern)
resource "azurerm_virtual_machine_extension" "ama" {
  count                      = var.create_test_vms ? 1 : 0
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.test[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  tags = local.common_tags
}

# Windows Admin Center Extension
resource "azurerm_virtual_machine_extension" "admin_center" {
  count                      = var.create_test_vms ? 1 : 0
  name                       = "AdminCenter"
  virtual_machine_id         = azurerm_windows_virtual_machine.test[0].id
  publisher                  = "Microsoft.AdminCenter"
  type                       = "AdminCenter"
  type_handler_version       = "0.0"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    "port" = "6516"
    "salt" = base64encode("${random_string.admin_center_salt[0].result}")
  })

  tags = local.common_tags

  depends_on = [
    azurerm_virtual_machine_extension.mma,
    azurerm_virtual_machine_extension.ama
  ]
}

# VM Extension for Microsoft Monitoring Agent (Legacy) - Second VM
resource "azurerm_virtual_machine_extension" "mma2" {
  count                      = var.create_test_vms ? 1 : 0
  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.test2[0].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    "workspaceId" = azurerm_log_analytics_workspace.main.workspace_id
  })

  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.main.primary_shared_key
  })

  tags = local.common_tags
}

# Azure Monitor Agent (Modern) - Second VM
resource "azurerm_virtual_machine_extension" "ama2" {
  count                      = var.create_test_vms ? 1 : 0
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.test2[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  tags = local.common_tags
}

# Random salt for Windows Admin Center
resource "random_string" "admin_center_salt" {
  count   = var.create_test_vms ? 1 : 0
  length  = 64
  special = true
}

# Data Collection Rule for Windows Security Events
resource "azurerm_monitor_data_collection_rule" "security_events" {
  count               = var.create_test_vms ? 1 : 0
  name                = "${local.resource_prefix}-security-events-dcr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  description         = "Data collection rule for Windows Security Events"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "LogAnalyticsDestination"
    }
  }

  data_flow {
    streams      = ["Microsoft-WindowsEvent"]
    destinations = ["LogAnalyticsDestination"]
  }

  data_sources {
    windows_event_log {
      streams = ["Microsoft-WindowsEvent"]
      x_path_queries = [
        "Security!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
        "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
        "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]"
      ]
      name = "SecurityEventDataSource"
    }
  }

  tags = local.common_tags
}

# Associate Data Collection Rule with VM
resource "azurerm_monitor_data_collection_rule_association" "security_events" {
  count                   = var.create_test_vms ? 1 : 0
  name                    = "${local.resource_prefix}-security-events-dcra"
  target_resource_id      = azurerm_windows_virtual_machine.test[0].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.security_events[0].id
  description             = "Association between VM and Security Events DCR"
}

# Associate Data Collection Rule with second VM
resource "azurerm_monitor_data_collection_rule_association" "security_events2" {
  count                   = var.create_test_vms ? 1 : 0
  name                    = "${local.resource_prefix}-security-events-dcra2"
  target_resource_id      = azurerm_windows_virtual_machine.test2[0].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.security_events[0].id
  description             = "Association between second VM and Security Events DCR"
}

# Auto-shutdown schedule for cost control
resource "azurerm_dev_test_global_vm_shutdown_schedule" "test" {
  count              = var.create_test_vms ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.test[0].id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = local.common_tags
}

# Auto-shutdown schedule for second VM (cost control)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "test2" {
  count              = var.create_test_vms ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.test2[0].id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = local.common_tags
}

# Security Center Workspace (Note: May already exist in subscription)
# Commented out to avoid conflicts with existing workspace settings
# resource "azurerm_security_center_workspace" "main" {
#   count        = var.enable_defender ? 1 : 0
#   scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
#   workspace_id = azurerm_log_analytics_workspace.main.id
# }

# Key Vault for secrets testing
resource "azurerm_key_vault" "main" {
  count                       = var.enable_key_vault ? 1 : 0
  name                        = "kv-sentinelkql-qg0m374b"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Add access policy for current user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Recover", "Purge"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Purge"
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Recover", "Purge"
    ]
  }

  tags = local.common_tags
}

# Key Vault Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  count                      = var.enable_key_vault ? 1 : 0
  name                       = "${local.resource_prefix}-kv-diagnostics"
  target_resource_id         = azurerm_key_vault.main[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Sample secrets for testing
resource "azurerm_key_vault_secret" "test_secret" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "test-secret"
  value        = "test-secret-value"
  key_vault_id = azurerm_key_vault.main[0].id

  tags = local.common_tags
}
