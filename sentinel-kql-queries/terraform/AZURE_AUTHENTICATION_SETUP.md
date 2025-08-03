# Azure Authentication Setup for GitHub Actions

This guide walks you through obtaining the necessary Azure credentials to authenticate your GitHub Actions workflows.

## 🎯 Overview

You need to create an Azure Service Principal that GitHub Actions can use to deploy resources to your Azure subscription. This involves:

1. **Azure CLI Setup** - Install and authenticate locally
2. **Service Principal Creation** - Create automated authentication
3. **Permission Assignment** - Grant necessary roles
4. **GitHub Secrets Configuration** - Store credentials securely
5. **Testing** - Verify authentication works

---

## 📋 Prerequisites

- Azure subscription with **Owner** or **Contributor + User Access Administrator** roles
- Local computer with internet access
- GitHub repository access

---

## 🚀 Step-by-Step Instructions

### Step 1: Install Azure CLI

Choose your operating system:

#### **macOS:**
```bash
# Using Homebrew (recommended)
brew install azure-cli

# Or using installer
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### **Windows:**
```powershell
# Using winget
winget install -e --id Microsoft.AzureCLI

# Or download installer from https://aka.ms/installazurecliwindows
```

#### **Linux (Ubuntu/Debian):**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### **Verify Installation:**
```bash
az --version
```

### Step 2: Login to Azure

1. **Authenticate with your Azure account:**
```bash
az login
```

2. **This will open a browser window** - sign in with your Azure credentials

3. **List your subscriptions:**
```bash
az account list --output table
```

4. **Set the correct subscription** (if you have multiple):
```bash
az account set --subscription "Your-Subscription-Name-Or-ID"
```

5. **Verify current subscription:**
```bash
az account show
```

### Step 3: Get Your Subscription Information

**Copy these values - you'll need them later:**

```bash
# Get subscription ID
az account show --query id --output tsv

# Get tenant ID  
az account show --query tenantId --output tsv

# Get subscription name
az account show --query name --output tsv
```

**Example output:**
```
Subscription ID: 12345678-1234-1234-1234-123456789012
Tenant ID: 87654321-4321-4321-4321-210987654321
Subscription Name: My Azure Subscription
```

### Step 4: Create Service Principal

Now create a service principal for GitHub Actions:

#### **Option A: Automatic Script (Recommended)**

Run our setup script:
```bash
cd sentinel-kql-queries/terraform
chmod +x setup-github-actions.sh
./setup-github-actions.sh
```

⚠️ **Note:** Some Sentinel data connectors require additional permissions beyond Contributor role (e.g., Global Admin for Azure AD connector). These are disabled by default but can be enabled manually in the Azure portal after deployment.

This script will automatically handle steps 4-6. **Skip to Step 7 if using this option.**

#### **Option B: Manual Creation**

1. **Create the service principal:**
```bash
# Replace with your subscription ID
SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789012"

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-actions-sentinel-kql" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --json-auth
```

2. **Save the output** - it will look like this:
```json
{
  "clientId": "abcd1234-5678-90ef-ghij-klmnopqrstuv",
  "clientSecret": "your-client-secret-here",
  "subscriptionId": "12345678-1234-1234-1234-123456789012",
  "tenantId": "87654321-4321-4321-4321-210987654321"
}
```

⚠️ **IMPORTANT:** The `clientSecret` is only shown once. Copy it immediately!

### Step 5: Install GitHub CLI (if not already installed)

#### **macOS:**
```bash
brew install gh
```

#### **Windows:**
```powershell
winget install --id GitHub.cli
```

#### **Linux:**
```bash
# Ubuntu/Debian
sudo apt install gh

# Or using snap
sudo snap install gh
```

### Step 6: Setup GitHub Repository Secrets

1. **Login to GitHub CLI:**
```bash
gh auth login
```

2. **Navigate to your repository directory:**
```bash
cd /path/to/your/Cloud-Sec-Projects
```

3. **Set the GitHub secrets** using the values from Step 4:

```bash
# Set the complete Azure credentials JSON
gh secret set AZURE_CREDENTIALS --body '{
  "clientId": "abcd1234-5678-90ef-ghij-klmnopqrstuv",
  "clientSecret": "your-client-secret-here", 
  "subscriptionId": "12345678-1234-1234-1234-123456789012",
  "tenantId": "87654321-4321-4321-4321-210987654321"
}'

# Set individual ARM variables (for Terraform)
echo "12345678-1234-1234-1234-123456789012" | gh secret set ARM_SUBSCRIPTION_ID
echo "abcd1234-5678-90ef-ghij-klmnopqrstuv" | gh secret set ARM_CLIENT_ID  
echo "your-client-secret-here" | gh secret set ARM_CLIENT_SECRET
echo "87654321-4321-4321-4321-210987654321" | gh secret set ARM_TENANT_ID
```

4. **Verify secrets were set:**
```bash
gh secret list
```

### Step 7: Test Authentication

1. **Test Azure CLI authentication:**
```bash
# This should show your resources
az resource list --output table
```

2. **Test service principal authentication:**
```bash
# Using the service principal credentials
az login --service-principal \
  --username "abcd1234-5678-90ef-ghij-klmnopqrstuv" \
  --password "your-client-secret-here" \
  --tenant "87654321-4321-4321-4321-210987654321"

# Test access
az resource list --output table
```

3. **Test GitHub Actions workflow:**
   - Go to your GitHub repository
   - Click **Actions** tab
   - Select **Deploy Azure Sentinel KQL Testing Infrastructure**
   - Click **Run workflow**
   - Choose `plan` action and `dev` environment
   - Click **Run workflow**

---

## 🔒 Security Best Practices

### Service Principal Permissions

Your service principal has these permissions:
- **Contributor** role on the subscription (can create/modify/delete resources)
- **Cannot** modify access permissions or billing
- **Cannot** access Key Vault secrets (unless explicitly granted)

### Credential Management

✅ **DO:**
- Store credentials only in GitHub Secrets
- Use unique service principal per repository
- Rotate credentials regularly (every 90 days)
- Monitor service principal usage in Azure AD

❌ **DON'T:**
- Store credentials in code or configuration files
- Share service principal credentials
- Use personal accounts for automation
- Grant excessive permissions

### Monitoring

Monitor your service principal:
```bash
# List service principals
az ad sp list --display-name "github-actions-sentinel-kql"

# Check role assignments
az role assignment list --assignee "abcd1234-5678-90ef-ghij-klmnopqrstuv"
```

---

## 🛠️ Troubleshooting

### Common Issues

#### 1. "Insufficient privileges" Error
```
Error: The client '...' with object id '...' does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write'
```

**Solution:** You need **User Access Administrator** role:
```bash
# Have an admin run this
az role assignment create \
  --role "User Access Administrator" \
  --assignee "your-email@domain.com" \
  --scope "/subscriptions/your-subscription-id"
```

#### 2. "Application not found" Error
```
Error: The request for a token from endpoint https://login.microsoftonline.com/... failed
```

**Solution:** Verify tenant ID and client ID are correct:
```bash
az ad sp show --id "your-client-id"
```

#### 3. GitHub Secrets Not Working
```
Error: Error building ARM Config: obtain subscription
```

**Solutions:**
- Verify secret names match exactly: `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, etc.
- Check for trailing spaces in secret values
- Regenerate client secret if needed:
```bash
az ad app credential reset --id "your-client-id"
```

#### 4. Permission Denied on Resources
```
Error: authorization failed: ... does not have authorization to perform action
```

**Solution:** Check service principal has Contributor role:
```bash
az role assignment list --assignee "your-client-id" --all
```

### Getting Help

1. **Check Azure Activity Log:**
   - Azure Portal → Monitor → Activity Log
   - Filter by service principal name

2. **GitHub Actions Logs:**
   - Repository → Actions → Select failed workflow
   - Expand failed steps for detailed errors

3. **Verify Credentials:**
```bash
# Test service principal login
az login --service-principal \
  --username "your-client-id" \
  --password "your-client-secret" \
  --tenant "your-tenant-id"
```

---

## 📝 Quick Reference

### Required Information Summary

| Field | Where to Find | Example |
|-------|---------------|---------|
| **Subscription ID** | `az account show --query id -o tsv` | `12345678-1234-1234-1234-123456789012` |
| **Tenant ID** | `az account show --query tenantId -o tsv` | `87654321-4321-4321-4321-210987654321` |
| **Client ID** | Output from `az ad sp create-for-rbac` | `abcd1234-5678-90ef-ghij-klmnopqrstuv` |
| **Client Secret** | Output from `az ad sp create-for-rbac` | `your-client-secret-here` |

### GitHub Secrets Required

```
AZURE_CREDENTIALS     = Complete JSON from service principal creation
ARM_SUBSCRIPTION_ID   = Your subscription ID
ARM_CLIENT_ID         = Service principal client ID  
ARM_CLIENT_SECRET     = Service principal client secret
ARM_TENANT_ID         = Your tenant ID
```

### Commands Cheat Sheet

```bash
# Login and set subscription
az login
az account set --subscription "your-subscription"

# Create service principal
az ad sp create-for-rbac --name "github-actions-sentinel-kql" --role "Contributor" --scopes "/subscriptions/your-sub-id" --json-auth

# Set GitHub secrets
gh secret set AZURE_CREDENTIALS --body "JSON-from-above"

# Test authentication
az login --service-principal --username CLIENT_ID --password CLIENT_SECRET --tenant TENANT_ID
```

---

## ✅ Verification Checklist

Before proceeding to deploy:

- [ ] Azure CLI installed and working
- [ ] Logged into correct Azure subscription
- [ ] Service principal created successfully
- [ ] GitHub CLI installed and authenticated
- [ ] All 5 GitHub secrets configured
- [ ] Service principal authentication tested
- [ ] GitHub Actions workflow triggered successfully

Once completed, you can proceed with the GitHub Actions deployment workflow!
