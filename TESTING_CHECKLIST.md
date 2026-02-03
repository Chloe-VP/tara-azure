# Testing Checklist

**Before production use, validate these scenarios**

## Pre-Testing Setup

- [ ] Azure subscription access confirmed
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform installed (>= 1.5)
- [ ] SSH key generated (`~/.ssh/id_rsa.pub`)
- [ ] Backup files available for restoration testing

## Module Testing

### azure-vm Module

- [ ] Terraform validate passes
- [ ] Terraform plan completes without errors
- [ ] VM deploys successfully
- [ ] VM is accessible via SSH
- [ ] Cloud-init completed (check `/var/log/cloud-init-output.log`)
- [ ] Node.js installed correctly (`node --version`)
- [ ] Ollama installed and running (`ollama list`)
- [ ] OpenClaw installed (`openclaw --version`)
- [ ] Systemd service created (`systemctl status openclaw`)
- [ ] Public IP accessible
- [ ] Can destroy cleanly (`terraform destroy`)

### network-security Module

- [ ] Terraform validate passes
- [ ] VNet created with correct CIDR
- [ ] Subnet created
- [ ] NSG has expected rules (SSH, HTTPS, custom)
- [ ] Can connect via SSH (allowed IP)
- [ ] Cannot connect from disallowed IP
- [ ] NSG attached to subnet correctly

## Environment Testing

### disaster-recovery Environment

- [ ] terraform.tfvars configured
- [ ] `terraform init` succeeds
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` completes successfully
- [ ] All outputs populate correctly
- [ ] VM boots and is accessible
- [ ] Backup restoration script works
- [ ] OpenClaw configs restored correctly
- [ ] OpenClaw service starts
- [ ] OpenClaw gateway responds (`openclaw gateway status`)
- [ ] Can connect to OpenClaw on port 8080
- [ ] Storage account created (if enabled)
- [ ] Cost estimates match Azure calculator
- [ ] `terraform destroy` removes everything

## Integration Testing

- [ ] Deploy from scratch
- [ ] Upload real backups
- [ ] Restore configuration
- [ ] Start OpenClaw service
- [ ] Test actual OpenClaw functionality
- [ ] Verify Telegram bot connects
- [ ] Check Application Insights logging (when added)

## Edge Cases & Error Handling

- [ ] Deploy with invalid VM size (should fail gracefully)
- [ ] Deploy with missing SSH key (should use password or fail)
- [ ] Deploy with restricted subnet CIDR (should fail)
- [ ] Destroy while VM is running (should stop gracefully)
- [ ] Re-apply after manual Azure portal changes (drift detection)
- [ ] Deploy to region with no quota (should fail with clear message)

## Security Testing

- [ ] SSH from allowed IP works
- [ ] SSH from disallowed IP fails
- [ ] No secrets in terraform.tfvars committed to git
- [ ] .gitignore prevents credential files
- [ ] SSH keys have correct permissions (600)
- [ ] NSG denies unexpected inbound traffic
- [ ] VM has no public IPs beyond expected

## Documentation Testing

- [ ] Follow USAGE.md step-by-step (works as written?)
- [ ] QUICK_REFERENCE.md commands work
- [ ] restore-from-backup.sh script works
- [ ] Example terraform.tfvars is valid
- [ ] README instructions are clear

## Performance Testing

- [ ] VM boots in reasonable time (< 5 minutes)
- [ ] Cloud-init completes in reasonable time (< 10 minutes)
- [ ] Ollama model pulling doesn't block other tasks
- [ ] rsync upload speed is acceptable
- [ ] Terraform apply completes in < 15 minutes
- [ ] Terraform destroy completes in < 5 minutes

## Cost Validation

- [ ] Actual monthly cost matches estimate
- [ ] `az vm deallocate` reduces cost as expected
- [ ] Storage costs are minimal when VM deallocated
- [ ] No unexpected charges (network egress, etc.)

## Cleanup Testing

- [ ] `terraform destroy` removes all resources
- [ ] No orphaned resources in Azure portal
- [ ] Resource group empty after destroy
- [ ] No lingering costs after destruction

---

## Test Results

| Test Category | Status | Notes | Date |
|---------------|--------|-------|------|
| Module Validation | ⏳ Pending | | |
| Basic Deployment | ⏳ Pending | | |
| Network Security | ⏳ Pending | | |
| Backup Restoration | ⏳ Pending | | |
| Full Integration | ⏳ Pending | | |
| Cost Validation | ⏳ Pending | | |
| Security | ⏳ Pending | | |
| Documentation | ⏳ Pending | | |

**Legend:** ⏳ Pending | ✅ Pass | ❌ Fail | ⚠️ Partial

---

## Known Issues

*Document any issues discovered during testing here*

---

**Tester:** ___________  
**Date:** ___________  
**Azure Subscription:** ___________  
**Terraform Version:** ___________
