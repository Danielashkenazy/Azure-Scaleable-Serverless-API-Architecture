######################################################################################
# Root Variables
# Purpose: Input variables for the entire infrastructure
######################################################################################

variable "location" {
  description = "Azure region for all resources. North Europe chosen for cost optimization and service availability"
  type        = string
  default     = "northeurope"
}

variable "db_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  sensitive   = true
}

variable "db_admin_password" {
  description = "PostgreSQL administrator password (min 8 chars, must include uppercase, lowercase, number)"
  type        = string
  sensitive   = true
}

variable "openweather_api_key" {
  description = "API key for OpenWeatherMap service"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags to apply to all resources for organization and cost tracking"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "WeatherApp"
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}
