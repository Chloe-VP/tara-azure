# Tara Azure Infrastructure

**Repeatable infrastructure-as-code for OpenClaw deployments on Azure**

Created by: Tara (Azure Infrastructure Specialist)  
Purpose: Convert one-off scripts into maintainable, reusable Terraform modules

## What This Does

This repo provides **modular Terraform** for deploying OpenClaw infrastructure to Azure:

1. **Azure VM provisioning** - Spin up VMs with correct specs
2. **OpenClaw installation** - Automated setup of dependencies and services
3. **Configuration restoration** - Restore from backups automatically
4. **Disaster Recovery** - Full Mac mini restore to Azure VM
5. **Azure Functions** (coming soon) - Serverless function deployment

## Architecture

```
tara-azure/
├── modules/
│   ├── azure-vm/           # Reusable VM module
│   ├── openclaw-setup/     # OpenClaw installation scripts
│   └── network-security/   # Network and firewall rules
├── environments/
│   ├── disaster-recovery/  # DR scenario: Mac mini → Azure
│   └── azure-functions/    # Serverless deployment (coming)
├── scripts/
│   └── provision/          # Cloud-init and setup scripts
└── docs/
    ├── USAGE.md           # How to use these modules
    └── AZURE_FUNCTIONS_PLAN.md  # Next automation target
```

## Quick Start

### Prerequisites

- Azure CLI installed (`brew install azure-cli`)
- Terraform installed (`brew install terraform`)
- Azure subscription with permissions
- Authenticated: `az login`

### Deploy Disaster Recovery VM

```bash
cd environments/disaster-recovery
terraform init
terraform plan -var="backup_source=/path/to/backup"
terraform apply
```

### Use Modules in Your Own Config

```hcl
module "openclaw_vm" {
  source = "github.com/VelocityPoint/tara-azure//modules/azure-vm"
  
  resource_group_name = "my-rg"
  location           = "westus2"
  vm_name            = "my-openclaw-vm"
  vm_size            = "Standard_D4s_v3"
  
  install_openclaw   = true
  enable_systemd     = true
}
```

## Design Principles

1. **Modular** - Each component is independently reusable
2. **Declarative** - Describe what you want, not how to get there
3. **Idempotent** - Safe to run multiple times
4. **Documented** - Every variable explained, every decision documented
5. **Production-ready** - Proper state management, remote backends, locking

## Cost Estimates

| VM Size | vCPU | RAM | Monthly Cost (westus2) |
|---------|------|-----|------------------------|
| Standard_D2s_v3 | 2 | 8GB | ~$70-90 |
| Standard_D4s_v3 | 4 | 16GB | ~$140-180 |
| Standard_D8s_v3 | 8 | 32GB | ~$280-360 |

*Estimates include VM + managed disk + network. Actual costs vary by region.*

## Why Terraform Instead of Scripts?

The original `restore-to-azure-vm.sh` was great for understanding the problem, but:

❌ **Script problems:**
- Imperative (do this, then this, then this)
- No state tracking (what's already created?)
- Hard to reuse (lots of global variables)
- Manual cleanup (delete everything by hand)
- No drift detection (did someone change it?)

✅ **Terraform benefits:**
- Declarative (here's what should exist)
- State tracking (knows what's created)
- Modular (import and customize)
- `terraform destroy` cleans up everything
- `terraform plan` shows what will change

## Roadmap

- [x] Initial structure and documentation
- [x] Azure VM module with cloud-init provisioning
- [x] Network security group module
- [x] OpenClaw installation scripts
- [x] Disaster recovery environment
- [ ] Azure Functions deployment automation
- [ ] Backup restoration from Azure Blob Storage
- [ ] Multi-region deployment
- [ ] Auto-scaling groups

## Contributing

This is Dave's infrastructure. Changes via PR with clear rationale.

---

*Built with ☁️ by Tara - Making Dave's infrastructure life easier since 2026*
