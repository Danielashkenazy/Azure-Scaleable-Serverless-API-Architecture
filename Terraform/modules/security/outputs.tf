######################################################################################
# Security Module Outputs
######################################################################################

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "db_host_secret_value" {
  description = "Database host from Key Vault"
  value       = azurerm_key_vault_secret.db_host.value
  sensitive   = true
}

output "db_username_secret_value" {
  description = "Database username from Key Vault"
  value       = azurerm_key_vault_secret.db_username.value
  sensitive   = true
}

output "db_password_secret_value" {
  description = "Database password from Key Vault"
  value       = azurerm_key_vault_secret.db_password.value
  sensitive   = true
}

output "openweather_api_key_secret_value" {
  description = "OpenWeather API key from Key Vault"
  value       = azurerm_key_vault_secret.openweather_api_key.value
  sensitive   = true
}
