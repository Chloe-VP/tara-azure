# Azure Functions Terraform Module

Production-ready Terraform module for deploying Azure Functions with Application Insights and Key Vault integration.

## Features

- ✅ Azure Function App (Linux or Windows)
- ✅ Application Insights integration
- ✅ Key Vault integration with managed identity
- ✅ Configurable SKUs (Consumption, Premium, Dedicated)
- ✅ CORS support
- ✅ Custom app settings
- ✅ Secure by default (TLS 1.2+, managed identity)

## Usage

```hcl
module "api_functions" {
  source = "../../modules/azure-functions"
  
  resource_group_name      = "rg-secondring-prod"
  location                 = "eastus"
  function_app_name        = "func-secondring-api-prod"
  storage_account_name     = "stsecondringprod"
  app_service_plan_name    = "plan-secondring-prod"
  app_insights_name        = "appi-secondring-prod"
  
  # SKU options
  sku_name = "EP1"  # Elastic Premium
  
  # Runtime
  os_type         = "Linux"
  runtime         = "python"
  runtime_version = "3.11"
  
  # Key Vault integration
  key_vault_id = azurerm_key_vault.main.id
  
  # Custom app settings
  app_settings = {
    "ENVIRONMENT" = "production"
    "LOG_LEVEL"   = "INFO"
  }
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## SKU Options

| SKU | Type | Description |
|-----|------|-------------|
| Y1 | Consumption | Pay-per-execution, auto-scale |
| EP1, EP2, EP3 | Elastic Premium | Pre-warmed workers, VNET integration |
| P1v2, P2v2, P3v2 | Dedicated | Dedicated compute |

## Key Vault Integration

When `key_vault_id` is provided:
- Function App gets system-assigned managed identity
- Access policy automatically created for secrets/certificates
- Key Vault URI available as `KEY_VAULT_URI` app setting

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| resource_group_name | string | - | Resource group name |
| create_resource_group | bool | false | Create new RG or use existing |
| location | string | - | Azure region |
| function_app_name | string | - | Function App name |
| storage_account_name | string | - | Storage account name (3-24 chars, lowercase) |
| sku_name | string | Y1 | App Service Plan SKU |
| os_type | string | Linux | OS type (Linux/Windows) |
| runtime | string | python | Runtime (python/node/dotnet/java) |
| runtime_version | string | 3.11 | Runtime version |
| key_vault_id | string | null | Key Vault ID for integration |
| app_settings | map(string) | {} | Custom app settings |
| cors_allowed_origins | list(string) | null | CORS allowed origins |
| tags | map(string) | {} | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| function_app_id | Function App ID |
| function_app_name | Function App name |
| function_app_default_hostname | Default hostname |
| function_app_principal_id | Managed identity principal ID |
| app_insights_instrumentation_key | App Insights key (sensitive) |
| storage_account_primary_connection_string | Storage connection string (sensitive) |

## Examples

### Consumption Plan

```hcl
module "functions" {
  source = "../../modules/azure-functions"
  
  resource_group_name   = "rg-dev"
  location              = "eastus"
  function_app_name     = "func-dev"
  storage_account_name  = "stfuncdev"
  app_service_plan_name = "plan-dev"
  app_insights_name     = "appi-dev"
  
  sku_name = "Y1"
}
```

### Premium Plan with Key Vault

```hcl
module "functions" {
  source = "../../modules/azure-functions"
  
  resource_group_name   = "rg-prod"
  location              = "eastus"
  function_app_name     = "func-prod"
  storage_account_name  = "stfuncprod"
  app_service_plan_name = "plan-prod"
  app_insights_name     = "appi-prod"
  
  sku_name     = "EP1"
  key_vault_id = azurerm_key_vault.prod.id
  
  app_settings = {
    "DB_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db.id})"
  }
}
```

## Notes

- Storage account names must be globally unique
- Function App names must be globally unique
- Managed identity is always enabled for Key Vault access
- Application Insights is always created and configured
- `WEBSITE_RUN_FROM_PACKAGE` is ignored in lifecycle to prevent deployment conflicts

## License

MIT
