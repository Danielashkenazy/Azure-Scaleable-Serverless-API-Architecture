######################################################################################
# API Gateway Module Variables
# Purpose: API Management for API gateway, rate limiting, and monitoring
######################################################################################

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "apim_name" {
  description = "Name of API Management instance"
  type        = string
}

variable "publisher_name" {
  description = "API publisher organization name"
  type        = string
  default     = "WeatherCorp"
}

variable "publisher_email" {
  description = "API publisher email"
  type        = string
  default     = "admin@weathercorp.com"
}

variable "sku_name" {
  description = "API Management SKU (Consumption = serverless, pay-per-call)"
  type        = string
  default     = "Consumption_0"
}

variable "function_app_hostname" {
  description = "Function App hostname for backend"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
