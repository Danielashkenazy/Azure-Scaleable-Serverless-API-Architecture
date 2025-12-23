######################################################################################
# CDN Module Variables
# Purpose: Azure Front Door for global CDN and low latency
######################################################################################

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "profile_name" {
  description = "Name of Front Door profile"
  type        = string
  default     = "weather-frontdoor-profile"
}

variable "endpoint_name" {
  description = "Name of Front Door endpoint"
  type        = string
  default     = "weather-fd-endpoint"
}

variable "static_storage_endpoint" {
  description = "Primary web endpoint of static storage"
  type        = string
}

variable "apim_gateway_url" {
  description = "API Management gateway URL"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
