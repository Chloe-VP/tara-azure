# Outputs for Disaster Recovery Environment

output "vm_public_ip" {
  description = "Public IP address of the disaster recovery VM"
  value       = module.openclaw_vm.public_ip_address
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = module.openclaw_vm.ssh_connection_string
}

output "vm_id" {
  description = "Azure VM resource ID"
  value       = module.openclaw_vm.vm_id
}

output "resource_group_name" {
  description = "Resource group name (for cleanup)"
  value       = azurerm_resource_group.main.name
}

output "backup_storage_account" {
  description = "Backup storage account name (if created)"
  value       = var.create_backup_storage ? azurerm_storage_account.backup[0].name : null
}

output "next_steps" {
  description = "Instructions for completing the disaster recovery setup"
  value       = <<-EOT
    ╔════════════════════════════════════════════════════════════════╗
    ║          DISASTER RECOVERY VM DEPLOYED SUCCESSFULLY            ║
    ╚════════════════════════════════════════════════════════════════╝
    
    VM Details:
      Public IP:  ${module.openclaw_vm.public_ip_address}
      SSH:        ${module.openclaw_vm.ssh_connection_string}
      Region:     ${var.location}
      Size:       ${var.vm_size}
    
    NEXT STEPS:
    
    1. Connect to the VM:
       ${module.openclaw_vm.ssh_connection_string}
    
    2. Transfer backup files:
       rsync -avz ~/clawd-backup/ ${var.admin_username}@${module.openclaw_vm.public_ip_address}:~/backup/
    
    3. Restore OpenClaw config:
       ssh ${var.admin_username}@${module.openclaw_vm.public_ip_address}
       cd ~/backup
       tar -xzf config/openclaw-*.tar.gz -C ~/.openclaw --strip-components=1
       tar -xzf credentials/clawdbot-creds-*.tar.gz -C ~/.clawdbot --strip-components=1
    
    4. Update API keys:
       nano ~/.openclaw/openclaw.json
       # Add ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN, etc.
    
    5. Start OpenClaw:
       sudo systemctl start openclaw
       sudo systemctl status openclaw
    
    6. Test the deployment:
       openclaw gateway status
       curl http://localhost:8080/health
    
    7. Check logs:
       sudo journalctl -u openclaw -f
    
    COST MANAGEMENT:
      - Monthly cost: ~$140-180 (${var.vm_size} @ ${var.location})
      - To stop (keeps disk): az vm deallocate -g ${azurerm_resource_group.main.name} -n ${var.vm_name}
      - To delete everything: terraform destroy
    
    AUTOMATION SCRIPT:
      A helper script has been generated at:
      ./scripts/restore-from-backup.sh
  EOT
}
