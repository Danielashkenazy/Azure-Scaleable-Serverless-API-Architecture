######################################################################################
# Compute Module Outputs
######################################################################################

output "function_app_id" {
  description = "ID of the Function App"
  value       = azurerm_linux_function_app.weather_api.id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.weather_api.name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.weather_api.default_hostname
}

output "service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.func_plan.id
}
