######################################################################################
# Storage Module Variables
# Purpose: Static website hosting and Function App storage
######################################################################################

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "static_storage_account_name" {
  description = "Name for static website storage account"
  type        = string
}

variable "function_storage_account_name" {
  description = "Name for Function App storage account"
  type        = string
}

variable "api_url" {
  description = "API base URL to inject into JavaScript (placeholder if not provided)"
  type        = string
  default     = "https://placeholder.azurefd.net"
}

variable "app_source_path" {
  description = "Path to weather-app static files"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
