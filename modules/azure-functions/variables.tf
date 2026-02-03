# Azure Functions Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use existing"
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 chars, lowercase alphanumeric)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the App Service Plan (e.g., Y1 for Consumption, EP1 for Elastic Premium, P1v2 for Premium)"
  type        = string
  default     = "Y1"
}

variable "os_type" {
  description = "Operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"
  
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be either Linux or Windows."
  }
}

variable "runtime" {
  description = "Function runtime (python, node, dotnet, java, powershell)"
  type        = string
  default     = "python"
}

variable "runtime_version" {
  description = "Runtime version (e.g., 3.9, 3.10, 3.11 for Python)"
  type        = string
  default     = "3.11"
}

variable "app_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
}

variable "app_insights_type" {
  description = "Application Insights application type"
  type        = string
  default     = "web"
}

variable "app_insights_retention_days" {
  description = "Application Insights data retention in days"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.app_insights_retention_days)
    error_message = "Retention must be one of: 30, 60, 90, 120, 180, 270, 365, 550, or 730 days."
  }
}

variable "key_vault_id" {
  description = "ID of the Key Vault to integrate with (optional)"
  type        = string
  default     = null
}

variable "app_settings" {
  description = "Additional app settings for the Function App"
  type        = map(string)
  default     = {}
}

variable "cors_allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
