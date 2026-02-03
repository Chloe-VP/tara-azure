# Variables for Network Security Module

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

# VNet Configuration
variable "create_vnet" {
  description = "Whether to create a new VNet or use existing"
  type        = bool
  default     = true
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet (CIDR)"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet Configuration
variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet (CIDR)"
  type        = string
  default     = "10.0.1.0/24"
}

# NSG Configuration
variable "nsg_name" {
  description = "Name of the network security group"
  type        = string
}

variable "allowed_ssh_sources" {
  description = "List of source IP ranges allowed to SSH (CIDR notation)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Consider restricting in production!
}

variable "allow_https" {
  description = "Whether to allow HTTPS (port 443) inbound"
  type        = bool
  default     = true
}

variable "allow_http" {
  description = "Whether to allow HTTP (port 80) inbound"
  type        = bool
  default     = false
}

variable "custom_ports" {
  description = "List of additional TCP ports to allow inbound"
  type        = list(number)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
