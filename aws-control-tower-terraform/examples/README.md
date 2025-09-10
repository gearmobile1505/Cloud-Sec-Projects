# Account Management Examples

This directory contains practical examples for common account management tasks using the AWS Control Tower and AFT setup.

## 📁 Directory Structure

```
examples/
├── account-requests/          # AFT account creation requests
├── scp-customizations/        # Custom Service Control Policies
├── compliance-checks/         # Automated compliance validation
├── cost-management/           # Cost optimization and monitoring
├── security-baselines/        # Account security configurations
└── workload-patterns/         # Common workload deployment patterns
```

## 🏗️ Common Use Cases

### 1. New Account Creation
- Development environment setup
- Production workload accounts  
- Sandbox accounts for experimentation
- Dedicated security accounts

### 2. Policy Management
- Custom SCPs for specific requirements
- Regional restrictions for data sovereignty
- Service limitations for cost control
- Security policy enforcement

### 3. Compliance Automation
- CIS Benchmark implementations
- SOC 2 compliance checks
- PCI DSS configurations
- GDPR data handling policies

### 4. Cost Optimization  
- Budget alerts and controls
- Resource tagging enforcement
- Instance type restrictions
- Auto-shutdown policies

## 🚀 Getting Started

Each subdirectory contains:
- **README.md**: Detailed explanations and use cases
- **example-configs/**: Sample Terraform configurations
- **scripts/**: Automation scripts and utilities
- **policies/**: JSON policy documents

Navigate to specific directories for implementation details and copy-paste ready configurations.
