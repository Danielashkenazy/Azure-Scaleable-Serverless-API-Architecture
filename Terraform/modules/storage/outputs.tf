######################################################################################
# Storage Module Outputs
######################################################################################

output "static_storage_account_name" {
  description = "Name of static website storage account"
  value       = azurerm_storage_account.static.name
}

output "static_website_endpoint" {
  description = "Primary web endpoint for static website"
  value       = azurerm_storage_account.static.primary_web_endpoint
}

output "function_storage_account_name" {
  description = "Name of Function App storage account"
  value       = azurerm_storage_account.func_storage.name
}

output "function_storage_primary_key" {
  description = "Primary access key for Function App storage"
  value       = azurerm_storage_account.func_storage.primary_access_key
  sensitive   = true
}
