# 🚨 Generate Security Events for Sentinel Testing

## 🎯 **Quick Start for First-Time Users**

**New to Azure Sentinel?** Follow this simple 3-step process:

1. **📋 Prerequisites Check** → Ensure you have the right access and quotas
2. **🚀 Deploy Infrastructure** → Run Terraform to create your testing environment  
3. **🧪 Generate Test Events** → Use the scripts below to trigger security alerts

---

## 📋 **Prerequisites (REQUIRED)**

### **Azure Access & Permissions**
- ✅ **Azure Subscription** with Owner or Contributor role
- ✅ **Azure CLI installed** and logged in (`az login`)
- ✅ **Terraform installed** (v1.0+ recommended)
- ✅ **Git repository cloned** locally

### **Azure Quotas & Limits**
- ✅ **vCPU Quota**: 4+ vCPUs available (if enabling test VMs)
- ✅ **Log Analytics**: Workspace creation permissions
- ✅ **Key Vault**: Creation permissions in your subscription
- ✅ **Sentinel**: Microsoft Sentinel enabled on your subscription

### **Cost Considerations** 💰
- **Without VMs**: ~$5-15/day (Log Analytics + Sentinel)
- **With VMs**: ~$15-30/day (includes 2 Windows VMs)
- **Auto-shutdown**: VMs stop at 22:00 UTC to save costs
- **Log Analytics limit**: 10GB daily quota to control ingestion costs

---

## 🚀 **Step 1: Deploy Your Testing Environment**

### **Option A: Without Test VMs (Recommended for beginners)**
```bash
# Navigate to the terraform directory
cd Cloud-Sec-Projects/sentinel-kql-queries/terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy the infrastructure
terraform apply -auto-approve
```

### **Option B: With Test VMs (Advanced users)**
```bash
# Navigate to terraform directory
cd Cloud-Sec-Projects/sentinel-kql-queries/terraform

# Create terraform.tfvars file to enable VMs
echo 'create_test_vms = true' > terraform.tfvars

# Check your vCPU quota first
az vm list-usage --location "East US" --query "[?name.value=='Total Regional vCPUs'].{Name:name.value, CurrentValue:currentValue, Limit:limit}" --output table

# Deploy with VMs (requires 4+ vCPU quota)
terraform init
terraform plan
terraform apply -auto-approve
```

### **What Gets Created**
- 🏗️ **Resource Group**: `sentinel-kql-dev-dev-rg`
- 📊 **Log Analytics Workspace**: For storing security events
- 🛡️ **Microsoft Sentinel**: Security monitoring and alerting
- 🔑 **Key Vault**: `kv-sentinelkql-qg0m374b` for testing access patterns
- 🖥️ **Test VMs** (optional): 2 Windows Server VMs for event generation
- 🚨 **Alert Rules**: 4 pre-configured security detection rules

---

## ⚡ **Automated vs Manual Setup**

**🎉 Good News**: All VM monitoring setup is now **fully automated** via Terraform!

- **✅ Automated (Recommended)**: Set `create_test_vms = true` and Terraform handles everything
- **⚙️ Manual Alternative**: Follow the manual setup instructions at the bottom if needed

## Prerequisites
1. Azure Sentinel infrastructure deployed successfully
2. **Test VM is optional** - disabled by default to avoid quota limits
3. **If enabling VM**: Set `create_test_vms = true` in terraform.tfvars and ensure sufficient vCPU quota
4. **Recommended**: Use Azure Cloud Shell or your local machine with Azure CLI for most testing

> **Note**: Test VMs are disabled by default to avoid Azure vCPU quota issues. The testing examples below work with Azure Cloud Shell or any machine with Azure CLI access. Enable VMs only if you need Windows security event generation.

- **✅ Recent Update**: VM monitoring is now fully automated! When you enable VMs (`create_test_vms = true`), Terraform will automatically:
> - Install both Microsoft Monitoring Agent (MMA) and Azure Monitor Agent (AMA)
> - Configure Data Collection Rules for Windows Security Events
> - Set up proper event collection for SecurityEvent and WindowsEvent tables
> - No manual agent configuration needed!

---

## 🔍 **Step 2: Verify Your Deployment**

### **Check Infrastructure Status**
```bash
# Get deployment information
terraform output

# Verify Key Vault is accessible
az keyvault show --name "kv-sentinelkql-qg0m374b" --query "name" -o tsv

# Check if VMs are running (if enabled)
az vm list --resource-group "sentinel-kql-dev-dev-rg" --show-details --query "[].{Name:name, PowerState:powerState, PublicIP:publicIps}" --output table
```

### **Test Log Analytics Connection**
```bash
# Get your workspace ID
WORKSPACE_ID=$(terraform output -raw log_analytics_workspace_id_value)
echo "Workspace ID: $WORKSPACE_ID"

# Test basic query execution
az monitor log-analytics query --workspace "$WORKSPACE_ID" --analytics-query "Heartbeat | take 5" --output table
```

### **Verify Sentinel Alert Rules**
1. **Open Azure Portal** → Search "Microsoft Sentinel"
2. **Select your workspace**: `sentinel-kql-dev-dev-law-xxxxx`
3. **Go to Analytics** → **Active rules**
4. **Confirm 4 rules are active**:
   - ✅ Advanced Multistage Attack Detection (Fusion)
   - ✅ Suspicious Sign-in Activity Detection
   - ✅ Activity from High-Risk IP Addresses  
   - ✅ Unusual Key Vault Access Patterns

---

## 🧪 **Step 3: Generate Test Events**

**Choose your testing approach based on your setup:**

### **🌐 Method 1: Key Vault Testing (Works without VMs)**
This is the **easiest way to start** - works with any Azure CLI access:

---

**Choose your testing approach based on your setup:**

### **🌐 Method 1: Key Vault Testing (Works without VMs)**
This is the **easiest way to start** - works with any Azure CLI access:

```bash
# Navigate to terraform directory first
cd terraform

# Get your Key Vault name
VAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null || echo "kv-sentinelkql-qg0m374b")
echo "Using Key Vault: $VAULT_NAME"

# Verify access
az keyvault show --name $VAULT_NAME --query "name" -o tsv

# Generate 50 rapid access attempts (triggers anomaly detection)
for i in {1..50}; do
    echo "Access attempt $i"
    az keyvault secret show --name "test-secret" --vault-name $VAULT_NAME --query "value" -o tsv 2>/dev/null || echo "Access failed"
    sleep 2
done
```

**What this triggers**: Unusual Key Vault Access Patterns alert (15-30 minutes delay)

### **🖥️ Method 2: Windows VM Testing (Requires VMs enabled)**
If you deployed with `create_test_vms = true`:

#### **Connect to Your VM**
```bash
# Get VM public IP
terraform output test_vm_public_ip

# Connect via RDP using the IP shown
# Username: adminuser
# Password: Check Azure portal → Virtual machines → Reset password
```

#### **Generate Failed Login Events**
Run this **inside the Windows VM**:
```powershell
# Simulate failed RDP attempts (generates Event ID 4625)
$users = @("admin", "administrator", "root", "test", "guest")
foreach ($user in $users) {
    for ($i = 1; $i -le 3; $i++) {
        Write-Host "Simulating failed login for user: $user (attempt $i)"
        Start-Process -FilePath "net" -ArgumentList "use", "\\127.0.0.1\c$", "/user:$user", "wrongpassword" -Wait -NoNewWindow 2>$null
        Start-Sleep 2
    }
}
```

**What this triggers**: Suspicious Sign-in Activity Detection alert

### **🌍 Method 3: High-Risk IP Monitoring (Automatic)**
This alert monitors real threat intelligence automatically - **no action needed**!

**How to check it**:
1. Go to **Sentinel** → **Analytics** → **Activity from High-Risk IP Addresses**
2. Click **"Test with current data"** to see if any risky IPs are detected
3. The query checks against live threat feeds automatically

---

## 🔍 **Alert Rule 1: Suspicious Sign-in Activity**

### What it detects:
- Multiple failed login attempts (5+) from external IPs
- Triggers: High severity alert

### How to trigger:
```powershell
# On the Windows VM, simulate failed RDP attempts
# Method 1: Use PowerShell to simulate failed logins
$users = @("admin", "administrator", "root", "test", "guest")
foreach ($user in $users) {
    for ($i = 1; $i -le 3; $i++) {
        Write-Host "Simulating failed login for user: $user (attempt $i)"
        # This will generate Event ID 4625 (failed logon)
        Start-Process -FilePath "net" -ArgumentList "use", "\\127.0.0.1\c$", "/user:$user", "wrongpassword" -Wait -NoNewWindow 2>$null
        Start-Sleep 2
    }
}
```

### Manual RDP attempts:
1. Get the VM's public IP from Azure portal
2. Use Remote Desktop Connection
3. Try logging in with wrong credentials multiple times:
   - Username: `admin`, Password: `wrongpassword123`
   - Username: `administrator`, Password: `badpassword`
   - Username: `root`, Password: `hackme`

---

## 🌐 **Alert Rule 2: High-Risk IP Activity**

### What it detects:
- Authentication attempts from known malicious IPs
- Uses external threat intelligence feed

### How to trigger:
This alert uses real threat intelligence, so it's harder to simulate. Instead:

1. **Monitor the alert rule** in Sentinel → Analytics
2. **Check the query manually**:
```kql
let RiskyIPs = externaldata(IPAddress: string)
[@"https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt"] 
with (format="txt", ignoreFirstRecord=true)
| where IPAddress matches regex @"\d+\.\d+\.\d+\.\d+"
| extend CleanIP = trim_start(@"[0-9]+\s+", IPAddress)
| distinct CleanIP;
SigninLogs
| where TimeGenerated > ago(1d)
| where IPAddress in (RiskyIPs)
| project TimeGenerated, UserPrincipalName, IPAddress, Location, AppDisplayName, ResultType
```

---

## 🔐 **Alert Rule 3: Key Vault Access Anomalies**

### What it detects:
- Unusual access patterns to Key Vault secrets
- Triggers on 3x normal access volume

### How to trigger:
```bash
# Navigate to terraform directory first (if running from project root)
cd terraform  # Only needed if not already in terraform directory

# Use Azure CLI to repeatedly access Key Vault
# First, get your Key Vault name from the deployed infrastructure
VAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null || echo "kv-sentinelkql-qg0m374b")
echo "Using Key Vault: $VAULT_NAME"

# Verify Key Vault exists and is accessible
az keyvault show --name $VAULT_NAME --query "name" -o tsv

# Then repeatedly access secrets to trigger anomaly detection
for i in {1..50}; do
    echo "Access attempt $i"
    az keyvault secret show --name "test-secret" --vault-name $VAULT_NAME --query "value" -o tsv 2>/dev/null || echo "Access failed"
    sleep 2
done
```

Or use PowerShell on the VM:
```powershell
# Install Azure PowerShell if not installed
Install-Module -Name Az -Force -AllowClobber

# Connect to Azure (you'll be prompted to sign in)
Connect-AzAccount

# Get Key Vault name from Terraform or use the deployed one
$vaultName = "kv-sentinelkql-qg0m374b"  # Current deployed Key Vault
Write-Host "Using Key Vault: $vaultName"

# Verify Key Vault access
try {
    Get-AzKeyVault -VaultName $vaultName | Select-Object VaultName, ResourceGroupName
    Write-Host "✅ Key Vault access confirmed" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot access Key Vault: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Tip: Make sure you're logged into the correct Azure subscription" -ForegroundColor Yellow
    exit
}

# Repeatedly access Key Vault to trigger anomaly detection
Write-Host "🚀 Starting Key Vault access simulation..." -ForegroundColor Cyan
for ($i = 1; $i -le 50; $i++) {
    Write-Host "Key Vault access attempt $i/50" -ForegroundColor Yellow
    try {
        Get-AzKeyVaultSecret -VaultName $vaultName -Name "test-secret" -AsPlainText | Out-Null
        Write-Host "✅ Access $i successful" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Access attempt $i failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    Start-Sleep 3
}
Write-Host "🎉 Completed 50 access attempts! Check Sentinel for alerts in 15-30 minutes." -ForegroundColor Green
```

---

## 🖥️ **Advanced Windows Security Event Generation**

> **⚠️ Note**: These commands require VMs to be enabled (`create_test_vms = true`) and should be run **inside the Windows VM** via RDP.

### **🔐 Method A: Failed Login Simulation (Beginner-Friendly)**
```powershell
# Run this inside your Windows VM to generate Event ID 4625
Write-Host "🚀 Starting failed login simulation..." -ForegroundColor Cyan

$users = @("admin", "administrator", "root", "test", "guest", "oracle", "mysql", "ftp")
foreach ($user in $users) {
    for ($i = 1; $i -le 3; $i++) {
        Write-Host "Simulating failed login for user: $user (attempt $i/3)" -ForegroundColor Yellow
        # This generates Event ID 4625 (failed logon)
        Start-Process -FilePath "net" -ArgumentList "use", "\\127.0.0.1\c$", "/user:$user", "wrongpassword" -Wait -NoNewWindow 2>$null
        Start-Sleep 2
    }
}
Write-Host "✅ Failed login simulation complete! Check Sentinel in 15-30 minutes." -ForegroundColor Green
```

### **🔍 Method B: Suspicious PowerShell Activity (Intermediate)**
```powershell
# Creates Process Creation events (Event ID 4688) that look suspicious
Write-Host "🚀 Generating suspicious PowerShell activity..." -ForegroundColor Cyan

# 1. Hidden PowerShell execution
Write-Host "Creating hidden PowerShell processes..." -ForegroundColor Yellow
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Write-Host 'Test completed'"
powershell.exe -EncodedCommand "VwByaXRlLUhvc3QgJ1Rlc3QgY29tcGxldGVkJw=="

# 2. Simulated download attempts (safe - doesn't actually download)
Write-Host "Simulating download commands..." -ForegroundColor Yellow
powershell.exe -Command "Write-Host 'Simulated: IEX (New-Object Net.WebClient).DownloadString()'"

# 3. Rapid file operations
Write-Host "Creating and deleting files rapidly..." -ForegroundColor Yellow
New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
for ($i = 1; $i -le 10; $i++) {
    New-Item -Path "C:\temp\suspicious_file_$i.txt" -ItemType File -Force | Out-Null
    Remove-Item -Path "C:\temp\suspicious_file_$i.txt" -Force
}

Write-Host "✅ PowerShell activity simulation complete!" -ForegroundColor Green
```

### **🌐 Method C: Network Activity Simulation (Advanced)**
```powershell
# Simulates network scanning behavior
Write-Host "🚀 Starting network activity simulation..." -ForegroundColor Cyan

Write-Host "Testing internal network connectivity..." -ForegroundColor Yellow
# Test common internal network ranges (safe - just connectivity tests)
$subnets = @("192.168.1", "10.0.0", "172.16.1")
foreach ($subnet in $subnets) {
    for ($i = 1; $i -le 5; $i++) {  # Limited to 5 IPs per subnet for safety
        $target = "$subnet.$i"
        Test-NetConnection -ComputerName $target -Port 445 -InformationLevel Quiet -WarningAction SilentlyContinue | Out-Null
        Start-Sleep 1
    }
}

Write-Host "✅ Network simulation complete!" -ForegroundColor Green
```

### **👤 Method D: User Account Events (Expert Level)**
```powershell
# ⚠️ Requires Administrator privileges
Write-Host "🚀 Creating user account events..." -ForegroundColor Cyan

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "💡 Right-click PowerShell and 'Run as Administrator'" -ForegroundColor Yellow
    exit
}

Write-Host "Creating and removing test user accounts..." -ForegroundColor Yellow

# Create test users (generates Event ID 4720)
net user testuser1 TempPassword123! /add /comment:"Test user for security simulation"
net user testuser2 TempPassword123! /add /comment:"Test user for security simulation"

# Add to administrators group (generates Event ID 4728)
net localgroup administrators testuser1 /add
Start-Sleep 2

# Remove from administrators group (generates Event ID 4729)
net localgroup administrators testuser1 /delete
Start-Sleep 2

# Delete users (generates Event ID 4726)
net user testuser1 /delete
net user testuser2 /delete

Write-Host "✅ User account simulation complete!" -ForegroundColor Green
```

---

---

## 📊 **Step 4: Monitor Your Test Results**

### **🎯 For First-Time Users: Simple Monitoring**

#### **1. Check Incidents in Azure Portal**
1. **Open Azure Portal** → Search "Microsoft Sentinel"
2. **Select your workspace** (sentinel-kql-dev-dev-law-xxxxx)
3. **Click "Incidents"** in the left menu
4. **Look for new incidents** with titles like:
   - "Unusual Key Vault Access Patterns"
   - "Suspicious Sign-in Activity Detection"
   - "Activity from High-Risk IP Addresses"

#### **2. Quick Status Check Queries**
Copy these into **Logs** section of your Sentinel workspace:

```kql
// Check if Key Vault testing worked (should show your access attempts)
AzureDiagnostics
| where TimeGenerated > ago(2h)
| where ResourceType == "VAULTS"
| where OperationName in ("SecretGet", "KeyGet", "VaultGet")
| summarize Count = count() by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

```kql
// Check if VMs are sending data (if VMs enabled)
Heartbeat
| where TimeGenerated > ago(1h)
| where Computer contains "sentinel"
| summarize LastHeartbeat = max(TimeGenerated) by Computer
```

### **📈 Expected Timeline for First-Time Users**
- **Immediate (0-2 min)**: Your test commands complete
- **5-10 minutes**: Events appear in Log Analytics
- **15-30 minutes**: Alert rules evaluate and may trigger
- **30+ minutes**: Incidents appear in Sentinel dashboard

### **🔍 Troubleshooting for Beginners**

#### **"I don't see any incidents after 30 minutes"**
1. **Check if testing worked**:
   ```bash
   # Verify Key Vault access was logged
   az monitor log-analytics query --workspace "$(terraform output -raw log_analytics_workspace_id_value)" --analytics-query "AzureDiagnostics | where ResourceType == 'VAULTS' | where TimeGenerated > ago(1h) | count" --output table
   ```

2. **Verify alert rules are enabled**:
   - Go to Sentinel → Analytics → Active rules
   - Ensure all 4 rules show "Enabled" status

3. **Check alert thresholds**:
   - Key Vault anomaly needs 3x normal access (50 attempts should trigger)
   - Failed login needs 5+ attempts
   - Some alerts may take longer to evaluate

#### **"Key Vault access failed"**
1. **Check permissions**:
   ```bash
   # Verify you have access to the Key Vault
   az keyvault show --name "kv-sentinelkql-qg0m374b" --query "properties.accessPolicies[0].permissions" --output table
   ```

2. **Re-run with error details**:
   ```bash
   # More verbose error reporting
   az keyvault secret show --name "test-secret" --vault-name "kv-sentinelkql-qg0m374b" --debug
   ```

#### **"VMs are not responding"**
1. **Check VM power state**:
   ```bash
   az vm list --resource-group "sentinel-kql-dev-dev-rg" --show-details --query "[].{Name:name, PowerState:powerState}" --output table
   ```

2. **Start VMs if stopped**:
   ```bash
   # VMs auto-shutdown at 22:00 UTC - restart them
   az vm start --name "sentinel-kql-test-dev-testvm" --resource-group "sentinel-kql-dev-dev-rg" --no-wait
   az vm start --name "sentinel-kql-test-dev-testvm2" --resource-group "sentinel-kql-dev-dev-rg" --no-wait
   ```

---

## 📊 **Advanced Monitoring (For Experienced Users)**

### 1. Check Alert Rules Status:
1. Go to Azure Portal → Microsoft Sentinel
2. Select your workspace
3. Go to **Analytics** → **Active rules**
4. Verify rules are enabled and running

### 2. View Triggered Incidents:
1. Go to **Incidents** in Sentinel
2. Look for new incidents created by your test events
3. Click on incidents to see details and investigate

### 3. Query Raw Data:
```kql
// Check for failed login events (modern syntax - VALIDATED)
union isfuzzy=true SecurityEvent, WindowsEvent
| where TimeGenerated > ago(1h)
| where EventID == 4625  // Failed logon
| where Computer contains "sentinel"
| project TimeGenerated, Account, IpAddress, WorkstationName, ProcessName, Computer
| order by TimeGenerated desc

// Check for PowerShell events (modern syntax - VALIDATED)
union isfuzzy=true SecurityEvent, WindowsEvent
| where TimeGenerated > ago(1h)
| where EventID == 4688  // Process creation
| where ProcessName contains "powershell"
| where Computer contains "sentinel"
| project TimeGenerated, Account, ProcessName, CommandLine, Computer
| order by TimeGenerated desc

// Check Key Vault access (VALIDATED)
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where ResourceType == "VAULTS"
| where OperationName in ("SecretGet", "KeyGet", "VaultGet")
| project TimeGenerated, CallerIPAddress, OperationName, ResultSignature
| order by TimeGenerated desc

// Verify VM is sending data (Heartbeat check - VALIDATED)
Heartbeat
| where TimeGenerated > ago(1h)
| where Computer contains "sentinel"
| project TimeGenerated, Computer, OSType, OSMajorVersion
| order by TimeGenerated desc

// Check for any available data from VMs (VALIDATED)
search *
| where TimeGenerated > ago(1h)
| where Computer contains "sentinel"
| summarize count() by Type
| order by count_ desc
```

---

## ⚠️ **Safety Notes**

1. **Test Environment Only**: Only run these on your test VM
2. **Clean Up**: Delete test files and accounts after testing
3. **Monitor Costs**: Watch Azure costs during testing
4. **Real Threats**: Don't use actual malicious IPs or domains

---

## 🎯 **Expected Timeline**

- **Immediate**: Security events logged to VM
- **5-10 minutes**: Events ingested into Log Analytics
- **15-30 minutes**: Alert rules evaluate and trigger
- **30+ minutes**: Incidents created in Sentinel

---

## 🔍 **Troubleshooting**

### VM Security Events Not Appearing:
If alerts don't trigger after enabling VMs:
1. **Wait 10-15 minutes** - Agent installation and DCR association takes time
2. **Check agent status** - Both MMA and AMA should be installed automatically
3. **Verify data collection** - Use this query to check for any Windows events:
   ```kql
   union isfuzzy=true SecurityEvent, WindowsEvent
   | where TimeGenerated > ago(1h)
   | where Computer contains "sentinel"
   | take 10
   ```
4. **Check DCR association** - Data Collection Rule should be linked to VM automatically

### General Troubleshooting:
1. **Verify Log Analytics workspace is receiving data**
2. **Confirm alert rules are enabled** - Go to Sentinel → Analytics → Active rules
3. **Check query syntax** - Test queries manually in Log Analytics
4. **Verify time windows** - Alert rules match your test timing
5. **Monitor agent heartbeats** - Use `Heartbeat | where Computer contains "sentinel"`

### ✅ **What's Now Automated:**
- ✅ Microsoft Monitoring Agent (MMA) installation
- ✅ Azure Monitor Agent (AMA) installation  
- ✅ Data Collection Rules for Security Events
- ✅ DCR association with VM
- ✅ Windows Event Log collection setup

### 🔧 **Manual Setup (If Needed)**
If you need to set up VM monitoring manually (not required with our Terraform automation):

> **📋 Reference**: These are the same steps that Terraform performs automatically in `terraform/compute.tf` using `azurerm_virtual_machine_extension` and `azurerm_monitor_data_collection_rule` resources.

#### **1. Install Monitoring Agents via Azure Portal:**
1. Go to **Azure Portal** → **Virtual Machines** → Select your VM
2. Navigate to **Settings** → **Extensions + applications**
3. **Add Extension** → Search for "Microsoft Monitoring Agent"
4. Configure with your **Log Analytics Workspace ID** and **Primary Key**
5. **Add Extension** → Search for "Azure Monitor Agent" 
6. Install and configure AMA extension

#### **2. Create Data Collection Rules (DCR):**
1. Go to **Azure Portal** → **Monitor** → **Data Collection Rules**
2. **Create** new DCR with these settings:
   - **Name**: `windows-security-events-dcr`
   - **Resource Group**: Same as your Sentinel workspace
   - **Region**: Same as your workspace
3. **Data Sources** tab:
   - **Add data source** → **Windows Event Logs**
   - **Select event logs**: `Security`, `System`, `Application`
   - **Log levels**: `Critical`, `Error`, `Warning`, `Information`
4. **Destinations** tab:
   - **Add destination** → **Azure Monitor Logs**
   - **Select your Log Analytics workspace**
5. **Data Collection Endpoints** → **Create** or select existing
6. **Resources** tab → **Add resources** → Select your VM

#### **3. Verify Agent Installation:**
```kql
// Check agent heartbeats (VALIDATED)
Heartbeat
| where Computer contains "sentinel"
| summarize LastHeartbeat = max(TimeGenerated) by Computer, OSType
```

#### **4. Test Data Collection:**
```kql
// Verify Windows Security Events are flowing (VALIDATED)
union isfuzzy=true SecurityEvent, WindowsEvent
| where TimeGenerated > ago(1h)
| where Computer contains "sentinel"
| summarize EventCount = count() by EventID
| order by EventCount desc
```

> **💡 Note**: With our Terraform automation, all these manual steps are done automatically when you set `create_test_vms = true`. The manual instructions above are provided for reference or troubleshooting purposes.

---

## ✅ **Updated & Validated - August 4, 2025**

**All commands and queries in this document have been updated and validated:**

- ✅ **Key Vault Names**: Updated to use actual deployed Key Vault `kv-sentinelkql-qg0m374b`
- ✅ **Resource Group**: Correct reference to `sentinel-kql-dev-dev-rg`
- ✅ **KQL Queries**: All updated with `union isfuzzy=true` syntax for modern table compatibility
- ✅ **Computer Filtering**: Updated from "sentinelkqltest" to "sentinel" for current VM names
- ✅ **External Data Sources**: Validated threat intelligence integration with proper variable naming
- ✅ **CLI Commands**: All Azure CLI commands tested and verified working
- ✅ **PowerShell Scripts**: Updated with current Key Vault name and error handling

**Ready for comprehensive security event testing!**

---

## 💰 **Step 5: Cost Management & Cleanup**

### **💡 Cost-Saving Tips for First-Time Users**

#### **Daily Cost Control**
```bash
# Stop VMs when not testing (saves ~50% of costs)
az vm deallocate --name "sentinel-kql-test-dev-testvm" --resource-group "sentinel-kql-dev-dev-rg" --no-wait
az vm deallocate --name "sentinel-kql-test-dev-testvm2" --resource-group "sentinel-kql-dev-dev-rg" --no-wait

# Check current Log Analytics usage
az monitor log-analytics workspace get-usage --workspace-name "$(terraform output -raw log_analytics_workspace_name)" --resource-group "sentinel-kql-dev-dev-rg"
```

#### **Weekend/Extended Break Cleanup**
```bash
# Temporary shutdown (keeps infrastructure, stops costs)
az vm deallocate --name "sentinel-kql-test-dev-testvm" --resource-group "sentinel-kql-dev-dev-rg"
az vm deallocate --name "sentinel-kql-test-dev-testvm2" --resource-group "sentinel-kql-dev-dev-rg"
```

#### **Complete Environment Cleanup**
```bash
# ⚠️ WARNING: This deletes everything! Only run when completely done testing
cd terraform
terraform destroy -auto-approve

# Verify cleanup
az group show --name "sentinel-kql-dev-dev-rg" --query "properties.provisioningState" -o tsv
```

### **💸 Estimated Costs (Per Day)**
- **Minimal setup** (no VMs): $5-15/day
- **With VMs** (2 Windows VMs): $15-30/day  
- **VMs deallocated**: ~50% cost reduction
- **Log Analytics** (10GB limit): ~$2-5/day max

---

## 🎓 **Learning Path for New Users**

### **Week 1: Foundation**
1. ✅ Deploy infrastructure without VMs
2. ✅ Test Key Vault anomaly detection
3. ✅ Learn Azure Portal navigation
4. ✅ Understand basic KQL queries

### **Week 2: Advanced Testing**
1. ✅ Enable VMs and test Windows events
2. ✅ Create custom alert rules
3. ✅ Practice incident investigation
4. ✅ Learn PowerShell security testing

### **Week 3: Real-World Scenarios**
1. ✅ Simulate advanced attack patterns
2. ✅ Create custom workbooks
3. ✅ Practice threat hunting
4. ✅ Export and share findings

---

## 📚 **Additional Resources for Beginners**

### **Microsoft Documentation**
- [Azure Sentinel Overview](https://docs.microsoft.com/en-us/azure/sentinel/overview)
- [KQL Quick Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kql-quick-reference)
- [Sentinel Analytics Rules](https://docs.microsoft.com/en-us/azure/sentinel/detect-threats-built-in)

### **Hands-On Labs**
- [Sentinel Ninja Training](https://techcommunity.microsoft.com/t5/microsoft-sentinel-blog/become-a-microsoft-sentinel-ninja-the-complete-level-400/ba-p/1246310)
- [KQL Learning Path](https://docs.microsoft.com/en-us/learn/paths/sc-200-utilize-kql-for-azure-sentinel/)

---

Happy testing! 🚀
