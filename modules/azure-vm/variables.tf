# Variables for Azure VM Module

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use existing"
  type        = bool
  default     = true
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westus2"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size (e.g., Standard_D4s_v3)"
  type        = string
  default     = "Standard_D4s_v3"
  
  validation {
    condition     = can(regex("^Standard_", var.vm_size))
    error_message = "VM size must be a valid Azure Standard size."
  }
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "openclaw"
}

variable "admin_password" {
  description = "Admin password (only used if no SSH key provided)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for authentication (recommended over password)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID of the subnet to attach the VM to"
  type        = string
}

variable "network_security_group_id" {
  description = "ID of the network security group to attach"
  type        = string
}

# OS Disk Configuration
variable "os_disk_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "Premium_LRS"
  
  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS"], var.os_disk_type)
    error_message = "Invalid disk type. Must be Standard_LRS, Premium_LRS, or StandardSSD_LRS."
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

# Data Disk Configuration
variable "data_disk_size_gb" {
  description = "Data disk size in GB (0 = no data disk)"
  type        = number
  default     = 0
}

variable "data_disk_type" {
  description = "Data disk storage account type"
  type        = string
  default     = "Standard_LRS"
}

# Image Configuration
variable "image_publisher" {
  description = "OS image publisher"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "OS image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  description = "OS image SKU"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "image_version" {
  description = "OS image version"
  type        = string
  default     = "latest"
}

# OpenClaw Installation
variable "install_openclaw" {
  description = "Whether to install OpenClaw via cloud-init"
  type        = bool
  default     = true
}

variable "install_ollama" {
  description = "Whether to install Ollama"
  type        = bool
  default     = true
}

variable "ollama_models" {
  description = "List of Ollama models to pre-pull"
  type        = list(string)
  default     = ["llama3.1:8b", "nomic-embed-text"]
}

variable "enable_systemd" {
  description = "Whether to configure OpenClaw systemd service"
  type        = bool
  default     = true
}

variable "purpose" {
  description = "Purpose/role of this VM (for tagging)"
  type        = string
  default     = "openclaw-instance"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
