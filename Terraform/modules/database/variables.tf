######################################################################################
# Database Module Variables
# Purpose: PostgreSQL Flexible Server configuration
######################################################################################

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "server_name" {
  description = "PostgreSQL server name (must be globally unique)"
  type        = string
}

variable "database_name" {
  description = "Name of the application database"
  type        = string
  default     = "weatherdb"
}

variable "admin_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU for PostgreSQL. B_Standard_B1ms = cheapest burstable tier"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage in MB. 32GB minimum for flexibility"
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "backup_retention_days" {
  description = "Backup retention period (7-35 days)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
