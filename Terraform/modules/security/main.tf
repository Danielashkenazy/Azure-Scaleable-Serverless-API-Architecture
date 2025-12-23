######################################################################################
# Azure Key Vault
# Purpose: Centralized secrets management - never hardcode credentials!
# Features:
#   - Encrypted storage
#   - Access policies for RBAC
#   - Audit logging
#   - Secret versioning
# Production Note: Should use Managed Identity instead of access policies
######################################################################################

resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  
  #### Purge Protection ####
  # Disabled for dev/test (allows immediate re-creation)
  # Production: MUST be enabled to prevent accidental deletion
  purge_protection_enabled    = false
  
  tags = var.tags
}

######################################################################################
# Access Policy - Terraform Deployer
# Purpose: Allow Terraform to create/read secrets during deployment
# Production Best Practice: Use separate service principals for deploy vs runtime
######################################################################################

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = var.deployer_object_id

  secret_permissions = [
    "Get",
    "Set",
    "Delete",
    "List",
    "Purge"
  ]
}

######################################################################################
# Secrets Storage
# Purpose: Store all sensitive configuration
# Best Practice: Secrets are encrypted at rest and in transit
######################################################################################

#### Database Connection Secrets ####
resource "azurerm_key_vault_secret" "db_host" {
  name         = "pg-host"
  value        = var.db_host
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "db_username" {
  name         = "pg-username"
  value        = var.db_username
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-admin-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}

#### External API Key ####
resource "azurerm_key_vault_secret" "openweather_api_key" {
  name         = "openweather-api-key"
  value        = var.openweather_api_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}
