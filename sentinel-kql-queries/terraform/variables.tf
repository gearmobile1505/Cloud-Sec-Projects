# Variables for Azure Sentinel KQL Testing Infrastructure

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (e.g., test, dev, prod)"
  type        = string
  default     = "test"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sentinel-kql"
}

# Log Analytics Workspace Configuration
variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily data ingestion quota in GB (-1 for unlimited)"
  type        = number
  default     = 10
}

# Sentinel Configuration
variable "enable_sentinel" {
  description = "Enable Microsoft Sentinel"
  type        = bool
  default     = true
}

variable "enable_data_connectors" {
  description = "Enable various data connectors for testing"
  type        = bool
  default     = true
}

# Test Environment Configuration
variable "create_test_vms" {
  description = "Create test VMs to generate security events"
  type        = bool
  default     = true
}

variable "vm_admin_username" {
  description = "Admin username for test VMs"
  type        = string
  default     = "testadmin"
}

variable "vm_admin_password" {
  description = "Admin password for test VMs (use strong password)"
  type        = string
  sensitive   = true
  default     = "TestPassword123!"
}

# Security Configuration
variable "enable_defender" {
  description = "Enable Microsoft Defender for Cloud"
  type        = bool
  default     = true
}

variable "enable_key_vault" {
  description = "Create Key Vault for secrets testing"
  type        = bool
  default     = true
}

variable "enable_storage_threats" {
  description = "Enable storage account threat detection"
  type        = bool
  default     = true
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for subnets"
  type        = map(string)
  default = {
    "default"  = "10.0.1.0/24"
    "security" = "10.0.2.0/24"
  }
}

# Network Configuration
variable "enable_flow_logs" {
  description = "Enable NSG flow logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Flow logs retention period in days"
  type        = number
  default     = 7
}

# Cost Control
variable "auto_shutdown_time" {
  description = "Auto-shutdown time for VMs (HHmm format, e.g., 1900 for 7 PM)"
  type        = string
  default     = "1900"
}

variable "enable_cost_alerts" {
  description = "Enable cost management alerts"
  type        = bool
  default     = true
}
