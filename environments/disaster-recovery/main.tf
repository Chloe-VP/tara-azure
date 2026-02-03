# Disaster Recovery Environment
# Deploys OpenClaw to Azure VM for Mac mini backup/failover
#
# Author: Tara (Azure Infrastructure)
# Purpose: Full disaster recovery deployment

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = true
      skip_shutdown_and_force_delete = false
    }
  }
}

# Local variables
locals {
  environment = "disaster-recovery"
  project     = "openclaw"
  
  common_tags = merge(
    var.tags,
    {
      Environment = local.environment
      Project     = local.project
      ManagedBy   = "Terraform"
      Purpose     = "Chloe Mac mini disaster recovery"
      CreatedBy   = "Tara"
    }
  )
}

# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = local.common_tags
}

# Network infrastructure
module "network" {
  source = "../../modules/network-security"
  
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  
  create_vnet           = true
  vnet_name             = "${var.vm_name}-vnet"
  vnet_address_space    = "10.0.0.0/16"
  
  subnet_name           = "${var.vm_name}-subnet"
  subnet_address_prefix = "10.0.1.0/24"
  
  nsg_name              = "${var.vm_name}-nsg"
  allowed_ssh_sources   = var.allowed_ssh_sources
  allow_https           = true
  allow_http            = false
  custom_ports          = [8080]  # OpenClaw gateway
  
  tags = local.common_tags
}

# OpenClaw VM
module "openclaw_vm" {
  source = "../../modules/azure-vm"
  
  resource_group_name        = azurerm_resource_group.main.name
  create_resource_group      = false  # Already created above
  location                   = azurerm_resource_group.main.location
  
  vm_name                    = var.vm_name
  vm_size                    = var.vm_size
  admin_username             = var.admin_username
  ssh_public_key             = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_rsa.pub")
  
  subnet_id                  = module.network.subnet_id
  network_security_group_id  = module.network.nsg_id
  
  # Storage
  os_disk_type               = "Premium_LRS"
  os_disk_size_gb            = 128
  data_disk_size_gb          = var.data_disk_size_gb
  
  # OpenClaw setup
  install_openclaw           = true
  install_ollama             = true
  ollama_models              = var.ollama_models
  enable_systemd             = true
  
  purpose                    = "disaster-recovery"
  tags                       = local.common_tags
}

# Backup storage (optional - for storing backups in Azure)
resource "azurerm_storage_account" "backup" {
  count                    = var.create_backup_storage ? 1 : 0
  name                     = replace("${var.vm_name}backup", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = local.common_tags
}

resource "azurerm_storage_container" "backup" {
  count                 = var.create_backup_storage ? 1 : 0
  name                  = "openclaw-backups"
  storage_account_name  = azurerm_storage_account.backup[0].name
  container_access_type = "private"
}
