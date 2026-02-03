# Variables for Disaster Recovery Environment

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "chloe-recovery-rg"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "westus2"
}

variable "vm_name" {
  description = "Name of the disaster recovery VM"
  type        = string
  default     = "chloe-dr-vm"
}

variable "vm_size" {
  description = "Azure VM size (match Mac mini specs: 4 vCPU, 16GB RAM)"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "chloe"
}

variable "ssh_public_key" {
  description = "SSH public key for authentication (leave empty to use ~/.ssh/id_rsa.pub)"
  type        = string
  default     = ""
}

variable "allowed_ssh_sources" {
  description = "IP ranges allowed to SSH (CIDR). Restrict in production!"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "data_disk_size_gb" {
  description = "Additional data disk size in GB (0 = no data disk)"
  type        = number
  default     = 256
}

variable "ollama_models" {
  description = "Ollama models to pre-install"
  type        = list(string)
  default     = [
    "llama3.1:8b",
    "nomic-embed-text"
  ]
}

variable "create_backup_storage" {
  description = "Whether to create Azure Storage for backups"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
