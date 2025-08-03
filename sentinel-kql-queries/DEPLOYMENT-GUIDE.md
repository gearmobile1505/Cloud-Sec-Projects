# 🚀 Azure Sentinel KQL Testing Environment - Deployment Guide

## 📋 Quick Start

### 1. **Deploy Infrastructure**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. **Enable VM Testing (Optional)**
```bash
# Create terraform.tfvars
echo 'create_test_vms = true' > terraform.tfvars
terraform apply
```

### 3. **Start Testing**
Follow the instructions in `generate-test-events.md`

---

## 🔧 **What Gets Deployed**

### **Core Infrastructure (Always)**
- ✅ **Resource Group**: `sentinel-kql-dev-dev-rg`
- ✅ **Log Analytics Workspace**: With 30-day retention
- ✅ **Microsoft Sentinel**: Enabled with alert rules
- ✅ **Key Vault**: For testing access anomalies
- ✅ **Storage Account**: For diagnostics
- ✅ **Virtual Network**: With security groups
- ✅ **Alert Rules**: Pre-configured detection rules
- ✅ **Watchlists**: Known good IPs list

### **VM Testing Components (Optional)**
- ✅ **Windows Server 2022 VM**: Standard_B1s (cost-optimized)
- ✅ **Microsoft Monitoring Agent (MMA)**: Legacy Log Analytics connection
- ✅ **Azure Monitor Agent (AMA)**: Modern data collection
- ✅ **Data Collection Rules**: Automated Windows Security Event collection
- ✅ **Auto-shutdown**: Configured for cost control
- ✅ **Network Interface & Public IP**: For RDP access

---

## 💡 **Key Improvements from Testing**

### **✅ Infrastructure Stability**
- **Before**: Random resource names created duplicates on each deployment
- **After**: Fixed resource naming prevents duplicate resource creation
- **Result**: Consistent environment with predictable resource names

**Fixed Resource Names:**
- Resource Group: `sentinel-kql-dev-dev-rg`
- Log Analytics: `sentinel-kql-dev-dev-law-qg0m374b`
- Storage Account: `sentinelkqldevlogs` (standardized)
- Key Vault: `kv-sentinelkql-qg0m374b`
- VM Computer: `sentinelkqltest` (consistent for queries)

### **✅ Automated Agent Setup**
- **Before**: Manual agent installation and configuration required
- **After**: Terraform automatically installs both MMA and AMA agents
- **Result**: VM security events work immediately after deployment

### **✅ Dual Data Collection**
- **Legacy Support**: MMA agent for SecurityEvent table
- **Modern Support**: AMA + DCR for WindowsEvent table  
- **Result**: Compatible with all detection queries

### **✅ Comprehensive Monitoring**
- **Security Events**: Event IDs 4625, 4688, etc.
- **System Events**: Application and System logs
- **Key Vault Access**: Audit events for anomaly detection
- **Network Security**: NSG flow logs

---

## 🎯 **Testing Scenarios**

### **1. Key Vault Access Anomalies** ✅ **WORKING**
```bash
# This works immediately after deployment
VAULT_NAME=$(az keyvault list --resource-group sentinel-kql-dev-dev-rg --query "[0].name" -o tsv)
for i in {1..20}; do
    az keyvault secret show --name "test-secret" --vault-name $VAULT_NAME --query "value" -o tsv >/dev/null
done
```

### **2. Windows Security Events** ✅ **AUTOMATED**
- **RDP Login Attempts**: Manual testing via Remote Desktop
- **PowerShell Execution**: Suspicious command detection  
- **User Account Changes**: Admin privilege escalation
- **File System Activity**: Rapid creation/deletion patterns

### **3. High-Risk IP Detection** ⚠️ **REQUIRES REAL DATA**
- Uses external threat intelligence feeds
- Monitors for authentication from known bad IPs
- Best tested by monitoring the rule rather than simulation

---

## ⚙️ **Configuration Options**

### **terraform.tfvars Settings**
```hcl
# VM Testing (disabled by default for cost)
create_test_vms = true              # Enable Windows VM for security event testing

# Optional configurations
auto_shutdown_time = "22:00"        # Auto-shutdown time (UTC)
log_retention_days = 30             # Log Analytics retention
daily_quota_gb = 10                 # Daily data ingestion limit
enable_key_vault = true             # Key Vault for access testing
enable_sentinel = true              # Microsoft Sentinel activation
```

### **Cost Management**
- **VM Auto-shutdown**: Prevents accidental overnight charges
- **Standard_B1s VM**: Smallest possible size (1 vCPU, 1GB RAM)
- **Standard LRS Storage**: Cost-optimized disk storage
- **10GB Daily Quota**: Prevents runaway log ingestion costs

---

## 🚨 **Important Notes**

### **Resource Naming Convention**
All resources use the pattern: `sentinel-kql-dev-dev-{resource}`
- Fixed suffix: `-qg0m374b` (prevents naming conflicts)
- Resource Group: `sentinel-kql-dev-dev-rg`
- Log Analytics: `sentinel-kql-dev-dev-law-qg0m374b`
- Key Vault: `kv-sentinelkql-qg0m374b`

### **VM Access**
- **Default Username**: `azureuser` (auto-configured)
- **Password Reset**: Use Azure Portal → VM → Reset Password
- **Network Access**: RDP (3389) and SSH (22) allowed from internet
- **Auto-shutdown**: 22:00 UTC daily (configurable)

### **Data Collection Timeline**
- **Immediate**: Infrastructure deployment
- **2-3 minutes**: Agent installation
- **5-10 minutes**: Data collection starts
- **15-30 minutes**: Alert rules evaluate
- **30+ minutes**: Incidents appear in Sentinel

---

## 🔍 **Verification Queries**

### **Check VM Agent Status**
```kql
Heartbeat
| where TimeGenerated > ago(1h)
| where Computer contains "sentinelkqltest"
| summarize LastHeartbeat = max(TimeGenerated) by Computer, OSType
```

### **Verify Security Event Collection**
```kql
union SecurityEvent, WindowsEvent
| where TimeGenerated > ago(1h)
| where Computer contains "sentinelkqltest"
| summarize EventCount = count() by EventID
| order by EventCount desc
```

### **Check Key Vault Access Logs**
```kql
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where ResourceType == "VAULTS"
| where OperationName == "SecretGet"
| project TimeGenerated, CallerIPAddress, OperationName, ResultSignature
```

---

## 🛠️ **Troubleshooting**

### **VM Not Sending Security Events**
1. **Wait 10-15 minutes** after deployment
2. **Check agent status** in Azure Portal → VM → Extensions
3. **Verify DCR association** in Azure Portal → Monitor → Data Collection Rules
4. **Test with Heartbeat query** to confirm basic connectivity

### **Key Vault Access Not Logging**
1. **Verify diagnostic settings** on Key Vault
2. **Check Log Analytics workspace** connection
3. **Confirm access policy** allows secret operations

### **Alert Rules Not Triggering**
1. **Verify rules are enabled** in Sentinel → Analytics
2. **Check query syntax** manually in Log Analytics
3. **Confirm time windows** match your testing timeline
4. **Review incident configuration** settings

---

## 💰 **Cost Estimation**

### **Without VM** (~$15-25/month)
- Log Analytics Workspace: ~$2-10/GB
- Microsoft Sentinel: ~$2-4/GB  
- Key Vault: ~$1-3/month
- Storage Account: ~$1-5/month

### **With VM** (~$35-75/month)
- Above components PLUS:
- Standard_B1s VM: ~$15-30/month
- Storage for VM disk: ~$4-8/month
- Data transfer: ~$1-5/month

### **Cost Control Features**
- ✅ Auto-shutdown schedule (22:00 UTC)
- ✅ 10GB daily quota limit
- ✅ Standard LRS storage (cheapest option)
- ✅ Smallest VM size (Standard_B1s)

---

## 🚀 **Ready to Deploy!**

This environment is now fully automated and tested. Simply run:

```bash
cd terraform
terraform init
terraform apply
```

All the issues we encountered during testing have been resolved! 🎉
