# Production Workload Account Request
# This is a Terraform variable file example
# Copy values to terraform.tfvars or use as reference for JSON account requests

variable "production_account" {
  description = "Production account configuration"
  type = object({
    account_name                 = string
    account_email               = string
    organizational_unit         = string
    account_customizations_name = string
    custom_fields              = map(string)
    enable_backup              = bool
    enable_monitoring          = bool
    enable_vpc_flow_logs       = bool
    require_mfa               = bool
    monthly_budget            = number
    alert_thresholds          = list(number)
    auto_shutdown             = bool
  })
  
  default = {
    account_name                 = "MyApp-Production"
    account_email               = "myapp-production@yourcompany.com"
    organizational_unit         = "Workloads/Production"
    account_customizations_name = "production-baseline"
    
    custom_fields = {
      Environment = "Production"
      Owner      = "Platform Team"
      CostCenter = "ENG-001"
      Project    = "MyApp"
      Compliance = "SOC2"
      Backup     = "Required"
      MultiAZ    = "Required"
      Encryption = "Required"
    }
    
    # Additional Configuration
    enable_backup        = true
    enable_monitoring    = true
    enable_vpc_flow_logs = true
    require_mfa         = true
    
    # Cost Management
    monthly_budget    = 5000
    alert_thresholds  = [50, 80, 95]
    auto_shutdown     = false
  }
}
