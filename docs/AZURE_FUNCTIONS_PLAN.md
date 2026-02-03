# Azure Functions Deployment Plan

**Next automation target for Tara's infrastructure toolkit**

## Overview

After establishing repeatable VM provisioning, the next step is automating Azure Functions deployment for Second Ring and other serverless workloads.

## Current State (Manual Process)

Right now, deploying Azure Functions involves:
1. Creating Function App in Azure Portal
2. Configuring runtime settings manually
3. Setting environment variables one-by-one
4. Deploying code via VS Code extension or `func azure functionapp publish`
5. Configuring bindings and triggers manually
6. Setting up Application Insights manually

**Problems:**
- Error-prone (easy to forget a setting)
- Not reproducible (what exactly did we configure?)
- No version control of infrastructure
- Hard to replicate across environments (dev/staging/prod)

## Target State (Terraform-Managed)

Infrastructure-as-code for Azure Functions:

```
environments/azure-functions/
├── main.tf                    # Function App infrastructure
├── variables.tf               # Configuration
├── outputs.tf                 # Endpoints, keys, etc.
├── terraform.tfvars.example   # Template
└── functions/
    ├── second-ring-inbound/   # Call handling function
    ├── second-ring-outbound/  # Callback function
    └── webhook-handlers/      # GHL webhooks
```

## Architecture

### Function App Components

```
Azure Function App
├── App Service Plan (Consumption or Premium)
├── Storage Account (function app data)
├── Application Insights (monitoring)
├── Key Vault (secrets)
└── Functions
    ├── HTTP Triggers (webhooks, API endpoints)
    ├── Timer Triggers (scheduled jobs)
    └── Queue Triggers (async processing)
```

### Infrastructure Modules

**Module 1: Function App Base**
- Creates Function App resource
- Configures runtime (Node.js, Python, etc.)
- Sets up Application Insights
- Connects to Storage Account

**Module 2: Function Deployment**
- Packages function code
- Uploads to Azure
- Configures app settings
- Sets up bindings

**Module 3: API Management** (optional)
- Puts API Gateway in front of functions
- Rate limiting, authentication
- Custom domains

## Implementation Plan

### Phase 1: Basic Function App Provisioning

**Goal:** Terraform creates Function App infrastructure

**Deliverables:**
```hcl
module "function_app" {
  source = "../../modules/azure-functions"
  
  name                = "second-ring-functions"
  resource_group_name = "second-ring-rg"
  location           = "westus2"
  
  runtime = "node"
  runtime_version = "20"
  
  app_settings = {
    "ANTHROPIC_API_KEY" = "@Microsoft.KeyVault(SecretUri=...)"
    "GHL_API_KEY"       = "@Microsoft.KeyVault(SecretUri=...)"
    "DB_CONNECTION"     = "..."
  }
}
```

**Tasks:**
- [x] Research Azure Functions Terraform provider
- [ ] Create `modules/azure-functions/` base module
- [ ] Add Application Insights integration
- [ ] Add Key Vault for secrets
- [ ] Document configuration options

**Timeline:** 1-2 days

---

### Phase 2: Code Deployment Automation

**Goal:** `terraform apply` deploys both infrastructure AND code

**Approach:**
```bash
# Package function code
npm run build
zip -r function.zip .

# Terraform uploads it
resource "azurerm_function_app_function" "inbound_call" {
  name            = "inbound-call-handler"
  function_app_id = azurerm_linux_function_app.main.id
  language        = "Javascript"
  file {
    name    = "index.js"
    content = file("${path.module}/functions/inbound/index.js")
  }
  config_json = jsonencode({
    bindings = [
      {
        type      = "httpTrigger"
        direction = "in"
        name      = "req"
        methods   = ["post"]
      }
    ]
  })
}
```

**Challenges:**
- Function code needs to be built/bundled first
- Large codebases may exceed Terraform size limits
- May need external deployment step

**Alternative:** Terraform creates infra, GitHub Actions deploys code

**Tasks:**
- [ ] Test code deployment via Terraform
- [ ] Create CI/CD pipeline for function deployment
- [ ] Document deployment workflow
- [ ] Add rollback mechanism

**Timeline:** 2-3 days

---

### Phase 3: Environment Promotion

**Goal:** Easy promotion from dev → staging → prod

**Structure:**
```
environments/
├── functions-dev/
│   └── main.tf
├── functions-staging/
│   └── main.tf
└── functions-prod/
    └── main.tf
```

**Key features:**
- Separate resource groups per environment
- Different scaling configurations
- Environment-specific app settings
- Slot deployments for zero-downtime updates

**Tasks:**
- [ ] Create environment templates
- [ ] Add slot deployment support
- [ ] Configure traffic splitting (blue/green)
- [ ] Add approval gates for prod

**Timeline:** 1-2 days

---

### Phase 4: Monitoring & Observability

**Goal:** Comprehensive monitoring out-of-the-box

**Features:**
- Application Insights dashboards
- Alert rules for failures/latency
- Log Analytics queries
- Cost monitoring

**Tasks:**
- [ ] Create Application Insights module
- [ ] Add pre-configured dashboards
- [ ] Set up alert rules
- [ ] Add cost alerts

**Timeline:** 1 day

---

## Design Decisions

### Consumption vs Premium vs Dedicated

| Plan | Use Case | Cost | Features |
|------|----------|------|----------|
| **Consumption** | Low-traffic, bursty | Pay-per-execution | Auto-scale, cold start |
| **Premium** | Production, consistent traffic | ~$150/mo base | Always-warm, VNet integration |
| **Dedicated** | High-traffic, complex workloads | App Service pricing | Full control |

**Recommendation:** Start with Consumption for dev, Premium for production Second Ring.

### Secrets Management

**Options:**
1. **Azure Key Vault** (recommended)
   - Secure storage
   - Audit logging
   - RBAC
2. **App Settings** (not recommended for production)
   - Visible in portal
   - No audit trail

**Decision:** Use Key Vault references in app settings

### Deployment Strategy

**Options:**
1. **Terraform-managed code** - Infrastructure AND code in one apply
2. **Terraform infra + GitHub Actions code** - Separation of concerns
3. **Terraform infra + Azure DevOps** - Microsoft-native CI/CD

**Recommendation:** Option 2 (Terraform + GitHub Actions)
- Clear separation of infrastructure and application code
- Faster iteration on code (no Terraform apply needed)
- Standard deployment pattern

## Success Criteria

✅ **Phase 1 Complete When:**
- `terraform apply` creates Function App infrastructure
- App is accessible and healthy
- Application Insights is logging
- Secrets are in Key Vault

✅ **Phase 2 Complete When:**
- CI/CD pipeline deploys function code automatically
- Deployment is idempotent
- Rollback works

✅ **Phase 3 Complete When:**
- Dev/staging/prod environments are reproducible
- Promotion requires only variable changes
- Zero-downtime deployments work

✅ **Phase 4 Complete When:**
- Dashboards show function health
- Alerts fire on failures
- Costs are tracked and alerted

## Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Infrastructure | 1-2 days | Azure subscription |
| Phase 2: Deployment | 2-3 days | Phase 1, GitHub repo |
| Phase 3: Environments | 1-2 days | Phase 2 |
| Phase 4: Monitoring | 1 day | Phase 1 |

**Total:** ~1 week for full implementation

**Parallel work:** Phases 1 & 4 can be developed simultaneously

## Next Steps

1. **Dave approval** on approach
2. **Research spike** - Validate Terraform Azure Functions provider capabilities
3. **Create base module** - Start with Phase 1
4. **Test deployment** - Verify with simple "hello world" function
5. **Iterate** - Add features based on actual Second Ring needs

## Questions for Dave

1. **Hosting plan preference?** Consumption (cheaper) vs Premium (faster)?
2. **Deployment trigger?** Git push? Manual? Scheduled?
3. **Environment strategy?** Single tenant vs multi-tenant?
4. **Region preference?** Match existing resources or optimize for latency?
5. **Budget constraints?** Any cost ceilings for function apps?

---

**Status:** Planning phase  
**Owner:** Tara (Azure Infrastructure)  
**Priority:** Next after VM provisioning is solid  
**Updated:** 2026-02-03

*This plan will evolve as we learn more about Second Ring's specific requirements.*
