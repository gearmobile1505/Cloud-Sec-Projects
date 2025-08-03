# Microsoft Sentinel KQL Query Library 🛡️

A comprehensive collection of KQL (Kusto Query Language) queries for Microsoft Sentinel security monitoring, threat hunting, and incident response.

## 🎉 **NEW: Complete Testing Environment!**

**✅ Fully Automated Setup** - Deploy a complete Azure Sentinel testing environment with one command!
**✅ VM Monitoring Ready** - Automatic agent installation and data collection configuration
**✅ Cost Optimized** - Auto-shutdown schedules and quota limits included

```bash
cd terraform
terraform init
terraform apply
# Optional: Enable VM testing
echo 'create_test_vms = true' > terraform.tfvars
terraform apply
```

[📖 **Full Deployment Guide**](DEPLOYMENT-GUIDE.md) | [📋 **Testing Instructions**](generate-test-events.md) | [🔄 **Changelog**](CHANGELOG.md)

---

## 📋 Overview

This repository contains production-ready KQL queries designed for security operations teams using Microsoft Sentinel. Each query includes detailed metadata, MITRE ATT&CK mappings, and deployment guidance.

**🆕 What's New in v2.0:**
- ✅ **Automated VM Agent Setup** - MMA and AMA agents installed automatically
- ✅ **Data Collection Rules** - Windows Security Events configured out-of-the-box  
- ✅ **Enhanced Queries** - Compatible with both SecurityEvent and WindowsEvent tables
- ✅ **Complete Testing Environment** - Deploy, test, and validate in minutes

## 🗂️ Repository Structure

```
sentinel-kql-queries/
├── terraform/                 # 🚀 Complete infrastructure deployment
│   ├── main.tf               # Core Sentinel infrastructure
│   ├── compute.tf            # VM with automated monitoring setup
│   ├── sentinel.tf           # Alert rules and watchlists
│   └── variables.tf          # Configurable parameters
├── queries/                  # 📊 Production KQL queries
│   ├── azure-ad/             # Azure Active Directory queries
│   ├── network/              # Network security queries  
│   ├── endpoint/             # Endpoint detection queries
│   └── cloud/                # Cloud security queries
├── playbooks/                # 🤖 Logic Apps automation
├── workbooks/                # 📈 Custom workbooks
├── docs/                     # 📚 Documentation
├── DEPLOYMENT-GUIDE.md       # 🚀 Complete setup instructions
├── generate-test-events.md   # 🧪 Testing guide
└── CHANGELOG.md              # 📝 Version history
```

## 🚀 Quick Start

### **🎯 Option 1: Deploy Complete Testing Environment**
```bash
git clone https://github.com/gearmobile1505/Cloud-Sec-Projects.git
cd sentinel-kql-queries/terraform
terraform init
terraform apply                    # Deploy core Sentinel infrastructure

# Optional: Enable VM for Windows security event testing
echo 'create_test_vms = true' > terraform.tfvars  
terraform apply                    # Adds VM with automated monitoring
```

**🎉 What you get:**
- ✅ Complete Azure Sentinel workspace
- ✅ Pre-configured alert rules and watchlists  
- ✅ Key Vault for access anomaly testing
- ✅ VM with automated agent setup (optional)
- ✅ Data collection rules for Security Events
- ✅ Cost controls (auto-shutdown, quotas)

### **📊 Option 2: Use Individual Queries**
1. **Browse the queries** in the `/queries` directory
2. **Copy to your Sentinel workspace** via Azure Portal
3. **Customize parameters** (time ranges, thresholds)
4. **Create analytics rules** or run as ad-hoc queries

## 📊 Featured Queries

### Azure AD Security
- **Privilege Escalation Detection** - Monitors suspicious role assignments to privileged Azure AD roles
- **Suspicious Sign-ins** - Detects anomalous authentication patterns
- **Account Manipulation** - Identifies unauthorized account modifications

### Network Security
- **DNS Tunneling Detection** - Identifies potential data exfiltration via DNS
- **Lateral Movement** - Detects suspicious network traversal patterns
- **Command & Control** - Monitors for C2 communication indicators

## 🎯 Query Metadata

Each query includes standardized metadata:
- **MITRE ATT&CK** technique and tactic mappings
- **Severity** levels (Low, Medium, High, Critical)
- **Data sources** required
- **False positive** rate estimates
- **Detection** logic explanations

## 📋 Prerequisites

- Microsoft Sentinel workspace
- Appropriate data connectors configured
- Required log sources ingesting data
- Proper RBAC permissions for query execution

## 🔧 Configuration

### Time Ranges
Most queries use configurable time ranges:
```kql
let lookbackTime = 24h;  // Adjust as needed
```

### Thresholds
Customize detection thresholds based on your environment:
```kql
let suspiciousThreshold = 5;  // Modify for your baseline
```

## 📈 Analytics Rules

Convert queries to Sentinel analytics rules:
1. Navigate to **Analytics** → **Rule templates**
2. Create **Scheduled query rule**
3. Paste KQL query content
4. Configure frequency and alert thresholds
5. Set up incident creation and response actions

## 🔍 Threat Hunting

Use queries for proactive threat hunting:
- Run ad-hoc investigations in **Logs**
- Create custom hunting queries
- Build threat hunting dashboards
- Export results for further analysis

## 📊 Custom Workbooks

Create visual dashboards:
1. Navigate to **Workbooks**
2. Add new workbook
3. Import visualization queries
4. Customize charts and tables

## 📚 KQL Basics for Microsoft Sentinel

### Essential KQL Syntax

#### Time Filtering
```kql
// Last 24 hours
| where TimeGenerated > ago(24h)

// Specific time range
| where TimeGenerated between (datetime(2025-01-01) .. datetime(2025-01-02))
```

#### Filtering and Searching
```kql
// Exact match
| where Account == "user@domain.com"

// Contains
| where Account contains "admin"

// Multiple conditions
| where Account contains "admin" and ResultType != "0"
```

#### Aggregations
```kql
// Count by field
| summarize count() by Account

// Multiple aggregations
| summarize 
    Total = count(),
    UniqueUsers = dcount(Account),
    FirstSeen = min(TimeGenerated)
    by SourceIP
```

#### Common Functions
- `ago()` - Time relative to now
- `bin()` - Time bucketing  
- `count()` - Count rows
- `dcount()` - Distinct count
- `make_set()` - Create array of unique values
- `extend` - Add calculated columns
- `project` - Select specific columns

#### Performance Tips
1. Always include time filters first
2. Use `where` clauses early in the pipeline
3. Limit result sets with `limit` or `take`
4. Use `sample` for testing on large datasets

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### How to Contribute
1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/new-detection`
3. **Follow query standards** (see below)
4. **Test thoroughly** in your environment
5. **Submit pull request** with detailed description

### Query Standards
- Include comprehensive metadata header
- Add MITRE ATT&CK technique mappings
- Provide clear descriptions and comments
- Test for false positives and document them
- Optimize for performance with proper time filters
- Document required data source requirements

### Query File Naming
- Use lowercase with hyphens: `failed-login-attempts.kql`
- Be descriptive and specific
- Include version if applicable: `malware-detection-v2.kql`

### Quality Requirements
- Include proper time range filters (performance critical)
- Add meaningful comments explaining detection logic
- Optimize queries for performance and cost
- Document known false positives and edge cases
- Provide example output or test cases
- Test in production-like environment before submission

## 📝 Query Template

````kql
// Query: [Descriptive Detection Name]
// Description: [What this query detects and why it's important]
// Author: [Author name]
// Created: [YYYY-MM-DD]
// Last Modified: [YYYY-MM-DD]
// Version: [X.X]
// Severity: [Low|Medium|High|Critical]
// MITRE ATT&CK: [Technique ID] - [Technique Name]
// MITRE Tactics: [Tactic Name]
// Data Sources: [Required log sources/tables]
// False Positive Rate: [Low|Medium|High]
// Tags: [detection, hunting, compliance, etc.]

// Your KQL query here