# Cloud Security Projects 🛡️

A comprehensive collection of security tools, automation frameworks, and threat detection queries for AWS and Azure cloud environments. This repository provides production-ready security solutions with automated testing and deployment capabilities.

## 🎯 **Featured Project: Microsoft Sentinel KQL Query Library** ⭐

**✅ Complete & Production-Ready** - Comprehensive KQL query library with automated testing environment
- **200+ Security Queries** with MITRE ATT&CK mappings
- **Terraform Infrastructure** for complete Sentinel testing environment  
- **Cost-Optimized Deployment** with auto-shutdown and quota controls
- **Automated Agent Setup** - MMA and AMA monitoring agents pre-configured
- **First-Time User Guide** - Step-by-step deployment and testing documentation

📈 **Recent Achievements:**
- ✅ Complete infrastructure automation with Terraform
- ✅ Comprehensive first-time user documentation 
- ✅ Full KQL syntax validation across all queries
- ✅ Cost optimization ($70-150/month → $0 when not in use)
- ✅ Production-ready deployment pipeline

➡️ **[Explore Sentinel KQL Queries →](./sentinel-kql-queries)**

---

## 🗂️ Project Portfolio

### 🔐 **Microsoft Azure Security**
- **[Sentinel KQL Queries](./sentinel-kql-queries)** - Production KQL library with automated testing environment
  - **Status**: ✅ Complete & Active
  - **Features**: 200+ queries, Terraform automation, cost optimization
  - **Use Case**: Threat hunting, security monitoring, incident response

### ⚡ **AWS Security Automation**
- **[AWS Resource Manager](./aws-resource-manager)** - Comprehensive AWS security remediation framework
  - **Status**: 🔄 Active Development  
  - **Features**: Multi-service remediation, compliance checking
  - **Use Case**: Automated security remediation, compliance monitoring

- **[Auto-Remediate Lambda](./auto-remediate-lambda)** - Serverless security remediation functions
  - **Status**: 📋 Planning Phase
  - **Features**: Event-driven remediation, cost-effective deployment
  - **Use Case**: Real-time security response automation

### 🛡️ **Compliance & Monitoring**
- **[CIS Benchmark Checker](./cis-benchmark-checker)** - Automated compliance validation
  - **Status**: 📋 Planning Phase
  - **Features**: CIS benchmark validation, automated reporting
  - **Use Case**: Compliance auditing, security baselines

- **[Cloud Security Remediation](./cloud-security-remediation)** - Multi-cloud remediation toolkit
  - **Status**: 🔄 Active Development
  - **Features**: AWS/Azure/GCP support, automated fixes
  - **Use Case**: Cross-cloud security standardization

### 📊 **Security Analytics & Monitoring**
- **[GuardDuty Summary](./guardduty-summary)** - AWS GuardDuty analytics and reporting
- **[CloudTrail Activity Finder](./cloudtrail-activity-finder)** - Advanced CloudTrail log analysis
- **[Credential Usage Tracker](./credential-usage-tracker)** - IAM credential monitoring
- **[IAM Policy Inspector](./iam-policy-inspector)** - Policy analysis and optimization
- **[S3 Public Access Scanner](./s3-public-access-scanner)** - S3 security assessment
- **[Security Group Audit](./security-group-audit)** - Network security validation
- **[VPC Flow Logs Enabler](./vpc-flow-logs-enabler)** - Network monitoring automation

## 🚀 Quick Start

### **Deploy Sentinel KQL Testing Environment**
```bash
git clone https://github.com/gearmobile1505/Cloud-Sec-Projects.git
cd sentinel-kql-queries/terraform
terraform init && terraform apply
```

### **AWS Security Tools Setup**
```bash
# Configure AWS CLI
aws configure

# Install Python dependencies
pip install -r requirements.txt

# Run security assessments
python aws_resource_manager.py --scan
```

## 🛠️ Requirements

### **Core Dependencies**
- **Azure CLI** - For Sentinel and Azure security tools
- **AWS CLI** - Configured with active credentials and appropriate permissions
- **Terraform** ≥ 1.0 - Infrastructure automation and deployment
- **Python** 3.9+ with Boto3 - AWS SDK and automation scripts
- **PowerShell** 7+ - Windows security event generation and testing

### **Permission Requirements**
- **Azure**: Contributor access to subscription for Sentinel deployment
- **AWS**: Security-focused IAM permissions based on tool functionality
- **Terraform**: Service principal/role permissions for infrastructure deployment

## 💰 Cost Management

**Sentinel KQL Environment:**
- **Development**: $0/month (auto-shutdown when not in use)
- **Active Testing**: $70-150/month (with cost controls enabled)
- **Production**: Customizable based on data ingestion requirements

**AWS Tools:**
- Most tools use read-only operations with minimal costs
- Lambda-based remediation: Pay-per-execution model

## 📚 Documentation

- **[Sentinel Deployment Guide](./sentinel-kql-queries/DEPLOYMENT-GUIDE.md)** - Complete infrastructure setup
- **[Testing Instructions](./sentinel-kql-queries/generate-test-events.md)** - First-time user guide
- **[KQL Query Library](./sentinel-kql-queries/queries/)** - Production security queries
- **[AWS Setup Guides](./aws-resource-manager/docs/)** - AWS tool configuration

## 🤝 Contributing

We welcome contributions! Please see individual project directories for specific contribution guidelines.

### **Development Standards**
- Follow security best practices and least privilege principles
- Include comprehensive testing and documentation
- Optimize for cost-effectiveness and performance
- Provide clear setup and usage instructions

## ⚠️ Security Notice

These tools are designed for legitimate security operations and educational purposes. Always:
- Obtain proper authorization before deployment
- Follow your organization's security policies
- Test in non-production environments first
- Monitor costs and resource usage
- Review and audit all configurations

## 📊 Project Status Dashboard

| Project | Status | Last Updated | Documentation |
|---------|--------|--------------|---------------|
| Sentinel KQL Queries | ✅ Production Ready | Aug 2025 | Complete |
| AWS Resource Manager | 🔄 Active Development | Aug 2025 | In Progress |
| Cloud Security Remediation | 🔄 Active Development | Aug 2025 | In Progress |
| Auto-Remediate Lambda | 📋 Planning | - | Planned |
| CIS Benchmark Checker | 📋 Planning | - | Planned |

---

**🎯 Ready to enhance your cloud security posture? Start with our [Sentinel KQL Queries](./sentinel-kql-queries) for immediate threat detection capabilities!**
