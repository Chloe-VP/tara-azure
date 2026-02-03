# Azure Functions Module
# Creates a Function App with Application Insights and Key Vault integration

# Resource Group (optional - can use existing)
resource "azurerm_resource_group" "functions" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Storage Account for Function App
resource "azurerm_storage_account" "functions" {
  name                     = var.storage_account_name
  resource_group_name      = var.create_resource_group ? azurerm_resource_group.functions[0].name : var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  min_tls_version          = "TLS1_2"
  
  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "functions" {
  name                = var.app_insights_name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.functions[0].name : var.resource_group_name
  location            = var.location
  application_type    = var.app_insights_type
  retention_in_days   = var.app_insights_retention_days
  
  tags = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "functions" {
  name                = var.app_service_plan_name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.functions[0].name : var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.sku_name
  
  tags = var.tags
}

# Linux Function App
resource "azurerm_linux_function_app" "main" {
  count                      = var.os_type == "Linux" ? 1 : 0
  name                       = var.function_app_name
  resource_group_name        = var.create_resource_group ? azurerm_resource_group.functions[0].name : var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  
  site_config {
    application_stack {
      python_version = var.runtime_version
    }
    
    application_insights_connection_string = azurerm_application_insights.functions.connection_string
    application_insights_key               = azurerm_application_insights.functions.instrumentation_key
    
    dynamic "cors" {
      for_each = var.cors_allowed_origins != null ? [1] : []
      content {
        allowed_origins = var.cors_allowed_origins
      }
    }
  }
  
  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"       = var.runtime
      "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.functions.instrumentation_key
      "AzureWebJobsStorage"            = azurerm_storage_account.functions.primary_connection_string
    },
    var.key_vault_id != null ? {
      "KEY_VAULT_URI" = var.key_vault_id
    } : {},
    var.app_settings
  )
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Windows Function App
resource "azurerm_windows_function_app" "main" {
  count                      = var.os_type == "Windows" ? 1 : 0
  name                       = var.function_app_name
  resource_group_name        = var.create_resource_group ? azurerm_resource_group.functions[0].name : var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  
  site_config {
    application_stack {
      node_version              = var.runtime == "node" ? var.runtime_version : null
      dotnet_version            = var.runtime == "dotnet" ? var.runtime_version : null
      java_version              = var.runtime == "java" ? var.runtime_version : null
      powershell_core_version   = var.runtime == "powershell" ? var.runtime_version : null
    }
    
    application_insights_connection_string = azurerm_application_insights.functions.connection_string
    application_insights_key               = azurerm_application_insights.functions.instrumentation_key
    
    dynamic "cors" {
      for_each = var.cors_allowed_origins != null ? [1] : []
      content {
        allowed_origins = var.cors_allowed_origins
      }
    }
  }
  
  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"       = var.runtime
      "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.functions.instrumentation_key
      "AzureWebJobsStorage"            = azurerm_storage_account.functions.primary_connection_string
    },
    var.key_vault_id != null ? {
      "KEY_VAULT_URI" = var.key_vault_id
    } : {},
    var.app_settings
  )
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Key Vault Access Policy (if Key Vault ID provided)
resource "azurerm_key_vault_access_policy" "functions" {
  count        = var.key_vault_id != null ? 1 : 0
  key_vault_id = var.key_vault_id
  tenant_id    = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity[0].tenant_id : azurerm_windows_function_app.main[0].identity[0].tenant_id
  object_id    = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity[0].principal_id : azurerm_windows_function_app.main[0].identity[0].principal_id
  
  secret_permissions = [
    "Get",
    "List"
  ]
  
  certificate_permissions = [
    "Get",
    "List"
  ]
}
