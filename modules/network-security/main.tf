# Network Security Module
# Creates VNet, subnet, and NSG with configurable firewall rules
#
# Author: Tara (Azure Infrastructure)

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  count               = var.create_vnet ? 1 : 0
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  
  tags = var.tags
}

data "azurerm_virtual_network" "existing" {
  count               = var.create_vnet ? 0 : 1
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

locals {
  vnet_id = var.create_vnet ? azurerm_virtual_network.main[0].id : data.azurerm_virtual_network.existing[0].id
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_address_prefix]
  
  depends_on = [
    azurerm_virtual_network.main
  ]
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = var.nsg_name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  tags = var.tags
}

# SSH Rule (always included)
resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowSSH"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_ssh_sources
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# HTTPS Rule (optional)
resource "azurerm_network_security_rule" "https" {
  count                       = var.allow_https ? 1 : 0
  name                        = "AllowHTTPS"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# HTTP Rule (optional)
resource "azurerm_network_security_rule" "http" {
  count                       = var.allow_http ? 1 : 0
  name                        = "AllowHTTP"
  priority                    = 1020
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Custom Ports (dynamic)
resource "azurerm_network_security_rule" "custom" {
  for_each = { for idx, port in var.custom_ports : idx => port }
  
  name                        = "AllowCustom${each.value}"
  priority                    = 1100 + each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Deny all other inbound traffic (implicit, but explicit here)
resource "azurerm_network_security_rule" "deny_all" {
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}
