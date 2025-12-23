######################################################################################
# API Gateway Module Outputs
######################################################################################

output "apim_id" {
  description = "ID of API Management"
  value       = azurerm_api_management.apimm.id
}

output "apim_name" {
  description = "Name of API Management"
  value       = azurerm_api_management.apimm.name
}

output "apim_gateway_url" {
  description = "Gateway URL of API Management"
  value       = azurerm_api_management.apimm.gateway_url
}

output "apim_public_ip_addresses" {
  description = "Public IP addresses of API Management (for Function App IP restrictions)"
  value       = azurerm_api_management.apimm.public_ip_addresses
}
