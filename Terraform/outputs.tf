######################################################################################
# Root Outputs
# Purpose: Key information needed post-deployment
######################################################################################

output "frontend_url" {
  description = "Public URL for the weather application (Front Door CDN endpoint)"
  value       = "https://${module.cdn.front_door_endpoint_hostname}"
}

output "api_gateway_url" {
  description = "API Management gateway URL"
  value       = module.api_gateway.apim_gateway_url
}

output "database_fqdn" {
  description = "PostgreSQL server fully qualified domain name"
  value       = module.database.server_fqdn
  sensitive   = true
}

output "key_vault_name" {
  description = "Name of the Key Vault containing secrets"
  value       = module.security.key_vault_name
}

output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = module.compute.function_app_name
}

output "resource_group_name" {
  description = "Name of the resource group containing all resources"
  value       = azurerm_resource_group.rg.name
}

output "app_insights_name" {
  description = "Name of Application Insights for monitoring"
  value       = "weather-app-insights"
}

output "deployment_summary" {
  description = "Quick deployment summary"
  value = <<-EOT
    ====================================
    Weather App Deployment Complete! 🎉
    ====================================
    
    Frontend: https://${module.cdn.front_door_endpoint_hostname}
    API Gateway: ${module.api_gateway.apim_gateway_url}
    
    Monitoring:
    - Application Insights: weather-app-insights
    - Log Analytics: weather-logs
    
    Resource Group: ${module.networking.resource_group_name}
    Location: ${module.networking.resource_group_location}
    
    Note: CDN may take 5-10 minutes to propagate globally.
  EOT
}
