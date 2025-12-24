######################################################################################
# Weather App Infrastructure - Root Configuration
# Purpose: Orchestrates all infrastructure modules
# Architecture: Modular, reusable, maintainable
######################################################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }

  ######################################################################################
  # Remote Backend Configuration
  # Purpose: Store Terraform state in Azure Storage Account
  # Benefits: 
  #   - State locking prevents concurrent modifications
  #   - Centralized state for team collaboration
  #   - State versioning and backup
  # Note: Configure backend.tfvars with your storage account details
  ######################################################################################
  backend "azurerm" {
    # These values should be provided via backend.tfvars or environment variables
    # resource_group_name  = "terraform-state-rg"
    # storage_account_name = "tfstateXXXXX"
    # container_name       = "tfstate"
    # key                  = "weather-app.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

#### Data Sources ####
data "azurerm_client_config" "current" {}

#### Random Suffix for Unique Names ####
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

######################################################################################
# Resource Group
# Purpose: Central container for all weather application resources
# Best Practice: Single RG per application for easier management and RBAC
# Note: Using existing RG created via CLI to avoid recreation
######################################################################################

data "azurerm_resource_group" "rg" {
  name = "weather-app-main-rg"
}

######################################################################################
# Module 1: Monitoring (Log Analytics + Application Insights)
######################################################################################

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  log_analytics_name  = "weather-logs"
  app_insights_name   = "weather-app-insights"
  retention_days      = 30

  tags = var.tags

  depends_on = [data.azurerm_resource_group.rg]
}

######################################################################################
# Module 2: Database (PostgreSQL Flexible Server)
######################################################################################

module "database" {
  source = "./modules/database"

  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  server_name           = "weather-postgres-${random_integer.suffix.result}"
  database_name         = "weatherdb"
  admin_username        = var.db_admin_username
  admin_password        = var.db_admin_password
  sku_name              = "B_Standard_B1ms"
  storage_mb            = 32768
  postgres_version      = "15"
  backup_retention_days = 7

  tags = var.tags

  depends_on = [data.azurerm_resource_group.rg]
}

######################################################################################
# Module 3: Security (Key Vault + Secrets)
######################################################################################

module "security" {
  source = "./modules/security"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  key_vault_name      = "weather-kv-${random_integer.suffix.result}"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  deployer_object_id  = data.azurerm_client_config.current.object_id
  db_host             = module.database.server_fqdn
  db_username         = var.db_admin_username
  db_password         = var.db_admin_password
  openweather_api_key = var.openweather_api_key

  tags = var.tags

  depends_on = [data.azurerm_resource_group.rg, module.database]
}

######################################################################################
# Module 4: Storage (Static Website + Function Storage)
######################################################################################

module "storage" {
  source = "./modules/storage"

  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  static_storage_account_name   = "weatherstatic${random_integer.suffix.result}"
  function_storage_account_name = "weatherfunc${random_integer.suffix.result}"

  app_source_path = "${path.module}/../weather-app/static"

  tags = var.tags

  depends_on = [data.azurerm_resource_group.rg]
}

######################################################################################
# Module 5: CDN (Azure Front Door)
######################################################################################

module "cdn" {
  source = "./modules/cdn"

  resource_group_name     = data.azurerm_resource_group.rg.name
  profile_name            = "weather-frontdoor-profile"
  endpoint_name           = "weather-fd-endpoint"
  static_storage_endpoint = module.storage.static_website_endpoint
  apim_gateway_url        = module.api_gateway.apim_gateway_url

  tags = var.tags

  depends_on = [data.azurerm_resource_group.rg, module.storage, module.api_gateway]
}

######################################################################################
# Module 6: Compute (Azure Functions)
######################################################################################

#### Package Function Code ####
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../weather-app/app"
  output_path = "${path.module}/function-package.zip"
}

module "compute" {
  source = "./modules/compute"

  resource_group_name            = data.azurerm_resource_group.rg.name
  location                       = data.azurerm_resource_group.rg.location
  function_app_name              = "weather-api-func-${random_integer.suffix.result}"
  service_plan_name              = "weather-func-plan"
  storage_account_name           = module.storage.function_storage_account_name
  storage_account_access_key     = module.storage.function_storage_primary_key
  function_package_path          = data.archive_file.function_zip.output_path
  db_host                        = module.security.db_host_secret_value
  db_user                        = module.security.db_username_secret_value
  db_password                    = module.security.db_password_secret_value
  db_name                        = module.database.database_name
  openweather_api_key            = module.security.openweather_api_key_secret_value
  app_insights_connection_string = module.monitoring.app_insights_connection_string

  tags = var.tags

  depends_on = [
    data.azurerm_resource_group.rg,
    module.storage,
    module.security,
    module.database,
    module.monitoring
  ]
}

######################################################################################
# Module 7: API Gateway (API Management)
# Note: Created after compute to get function hostname
######################################################################################

module "api_gateway" {
  source = "./modules/api-gateway"

  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  apim_name                  = "weather-apimm-${random_integer.suffix.result}"
  publisher_name             = "WeatherCorp"
  publisher_email            = "admin@weathercorp.com"
  sku_name                   = "Consumption_0" # Changed from Standard to Consumption!
  function_app_hostname      = module.compute.function_app_default_hostname
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = var.tags

  depends_on = [data.azurerm_resource_group.rg, module.compute, module.monitoring]
}
