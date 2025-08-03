# Azure Sentinel KQL Testing Infrastructure

This Terraform configuration creates a comprehensive Azure testing environment for validating KQL queries against Microsoft Sentinel. The infrastructure generates real security events and logs that can be used to test and develop KQL hunting queries, analytics rules, and workbooks.

## 🏗️ Infrastructure Overview

The deployment creates:

- **Log Analytics Workspace** - Core logging platform for Sentinel
- **Microsoft Sentinel** - SIEM/SOAR platform with data connectors
- **Test Virtual Machine** - Windows VM generating security events
- **Virtual Network** - Isolated network environment with NSG flow logs
- **Storage Account** - For log storage and retention
- **Key Vault** - For secrets management and audit logs
- **Network Security Group** - With diagnostic logging enabled
- **Sample Analytics Rules** - Pre-configured detection rules for testing

## 💰 Cost Estimation

**Monthly costs (approximate):**
- Log Analytics: $2-10 per GB ingested
- Sentinel: $2-4 per GB ingested  
- Test VM (Standard_B2s): $30-50
- Storage Account: $1-5
- Key Vault: $1-3
- **Total: ~$35-75/month** (depending on data volume)

## 🚀 Quick Start

### Option 1: GitHub Actions (Recommended)

For automated CI/CD deployment with GitHub Actions:

1. **One-time setup:**
```bash
cd sentinel-kql-queries/terraform
chmod +x setup-github-actions.sh
./setup-github-actions.sh
```

2. **Deploy via GitHub Actions:**
   - Go to your GitHub repository → Actions
   - Select "Deploy Azure Sentinel KQL Testing Infrastructure"
   - Choose action (`plan`/`apply`/`destroy`) and environment (`dev`/`staging`/`prod`)
   - Click "Run workflow"

📖 **Detailed GitHub Actions guide:** [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md)

### Option 2: Local Terraform Deployment

For local development and testing:

#### Prerequisites

1. **Azure CLI** installed and authenticated
```bash
az login
az account set --subscription "Your-Subscription-ID"
```

2. **Terraform** installed (version >= 1.0)
```bash
# macOS
brew install terraform

# Or download from https://www.terraform.io/downloads
```

3. **Required Azure permissions:**
   - Contributor role on target subscription
   - User Access Administrator (for role assignments)

#### Deployment Steps

1. **Clone and navigate to the terraform directory:**
```bash
cd sentinel-kql-queries/terraform
```

2. **Configure variables:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

3. **Initialize Terraform:**
```bash
terraform init
```

4. **Review the deployment plan:**
```bash
terraform plan
```

5. **Deploy the infrastructure:**
```bash
terraform apply
```

6. **Access your environment:**
   - Sentinel workspace URL will be displayed in outputs
   - Log Analytics query interface URL provided
   - VM credentials available in Key Vault

## 📝 Configuration Options

### Key Variables in `terraform.tfvars`

```hcl
# Basic settings
project_name = "sentinel-kql-test"
environment  = "dev"
location     = "East US"

# Cost optimization
log_analytics_retention_days = 30
log_analytics_daily_quota_gb = 1
vm_size                     = "Standard_B2s"

# Feature toggles
create_test_vms     = true
enable_sentinel     = true
enable_key_vault    = true
enable_flow_logs    = true
```

### Environment Profiles

**Development (Low Cost):**
```hcl
log_analytics_retention_days = 30
log_analytics_daily_quota_gb = 1
create_test_vms             = true
vm_size                     = "Standard_B2s"
enable_flow_logs           = false
```

**Production/Training:**
```hcl
log_analytics_retention_days = 90
log_analytics_daily_quota_gb = 10
create_test_vms             = true
vm_size                     = "Standard_D2s_v3"
enable_flow_logs           = true
```

## 🔍 Testing Your KQL Queries

### 1. Access Log Analytics

Use the output URL or navigate to:
- Azure Portal → Log Analytics workspaces → Your workspace → Logs

### 2. Available Data Sources

The infrastructure generates logs from:

- **SecurityEvent** - Windows security events from test VM
- **AzureNetworkAnalytics_CL** - NSG flow logs
- **AzureActivity** - Azure resource activity logs
- **KeyVaultData** - Key Vault access and audit logs
- **AzureDiagnostics** - Resource diagnostic logs

### 3. Sample KQL Queries

```kql
// Failed logon attempts from test VM
SecurityEvent
| where EventID == 4625
| where TimeGenerated > ago(24h)
| summarize FailedAttempts = count() by Account, Computer
| order by FailedAttempts desc

// Network traffic analysis
AzureNetworkAnalytics_CL  
| where TimeGenerated > ago(1h)
| summarize Flows = count() by SrcIP_s, DestIP_s, DestPort_d
| order by Flows desc

// Key Vault access events
KeyVaultData
| where TimeGenerated > ago(24h)
| where OperationName in ("SecretGet", "SecretSet", "SecretDelete")
| project TimeGenerated, OperationName, CallerIPAddress, Identity
```

### 4. Analytics Rules Testing

Pre-configured rules for testing:
- **Multiple Failed Logins** - Detects brute force attempts
- **Suspicious Network Activity** - Unusual traffic patterns
- **Key Vault Anomalies** - Irregular vault access

## 🛠️ Customization

### Adding Custom Analytics Rules

Edit `sentinel.tf` and add:

```hcl
resource "azurerm_sentinel_alert_rule_scheduled" "custom_rule" {
  name                       = "Custom Detection Rule"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name              = "Custom Detection Rule"
  severity                  = "Medium"
  query                     = <<QUERY
SecurityEvent
| where EventID == 4624
| where TimeGenerated > ago(5m)
// Your custom logic here
QUERY
  query_frequency           = "PT5M"
  query_period             = "PT5M"
  trigger_operator         = "GreaterThan"
  trigger_threshold        = 0
}
```

### Adding Data Connectors

Add to `sentinel.tf`:

```hcl
resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
  name                       = "aad-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}
```

## 🔒 Security Best Practices

1. **Access Control:**
   - Use Azure RBAC for workspace access
   - Implement least privilege principles
   - Enable MFA for all admin accounts

2. **Data Protection:**
   - Configure data retention policies
   - Enable storage encryption
   - Implement network access restrictions

3. **Monitoring:**
   - Enable Azure Security Center
   - Configure alert notifications
   - Monitor costs and usage

## 🧪 Generating Test Data

### Windows VM Security Events

Connect to the test VM and generate events:

```powershell
# Failed authentication attempts
net user testuser wrongpassword 2>$null

# Process creation events  
powershell.exe -Command "Get-Process"

# File access events
Get-Content C:\Windows\System32\drivers\etc\hosts
```

### Network Traffic

Generate network activity:

```bash
# From your local machine
nmap -sS <VM_PUBLIC_IP>
curl -I http://<VM_PUBLIC_IP>
```

## 📊 Monitoring and Troubleshooting

### Check Data Ingestion

```kql
Heartbeat
| where TimeGenerated > ago(15m)
| summarize count() by Computer

Usage
| where TimeGenerated > startofday(ago(30d))
| where IsBillable == true
| summarize TotalVolumeGB = sum(Quantity) / 1000 by bin(TimeGenerated, 1d)
| render timechart
```

### Common Issues

1. **No data in workspace:**
   - Check VM monitoring agent status
   - Verify NSG allows traffic
   - Confirm diagnostic settings enabled

2. **High costs:**
   - Review daily quota settings
   - Check retention policies
   - Monitor data ingestion rates

3. **Missing logs:**
   - Verify data connector configuration
   - Check Azure resource diagnostic settings
   - Confirm workspace permissions

## 🧹 Cleanup

To avoid ongoing costs:

```bash
# Destroy all resources
terraform destroy

# Or selectively disable expensive resources
terraform apply -var="create_test_vms=false" -var="enable_flow_logs=false"
```

## 📚 Additional Resources

- [KQL Quick Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Sentinel Documentation](https://docs.microsoft.com/en-us/azure/sentinel/)
- [Log Analytics Query Examples](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/example-queries)
- [KQL Learning Path](https://docs.microsoft.com/en-us/learn/paths/sc-200-utilize-kql-for-azure-sentinel/)

## 🤝 Contributing

1. Test your KQL queries against this infrastructure
2. Add new analytics rules and data connectors
3. Improve cost optimization
4. Enhance documentation

---

**⚠️ Important:** This infrastructure is designed for testing and learning. Do not use in production without proper security hardening and compliance review.
