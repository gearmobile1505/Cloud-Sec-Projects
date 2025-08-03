# Sentinel Data Connectors

# Azure Activity Data Connector
resource "azurerm_sentinel_data_connector_azure_active_directory" "main" {
  count                      = var.enable_sentinel && var.enable_data_connectors ? 1 : 0
  name                       = "AzureActiveDirectory"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# Azure Security Center Data Connector
resource "azurerm_sentinel_data_connector_azure_security_center" "main" {
  count                      = var.enable_sentinel && var.enable_data_connectors ? 1 : 0
  name                       = "AzureSecurityCenter"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# Office 365 Data Connector
resource "azurerm_sentinel_data_connector_office_365" "main" {
  count                      = var.enable_sentinel && var.enable_data_connectors ? 1 : 0
  name                       = "Office365"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  exchange_enabled   = true
  sharepoint_enabled = true
  teams_enabled      = true
}

# Sample Analytics Rule - Suspicious Sign-in Activity
resource "azurerm_sentinel_alert_rule_scheduled" "suspicious_signin" {
  count                      = var.enable_sentinel ? 1 : 0
  name                       = "Suspicious Sign-in Activity"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name               = "Suspicious Sign-in Activity Detection"

  severity = "High"
  enabled  = true

  query_frequency   = "PT1H" # Every hour
  query_period      = "PT1H" # Look back 1 hour
  trigger_threshold = 1

  query = <<QUERY
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType != 0  // Failed sign-ins
| where IPAddress !startswith "10." and IPAddress !startswith "192.168." and IPAddress !startswith "172."
| summarize FailedAttempts = count(), Countries = make_set(LocationDetails.countryOrRegion), IPs = make_set(IPAddress) by UserPrincipalName
| where FailedAttempts >= 5
| project UserPrincipalName, FailedAttempts, Countries, IPs
QUERY

  description = "Detects suspicious sign-in activities with multiple failed attempts from external IPs"

  tactics = ["InitialAccess", "CredentialAccess"]
}

# Sample Analytics Rule - High-Risk IP Activity
resource "azurerm_sentinel_alert_rule_scheduled" "high_risk_ip" {
  count                      = var.enable_sentinel ? 1 : 0
  name                       = "High-Risk IP Activity"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name               = "Activity from High-Risk IP Addresses"

  severity = "Medium"
  enabled  = true

  query_frequency   = "PT6H" # Every 6 hours
  query_period      = "P1D"  # Look back 1 day
  trigger_threshold = 1

  query = <<QUERY
let RiskyIPs = externaldata(IPAddress: string)
[@"https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt"] 
with (format="txt", ignoreFirstRecord=true)
| where IPAddress matches regex @"\d+\.\d+\.\d+\.\d+"
| extend IPAddress = trim_start(@"[0-9]+\s+", IPAddress)
| distinct IPAddress;
SigninLogs
| where TimeGenerated > ago(1d)
| where IPAddress in (RiskyIPs)
| project TimeGenerated, UserPrincipalName, IPAddress, Location, AppDisplayName, ResultType
QUERY

  description = "Detects authentication attempts from known high-risk IP addresses"

  tactics = ["InitialAccess", "Persistence"]
}

# Sample Analytics Rule - Key Vault Access Anomalies
resource "azurerm_sentinel_alert_rule_scheduled" "keyvault_anomalies" {
  count                      = var.enable_sentinel && var.enable_key_vault ? 1 : 0
  name                       = "Key Vault Access Anomalies"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name               = "Unusual Key Vault Access Patterns"

  severity = "Medium"
  enabled  = true

  query_frequency   = "PT4H" # Every 4 hours
  query_period      = "P7D"  # Look back 7 days
  trigger_threshold = 1

  query = <<QUERY
KeyVaultDiagnostics
| where TimeGenerated > ago(7d)
| where OperationName == "SecretGet" or OperationName == "KeyGet"
| summarize AccessCount = count() by CallerIPAddress, bin(TimeGenerated, 1h)
| summarize avg(AccessCount), max(AccessCount), count() by CallerIPAddress
| where max_AccessCount > (avg_AccessCount * 3) and count_ > 24  // Anomalous access pattern
| project CallerIPAddress, AverageAccess = avg_AccessCount, MaxAccess = max_AccessCount, Hours = count_
QUERY

  description = "Detects unusual access patterns to Key Vault secrets and keys"

  tactics = ["Collection", "CredentialAccess"]
}

# Watchlist for Known Good IPs (for testing exclusions)
resource "azurerm_sentinel_watchlist" "known_good_ips" {
  count                      = var.enable_sentinel ? 1 : 0
  name                       = "KnownGoodIPs"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name               = "Known Good IP Addresses"
  description                = "List of trusted IP addresses for exclusion from alerts"

  labels = ["IP", "TrustedSource"]

  default_duration = "P30D"

  item_search_key = "IPAddress"
}
