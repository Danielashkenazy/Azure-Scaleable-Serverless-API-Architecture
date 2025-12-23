output "frontdoor_endpoint" {
  value = azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name
}

output "api_gateway_url" {
  value = "${azurerm_api_management.apimm.gateway_url}"
  description = "Base URL for API Management."
}

output "function_default_hostname" {
  value = azurerm_linux_function_app.weather_api.default_hostname
  description = "Default hostname for Function App (useful for debugging)."
}

output "static_website_url" {
  value = azurerm_storage_account.static.primary_web_endpoint
  description = "Static website endpoint (origin)."
}

output "postgres_private_host" {
  value = azurerm_postgresql_flexible_server.db.fqdn
  description = "Private hostname of PostgreSQL."
}