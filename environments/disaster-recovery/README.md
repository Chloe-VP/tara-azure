# Disaster Recovery Environment

Deploys a full OpenClaw instance to Azure VM for Mac mini backup/failover.

## Quick Start

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit values

# 2. Deploy
terraform init
terraform apply

# 3. Restore
VM_IP=$(terraform output -raw vm_public_ip)
../../scripts/restore-from-backup.sh $VM_IP ~/clawd-backup

# 4. Access
ssh chloe@$VM_IP
```

## What Gets Created

- Azure Resource Group
- Virtual Network + Subnet
- Network Security Group (SSH, HTTPS, port 8080)
- VM (Standard_D4s_v3 by default - 4 vCPU, 16GB RAM)
- Public IP address
- Managed disks (OS + optional data disk)
- Azure Storage Account for backups (optional)

## Cost

Approximately **$140-180/month** for Standard_D4s_v3 in westus2.

To save costs when not in use:
```bash
az vm deallocate -g chloe-recovery-rg -n chloe-dr-vm
```

This stops compute charges but keeps disks/data.

## Configuration

Edit `terraform.tfvars`:

```hcl
vm_size = "Standard_D4s_v3"  # Match Mac mini: 4 vCPU, 16GB
location = "westus2"          # Choose region
allowed_ssh_sources = ["YOUR_IP/32"]  # Restrict SSH access!
```

## Manual Steps After Deployment

Terraform creates the infrastructure and installs software, but you need to:

1. **Upload your backups** (if not done by script)
2. **Configure API keys** in `~/.openclaw/openclaw.json`
3. **Start OpenClaw service:** `sudo systemctl start openclaw`

## Cleanup

```bash
terraform destroy
```

This deletes **everything** - resource group, VM, disks, network, etc.

---

**Full documentation:** See `../../docs/USAGE.md`
