# Azure VM Module for OpenClaw
# Reusable module for creating Azure VMs with optional OpenClaw setup
#
# Author: Tara (Azure Infrastructure)
# Purpose: Repeatable VM provisioning across different scenarios

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Resource Group (create or use existing)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  
  tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "azure-vm"
    }
  )
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.existing[0].name
  location           = var.create_resource_group ? azurerm_resource_group.main[0].location : data.azurerm_resource_group.existing[0].location
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.vm_name}-pip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = var.tags
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  resource_group_name = local.resource_group_name
  location            = local.location
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
  
  tags = var.tags
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = var.network_security_group_id
}

# SSH Key
resource "azurerm_ssh_public_key" "main" {
  count               = var.ssh_public_key != "" ? 1 : 0
  name                = "${var.vm_name}-ssh-key"
  resource_group_name = local.resource_group_name
  location            = local.location
  public_key          = var.ssh_public_key
  
  tags = var.tags
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                  = var.vm_name
  resource_group_name   = local.resource_group_name
  location              = local.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.main.id]
  
  # Use SSH key if provided, otherwise generate
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }
  
  disable_password_authentication = var.ssh_public_key != "" ? true : false
  
  # Only set password if no SSH key provided
  admin_password = var.ssh_public_key == "" ? var.admin_password : null
  
  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }
  
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
  
  # Cloud-init custom data for provisioning
  custom_data = var.install_openclaw ? base64encode(templatefile(
    "${path.module}/scripts/cloud-init.yaml",
    {
      admin_username  = var.admin_username
      install_ollama  = var.install_ollama
      ollama_models   = jsonencode(var.ollama_models)
      enable_systemd  = var.enable_systemd
    }
  )) : null
  
  tags = merge(
    var.tags,
    {
      Name = var.vm_name
      Purpose = var.purpose
    }
  )
}

# Optional: Attach managed data disk
resource "azurerm_managed_disk" "data" {
  count                = var.data_disk_size_gb > 0 ? 1 : 0
  name                 = "${var.vm_name}-datadisk"
  resource_group_name  = local.resource_group_name
  location             = local.location
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  
  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.data_disk_size_gb > 0 ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.main.id
  lun                = 0
  caching            = "ReadWrite"
}
