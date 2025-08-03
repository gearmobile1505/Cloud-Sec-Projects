# Test Virtual Machine (Windows)
resource "azurerm_windows_virtual_machine" "test" {
  count               = var.create_test_vms ? 1 : 0
  name                = "${local.resource_prefix}-testvm"
  computer_name       = "testvm-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B2s"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.test_vm[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = local.common_tags
}

# VM Extension for Microsoft Monitoring Agent
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

# Security Center Workspace (Auto provisioning is deprecated)
resource "azurerm_security_center_workspace" "main" {
  count        = var.enable_defender ? 1 : 0
  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.main.id
}

# Key Vault for secrets testing
resource "azurerm_key_vault" "main" {
  count                       = var.enable_key_vault ? 1 : 0
  name                        = "kv-${substr(replace(local.resource_prefix, "-", ""), 0, 11)}-${random_string.suffix.result}"
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
