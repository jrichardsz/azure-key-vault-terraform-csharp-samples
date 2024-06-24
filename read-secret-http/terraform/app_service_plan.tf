#### APP SERVICE PLAN
resource "azurerm_storage_account" "apps_storage" {
  name                     = "storage${var.base_name}${var.environment}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_service_plan" "func_apps" {
  name                = "srvpl-${var.base_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "S1"

  tags = var.tags
}

resource "azurerm_application_insights" "application_insights" {
    name                = "appinsights-${var.base_name}-${var.environment}"
    location = var.location
    resource_group_name = azurerm_resource_group.rg.name
    application_type = "other"
}

resource "azurerm_windows_function_app" "azure_function" {
  name                  = "az-function-${var.base_name}-${var.environment}"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  storage_account_name        = azurerm_storage_account.apps_storage.name
  storage_account_access_key  = azurerm_storage_account.apps_storage.primary_access_key
  service_plan_id             = azurerm_service_plan.func_apps.id
  identity {
      type = "SystemAssigned"
  }
    
  app_settings = {
      FUNCTIONS_EXTENSION_VERSION = "~4"
      SCM_DO_BUILD_DURING_DEPLOYMENT = true
      FUNCTIONS_WORKER_RUNTIME                          = "dotnet-isolated"
      APPINSIGHTS_INSTRUMENTATIONKEY                    = azurerm_application_insights.application_insights.instrumentation_key
      KEY_VAULT_NAME = random_id.kvname.hex
  }

  site_config {
    application_stack {
      dotnet_version = "v6.0"
    }
  }  

  tags = var.tags
  
}