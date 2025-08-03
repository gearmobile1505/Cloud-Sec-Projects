# GitHub Actions CI/CD for Azure Sentinel KQL Testing

This directory contains Terraform infrastructure code and GitHub Actions workflows to automatically deploy Azure Sentinel testing environments for KQL query validation.

## 🚀 Quick Start with GitHub Actions

### 1. Prerequisites

- GitHub repository with this code
- Azure subscription with appropriate permissions
- GitHub CLI and Azure CLI installed locally (for setup)

**📋 Need help getting Azure credentials?** 
See our detailed guide: **[AZURE_AUTHENTICATION_SETUP.md](AZURE_AUTHENTICATION_SETUP.md)**

### 2. One-Time Setup

Run the setup script to configure GitHub Actions:

```bash
cd sentinel-kql-queries/terraform
chmod +x setup-github-actions.sh
./setup-github-actions.sh
```

This script will:
- Create an Azure Service Principal
- Set GitHub repository secrets
- Configure GitHub environments (dev, staging, prod)

### 3. Deploy Infrastructure

There are three ways to deploy:

#### Option A: Manual Workflow Trigger
1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Deploy Azure Sentinel KQL Testing Infrastructure**
4. Click **Run workflow**
5. Choose:
   - **Action**: `plan` (to preview) or `apply` (to deploy)
   - **Environment**: `dev`, `staging`, or `prod`

#### Option B: Automatic on Push
- Push changes to `main` branch
- Workflow automatically runs `terraform plan`
- Manual approval required for `apply`

#### Option C: Pull Request Preview
- Create a pull request with Terraform changes
- Workflow runs `terraform plan`
- Plan results posted as PR comment

## 🔧 Workflow Features

### Available Actions

| Action | Description | When to Use |
|--------|-------------|-------------|
| `plan` | Show planned changes without deploying | Preview infrastructure changes |
| `apply` | Deploy the infrastructure | Create testing environment |
| `destroy` | Remove all resources | Clean up to avoid costs |

### Environment Management

| Environment | Purpose | Auto-Deploy |
|-------------|---------|-------------|
| `dev` | Development and testing | Yes (on main branch) |
| `staging` | Pre-production validation | Manual approval |
| `prod` | Production-like environment | Manual approval |

### Cost Optimization Features

The workflow includes automatic cost optimization:
- ✅ Daily quota limits on Log Analytics
- ✅ Auto-shutdown for VMs at 7 PM
- ✅ Standard tier storage (LRS)
- ✅ Minimal VM sizes (Standard_B2s)
- ✅ Flow logs disabled in CI/CD (optional in manual)

## 📋 Workflow Configuration

### GitHub Secrets (Automatically Configured)

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Service principal credentials JSON |
| `ARM_CLIENT_ID` | Azure service principal client ID |
| `ARM_CLIENT_SECRET` | Azure service principal client secret |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `ARM_TENANT_ID` | Azure tenant ID |

### Workflow Triggers

```yaml
# Manual trigger with options
workflow_dispatch:
  inputs:
    action: [plan, apply, destroy]
    environment: [dev, staging, prod]

# Automatic on code changes
push:
  branches: [main]
  paths: ['sentinel-kql-queries/terraform/**']

# Preview on pull requests  
pull_request:
  branches: [main]
  paths: ['sentinel-kql-queries/terraform/**']
```

## 🏗️ Infrastructure Components

The workflow deploys:

### Core Services
- **Log Analytics Workspace** - Central logging platform
- **Microsoft Sentinel** - SIEM/SOAR with data connectors
- **Storage Account** - For logs and Terraform state

### Testing Resources
- **Windows Test VM** - Generates security events
- **Virtual Network** - Isolated network environment
- **Network Security Group** - With diagnostic logging
- **Key Vault** - For secrets and audit logs

### Monitoring & Security
- **Azure Security Center** - Security recommendations
- **VM Insights** - Performance monitoring
- **Diagnostic Settings** - Comprehensive logging
- **Sample Analytics Rules** - Pre-configured detections

## 📊 Monitoring Deployments

### Workflow Status
Monitor deployments in the GitHub Actions tab:
- ✅ Green: Successful deployment
- ❌ Red: Failed deployment (check logs)
- 🟡 Yellow: In progress

### Terraform Outputs
After successful deployment, outputs are available:
- **Artifacts**: Download `terraform-outputs-{env}-{run_number}`
- **Step Summary**: View outputs in workflow summary
- **Workspace URLs**: Direct links to Sentinel and Log Analytics

### Cost Monitoring
Track costs in Azure Cost Management:
- Filter by resource tags: `DeployedBy: GitHub Actions`
- Monitor by environment: `Environment: dev/staging/prod`
- Review daily spend alerts

## 🧪 Testing KQL Queries

### 1. Access Your Environment

After deployment, access via output URLs:
```bash
# Get deployment outputs
gh run download <run_id> --name terraform-outputs-dev-<run_number>
cat terraform_outputs.json | jq '.sentinel_url.value'
```

### 2. Sample KQL Queries

Test with these queries in Log Analytics:

```kql
// Security events from test VM
SecurityEvent
| where TimeGenerated > ago(1h)
| where EventID in (4624, 4625, 4648)
| summarize count() by EventID, Account
| order by count_ desc

// Azure activity logs
AzureActivity  
| where TimeGenerated > ago(24h)
| where OperationNameValue contains "Microsoft.Compute"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue

// Key Vault operations
KeyVaultData
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, CallerIPAddress, ResultSignature
```

### 3. Analytics Rules Testing

Pre-deployed rules for testing:
- **Multiple Failed Logins** - Brute force detection
- **Suspicious Network Activity** - Anomalous traffic
- **Key Vault Anomalies** - Unusual access patterns

## 🛠️ Customization

### Modify Infrastructure

1. **Update Terraform files** in `sentinel-kql-queries/terraform/`
2. **Commit changes** to feature branch
3. **Create pull request** to preview changes
4. **Merge to main** to deploy changes

### Add Custom Analytics Rules

Add to `sentinel.tf`:

```hcl
resource "azurerm_sentinel_alert_rule_scheduled" "custom_rule" {
  name = "my-custom-rule"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name = "My Custom Detection"
  severity = "Medium"
  query = <<QUERY
SecurityEvent
| where EventID == 4625
| where TimeGenerated > ago(5m)
// Custom logic here
QUERY
  query_frequency = "PT5M"
  query_period = "PT5M"
  trigger_operator = "GreaterThan"
  trigger_threshold = 5
}
```

### Environment-Specific Configuration

Modify workflow to use different configurations per environment:

```yaml
- name: Set Environment Variables
  run: |
    if [ "${{ github.event.inputs.environment }}" == "prod" ]; then
      echo "TF_VAR_vm_size=Standard_D4s_v3" >> $GITHUB_ENV
      echo "TF_VAR_log_analytics_daily_quota_gb=10" >> $GITHUB_ENV
    else
      echo "TF_VAR_vm_size=Standard_B2s" >> $GITHUB_ENV
      echo "TF_VAR_log_analytics_daily_quota_gb=1" >> $GITHUB_ENV
    fi
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Authentication Failures
```
Error: Error building ARM Config: obtain subscription
```
**Solution**: Re-run setup script to refresh service principal credentials

#### 2. Resource Naming Conflicts
```
Error: Storage account name already exists
```
**Solution**: The workflow uses run numbers for uniqueness, but conflicts can occur

#### 3. Terraform State Locking
```
Error: Error acquiring the state lock
```
**Solution**: Previous workflow may have failed, manually unlock or wait 20 minutes

#### 4. Cost Limit Exceeded
```
Error: Quota exceeded for this subscription
```
**Solution**: Check Azure quotas and cost management settings

### Debugging Steps

1. **Check workflow logs** in GitHub Actions
2. **Review Terraform plan** before applying
3. **Verify Azure permissions** for service principal
4. **Monitor Azure costs** in Cost Management
5. **Check resource group** for partial deployments

### Get Help

- **Workflow issues**: Check GitHub Actions logs
- **Terraform errors**: Review plan output in PR comments
- **Azure resources**: Use Azure Portal for resource investigation
- **Costs**: Monitor in Azure Cost Management + Billing

## 🧹 Cleanup

### Destroy Infrastructure
```bash
# Via GitHub Actions
# Go to Actions → Run workflow → Choose "destroy"

# Or trigger via CLI
gh workflow run azure-sentinel-deploy.yml --ref main -f action=destroy -f environment=dev
```

### Remove GitHub Configuration
```bash
cd sentinel-kql-queries/terraform  
./setup-github-actions.sh cleanup
```

This removes the Azure Service Principal and associated permissions.

---

**💡 Pro Tips:**
- Use `plan` action first to preview changes
- Monitor costs daily during active testing
- Use `destroy` action immediately after testing
- Keep multiple environments for different test scenarios
- Review security scan results in PR checks
