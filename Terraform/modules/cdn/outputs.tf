######################################################################################
# CDN Module Outputs
######################################################################################

output "front_door_profile_id" {
  description = "ID of Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.fd_profile.id
}

output "front_door_endpoint_id" {
  description = "ID of Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
}

output "front_door_endpoint_hostname" {
  description = "Hostname of Front Door endpoint (public URL)"
  value       = azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name
}
