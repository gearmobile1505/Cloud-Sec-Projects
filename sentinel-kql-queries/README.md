# Microsoft Sentinel KQL Query Library

Production-ready KQL queries for Microsoft Sentinel security monitoring and threat hunting.

## � Query Categories

- **Azure AD Security** - Identity and access monitoring
- **Network Security** - DNS tunneling, lateral movement detection  
- **Endpoint Detection** - Suspicious process monitoring
- **Cloud Security** - Multi-cloud threat hunting

## 🚀 Quick Start

1. **Browse Queries**
   - Navigate to `queries/` directory
   - Each query includes MITRE ATT&CK mappings

2. **Deploy to Sentinel**
   ```bash
   # Copy query to Sentinel Log Analytics
   # Adjust time ranges and parameters
   # Create analytics rules
   ```

3. **Customize**
   - Modify thresholds in queries
   - Add custom data sources
   - Create scheduled rules

## 🔧 Usage

```kql
// Example: Privilege escalation detection
SecurityEvent
| where TimeGenerated > ago(24h)
| where EventID == 4728
| project TimeGenerated, Account, TargetAccount, Computer
```

## 📋 Requirements

- Microsoft Sentinel workspace
- Appropriate data connectors configured
- Log Analytics contributor permissions
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

## 🤝 Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-query`)
3. Follow query metadata standards
4. Include test cases and documentation
5. Submit pull request

### Query Standards
- Include comprehensive metadata header
- Add MITRE ATT&CK mappings
- Provide clear descriptions
- Test for false positives
- Document data source requirements

## 📝 Query Template

````kql
// Query: [Query Name]
// Description: [Brief description of detection logic]
// Author: [Author name]
// Created: [YYYY-MM-DD]
// Last Modified: [YYYY-MM-DD]
// Version: [X.X]
// Severity: [Low|Medium|High|Critical]
// MITRE ATT&CK: [Technique ID] - [Technique Name]
// MITRE Tactics: [Tactic Name]
// Data Sources: [Required log sources]
// False Positive Rate: [Low|Medium|High]
// Tags: [comma-separated tags]

// Your KQL query here