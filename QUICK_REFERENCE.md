# Quick Reference

**TL;DR for busy people**

## Deploy Disaster Recovery VM

```bash
cd ~/Documents/repos/Chloe-VP/tara-azure/environments/disaster-recovery
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## Restore from Backup

```bash
VM_IP=$(terraform output -raw vm_public_ip)
./../../scripts/restore-from-backup.sh $VM_IP ~/clawd-backup
```

## Common Commands

```bash
# Check VM status
az vm show -g chloe-recovery-rg -n chloe-dr-vm --query "powerState"

# Stop VM (save costs)
az vm deallocate -g chloe-recovery-rg -n chloe-dr-vm

# Start VM
az vm start -g chloe-recovery-rg -n chloe-dr-vm

# Get VM IP
az vm show -g chloe-recovery-rg -n chloe-dr-vm --show-details --query publicIps -o tsv

# Delete everything
terraform destroy
```

## SSH to VM

```bash
ssh chloe@<VM_IP>
```

## Check OpenClaw Status

```bash
# On the VM:
openclaw gateway status
sudo systemctl status openclaw
sudo journalctl -u openclaw -f
```

## Module Usage

```hcl
# Use VM module in your own config
module "my_vm" {
  source = "github.com/VelocityPoint/tara-azure//modules/azure-vm"
  
  resource_group_name = "my-rg"
  vm_name            = "my-vm"
  subnet_id          = "..."
  network_security_group_id = "..."
}
```

## Cost Estimates

- **Standard_D2s_v3** (2 vCPU, 8GB): ~$70-90/mo
- **Standard_D4s_v3** (4 vCPU, 16GB): ~$140-180/mo
- **Standard_D8s_v3** (8 vCPU, 32GB): ~$280-360/mo

Stop VMs when not in use to save money!

---

**Full docs:** See `docs/USAGE.md`
