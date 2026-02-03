# Outputs for Network Security Module

output "vnet_id" {
  description = "ID of the virtual network"
  value       = local.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = var.vnet_name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = azurerm_subnet.main.name
}

output "nsg_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

output "nsg_name" {
  description = "Name of the network security group"
  value       = azurerm_network_security_group.main.name
}
