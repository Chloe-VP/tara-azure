# Usage Guide

Complete guide for using Tara's Azure infrastructure modules.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Module Reference](#module-reference)
3. [Common Scenarios](#common-scenarios)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

```bash
# Install Azure CLI
brew install azure-cli

# Install Terraform
brew install terraform

# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

### Deploy Disaster Recovery VM

```bash
# Clone the repo
cd ~/Documents/repos/Chloe-VP/tara-azure

# Navigate to disaster recovery environment
cd environments/disaster-recovery

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (will prompt for confirmation)
terraform apply

# Save outputs
terraform output > deployment-info.txt
```

### Restore from Backup

```bash
# Get VM IP from Terraform output
VM_IP=$(terraform output -raw vm_public_ip)

# Upload backup files
rsync -avz ~/clawd-backup/ chloe@${VM_IP}:~/backup/

# SSH to VM and restore
ssh chloe@${VM_IP}

# On the VM:
cd ~/backup
tar -xzf config/openclaw-*.tar.gz -C ~/.openclaw --strip-components=1
tar -xzf credentials/clawdbot-creds-*.tar.gz -C ~/.clawdbot --strip-components=1

# Update API keys
nano ~/.openclaw/openclaw.json

# Start service
sudo systemctl start openclaw
sudo systemctl status openclaw
```

---

## Module Reference

### azure-vm Module

Creates an Azure VM with optional OpenClaw installation.

**Basic usage:**

```hcl
module "my_vm" {
  source = "github.com/VelocityPoint/tara-azure//modules/azure-vm"
  
  resource_group_name = "my-rg"
  location           = "westus2"
  vm_name            = "my-openclaw-vm"
  vm_size            = "Standard_D4s_v3"
  admin_username     = "openclaw"
  ssh_public_key     = file("~/.ssh/id_rsa.pub")
  
  subnet_id                 = module.network.subnet_id
  network_security_group_id = module.network.nsg_id
  
  install_openclaw = true
  install_ollama   = true
}
```

**Key variables:**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_size` | string | `Standard_D4s_v3` | Azure VM size |
| `install_openclaw` | bool | `true` | Install OpenClaw via cloud-init |
| `install_ollama` | bool | `true` | Install Ollama for local models |
| `ollama_models` | list(string) | `["llama3.1:8b"]` | Models to pre-pull |
| `os_disk_size_gb` | number | `128` | OS disk size |
| `data_disk_size_gb` | number | `0` | Additional data disk (0=none) |

**Outputs:**

- `public_ip_address` - Public IP for SSH/access
- `ssh_connection_string` - Ready-to-use SSH command
- `vm_id` - Azure resource ID

### network-security Module

Creates VNet, subnet, and NSG with configurable firewall rules.

**Basic usage:**

```hcl
module "network" {
  source = "github.com/VelocityPoint/tara-azure//modules/network-security"
  
  resource_group_name = "my-rg"
  location           = "westus2"
  
  vnet_name             = "my-vnet"
  subnet_name           = "my-subnet"
  nsg_name              = "my-nsg"
  
  allowed_ssh_sources   = ["YOUR.IP.ADDRESS/32"]
  allow_https           = true
  custom_ports          = [8080]
}
```

**Key variables:**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `allowed_ssh_sources` | list(string) | `["0.0.0.0/0"]` | IPs allowed to SSH |
| `allow_https` | bool | `true` | Open port 443 |
| `allow_http` | bool | `false` | Open port 80 |
| `custom_ports` | list(number) | `[]` | Additional TCP ports |

**Outputs:**

- `subnet_id` - For attaching VMs
- `nsg_id` - For attaching to NICs
- `vnet_id` - For peering or gateways

---

## Common Scenarios

### Scenario 1: Disaster Recovery

**Goal:** Full Mac mini backup to Azure VM

**Solution:** Use `environments/disaster-recovery`

**Steps:**
1. Deploy infrastructure: `terraform apply`
2. Upload backups: `rsync -avz ~/clawd-backup/ user@vm:~/backup/`
3. Restore configs on VM
4. Start OpenClaw service

**Cost:** ~$140-180/month

---

### Scenario 2: Development/Testing VM

**Goal:** Temporary VM for testing OpenClaw changes

**Solution:** Create custom environment

```hcl
module "dev_vm" {
  source = "../../modules/azure-vm"
  
  vm_name  = "openclaw-dev"
  vm_size  = "Standard_D2s_v3"  # Smaller/cheaper
  
  install_openclaw = true
  install_ollama   = false  # Skip Ollama for faster boot
  enable_systemd   = false  # Manual start for testing
}
```

**Cost:** ~$70-90/month (deallocate when not in use to save costs)

---

### Scenario 3: Azure Functions Deployment

**Goal:** Deploy Second Ring functions to Azure

**Solution:** Coming soon - see `docs/AZURE_FUNCTIONS_PLAN.md`

---

## Best Practices

### Security

1. **Restrict SSH access:**
   ```hcl
   allowed_ssh_sources = ["YOUR.PUBLIC.IP/32"]
   ```

2. **Use SSH keys, not passwords:**
   ```hcl
   ssh_public_key = file("~/.ssh/id_rsa.pub")
   ```

3. **Store secrets in Azure Key Vault:**
   ```bash
   az keyvault create --name my-vault --resource-group my-rg
   az keyvault secret set --vault-name my-vault --name ANTHROPIC_API_KEY --value "sk-..."
   ```

### Cost Management

1. **Deallocate when not in use:**
   ```bash
   az vm deallocate -g my-rg -n my-vm  # Stops billing for compute
   ```

2. **Use appropriate VM sizes:**
   - Dev/test: `Standard_D2s_v3` (2 vCPU, 8GB) - ~$70/mo
   - Production: `Standard_D4s_v3` (4 vCPU, 16GB) - ~$140/mo

3. **Enable auto-shutdown:**
   ```bash
   az vm auto-shutdown -g my-rg -n my-vm --time 1900  # 7 PM local time
   ```

### State Management

1. **Use remote state for teams:**
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "terraform-state-rg"
       storage_account_name = "tfstate"
       container_name       = "tfstate"
       key                  = "openclaw.tfstate"
     }
   }
   ```

2. **Enable state locking** (prevents concurrent modifications)

3. **Never commit `.tfstate` files to git**

---

## Troubleshooting

### VM won't connect via SSH

**Problem:** `ssh: connect to host X.X.X.X port 22: Connection refused`

**Solutions:**
1. Check NSG rules: `az network nsg rule list -g my-rg --nsg-name my-nsg`
2. Verify VM is running: `az vm get-instance-view -g my-rg -n my-vm`
3. Check public IP: `az vm show -g my-rg -n my-vm --show-details --query publicIps`
4. Wait 2-3 minutes after creation for SSH to start

### Cloud-init didn't run

**Problem:** OpenClaw not installed after deployment

**Check cloud-init logs:**
```bash
ssh user@vm
sudo cat /var/log/cloud-init-output.log
sudo cloud-init status
```

**Force re-run (careful - may cause issues):**
```bash
sudo cloud-init clean
sudo cloud-init init
sudo cloud-init modules --mode final
```

### Terraform state is locked

**Problem:** `Error: Error locking state: Error acquiring the state lock`

**Solution:**
```bash
# Check who has the lock
terraform force-unlock <LOCK_ID>

# Or manually remove lock from backend
```

### Out of quota

**Problem:** `QuotaExceeded: Operation could not be completed as it results in exceeding approved standardDSv3Family Cores quota`

**Solution:**
```bash
# Check current quotas
az vm list-usage --location westus2 -o table

# Request quota increase (Azure portal or CLI)
az support tickets create ...
```

---

## Additional Resources

- [Azure VM Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Azure Regions](https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/)
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [OpenClaw Documentation](https://openclaw.dev)

---

**Questions?** Open an issue or ask Dave.

*Updated: 2026-02-03 by Tara*
