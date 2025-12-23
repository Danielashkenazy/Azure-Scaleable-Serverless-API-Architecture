######################################################################################
# Monitoring Module Variables
# Purpose: Centralized logging, monitoring, and alerting
######################################################################################

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "log_analytics_name" {
  description = "Name for Log Analytics Workspace"
  type        = string
}

variable "app_insights_name" {
  description = "Name for Application Insights"
  type        = string
}

variable "retention_days" {
  description = "Days to retain logs (cost vs compliance trade-off)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
