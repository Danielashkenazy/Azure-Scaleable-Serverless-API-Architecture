######################################################################################
# Azure Front Door Profile
# Purpose: Global CDN with edge locations worldwide
# Tier: Standard (Premium adds WAF, Private Link - not needed for this project)
# Benefits:
#   - ~50ms latency for static content globally
#   - Automatic SSL/TLS
#   - Health probes & failover
#   - Caching at edge
######################################################################################

resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = var.profile_name
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.tags
}

######################################################################################
# Front Door Endpoint
# Purpose: Entry point for all client requests
# Gets unique hostname: {endpoint-name}.azurefd.net
######################################################################################

resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = var.endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  tags = var.tags
}

######################################################################################
# Origin Group - Static Content
# Purpose: Logical group for static website origins
# Health Probe: Ensures origin is responsive before routing traffic
######################################################################################

resource "azurerm_cdn_frontdoor_origin_group" "static_group" {
  name                     = "static-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  #### Health Probe Configuration ####
  # Checks origin health every 120 seconds
  health_probe {
    protocol            = "Https"
    path                = "/"
    request_type        = "GET"
    interval_in_seconds = 120
  }

  #### Load Balancing ####
  # Requires 3/4 successful probes before marking healthy
  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

######################################################################################
# Origin - Static Website
# Purpose: Azure Storage static website backend
# Certificate Check: Ensures secure HTTPS connection
######################################################################################

resource "azurerm_cdn_frontdoor_origin" "static_origin" {
  name                          = "static-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_group.id
  enabled                       = true
  certificate_name_check_enabled = true
  
  #### Origin Configuration ####
  # Remove https:// and trailing / from storage endpoint
  host_name = replace(
    replace(var.static_storage_endpoint, "https://", ""),
    "/",
    ""
  )

  origin_host_header = replace(
    replace(var.static_storage_endpoint, "https://", ""),
    "/",
    ""
  )

  http_port  = 80
  https_port = 443
}

######################################################################################
# Origin Group - API Management
# Purpose: Backend for API calls
######################################################################################

resource "azurerm_cdn_frontdoor_origin_group" "apim_group" {
  name                     = "apim-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  health_probe {
    protocol            = "Https"
    path                = "/"
    request_type        = "GET"
    interval_in_seconds = 120
  }

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

######################################################################################
# Origin - API Management
# Purpose: API gateway backend
######################################################################################

resource "azurerm_cdn_frontdoor_origin" "apim_origin" {
  name                          = "apim-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.apim_group.id
  enabled                       = true
  certificate_name_check_enabled = true
  
  host_name          = replace(var.apim_gateway_url, "https://", "")
  origin_host_header = replace(var.apim_gateway_url, "https://", "")

  http_port  = 80
  https_port = 443
}

######################################################################################
# Route - API Traffic
# Purpose: Route /weather/* requests to API Management
# Priority: Created first to ensure API paths don't fall through to static
######################################################################################

resource "azurerm_cdn_frontdoor_route" "api_route" {
  name                          = "api-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.apim_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.apim_origin.id]

  #### Route Matching ####
  # Matches: /weather, /weather/anything
  patterns_to_match     = ["/weather", "/weather/*"]
  supported_protocols   = ["Http", "Https"]
  forwarding_protocol   = "HttpsOnly"  # Force HTTPS
  link_to_default_domain = true
  enabled                = true
}

######################################################################################
# Route - Static Content (Catch-All)
# Purpose: Route all other requests to static website
# Priority: Created after API route to act as default
######################################################################################

resource "azurerm_cdn_frontdoor_route" "static_route" {
  name                          = "static-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_origin.id]

  #### Catch-All Pattern ####
  # Matches everything not matched by API route
  patterns_to_match     = ["/", "/*"]
  supported_protocols   = ["Http", "Https"]
  forwarding_protocol   = "HttpsOnly"
  link_to_default_domain = true
  enabled                = true
  
  #### Dependency ####
  # Ensures API route is created first
  depends_on = [
    azurerm_cdn_frontdoor_route.api_route
  ]
}
