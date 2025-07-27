# Microsoft Sentinel KQL Query Library

A comprehensive collection of KQL (Kusto Query Language) queries for Microsoft Sentinel security monitoring, threat hunting, and incident response.

## 📋 Overview

This repository contains production-ready KQL queries designed for security operations teams using Microsoft Sentinel. Each query includes detailed metadata, MITRE ATT&CK mappings, and deployment guidance.

## 🗂️ Repository Structure

```
sentinel-kql-queries/
├── queries/
│   ├── azure-ad/              # Azure Active Directory queries
│   │   └── privilege-escalation.kql
│   ├── network/               # Network security queries
│   ├── endpoint/              # Endpoint detection queries
│   └── cloud/                 # Cloud security queries
├── playbooks/                 # Logic Apps automation
├── workbooks/                 # Custom workbooks
└── docs/                      # Documentation
```

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/gearmobile1505/Cloud-Sec_Projects.git
   cd sentinel-kql-queries
   ```

2. **Browse available queries**
   - Navigate to the `queries/` directory
   - Each query includes comprehensive metadata and documentation

3. **Deploy to Sentinel**
   - Copy queries to your Sentinel workspace
   - Adjust time ranges and parameters as needed
   - Create custom analytics rules or scheduled queries

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