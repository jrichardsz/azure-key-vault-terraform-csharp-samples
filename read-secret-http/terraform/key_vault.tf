#Keyvault Creation

resource "random_pet" "rg_name" {
  prefix = var.base_name
}


resource "random_id" "kvname" {
  byte_length = 5
  prefix      = "keyvault"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv1" {
  depends_on                  = [azurerm_resource_group.rg]
  name                        = random_id.kvname.hex
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

# help the to logged-in user to see the secret using the azure portal ui
resource "azurerm_key_vault_access_policy" "for_logged_in_user" {
  key_vault_id = azurerm_key_vault.kv1.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "for_function" {
  key_vault_id = azurerm_key_vault.kv1.id
  tenant_id    = "${azurerm_windows_function_app.azure_function.identity[0].tenant_id}"
  object_id    = "${azurerm_windows_function_app.azure_function.identity[0].principal_id}"

  key_permissions = []

  secret_permissions = [
    "Get"
  ]
}

#Create KeyVault VM password
resource "random_password" "vmpassword" {
  length  = 20
  special = true
}

#Create Key Vault Secret
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  depends_on   = [azurerm_key_vault.kv1]
}