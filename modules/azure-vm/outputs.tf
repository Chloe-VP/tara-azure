# Outputs for Azure VM Module

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "admin_username" {
  description = "Admin username for SSH access"
  value       = var.admin_username
}

output "ssh_connection_string" {
  description = "SSH connection string for easy access"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = local.location
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.main.id
}
