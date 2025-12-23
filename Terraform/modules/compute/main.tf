######################################################################################
# App Service Plan (Consumption)
# Purpose: Serverless compute plan for Azure Functions
# Y1 SKU: Pay-per-execution model
#   - First 1M executions free/month
#   - $0.20 per million executions after
#   - Automatic scaling (0 to ~200 instances)
#   - Cold start: ~1-3 seconds
######################################################################################

resource "azurerm_service_plan" "func_plan" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"  # Linux = cheaper than Windows
  sku_name            = "Y1"     # Y1 = Consumption tier

  tags = var.tags
}

######################################################################################
# Azure Function App
# Purpose: Serverless API backend (weather + save endpoints)
# Runtime: Python 3.10
# Deployment: ZIP deploy (function-package.zip)
# Security: IP restrictions allow only API Management
######################################################################################

resource "azurerm_linux_function_app" "weather_api" {
  name                       = var.function_app_name
  service_plan_id            = azurerm_service_plan.func_plan.id
  resource_group_name        = var.resource_group_name
  location                   = var.location
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  
  #### Code Deployment ####
  # ZIP deployment: All Python code packaged into single file
  zip_deploy_file = var.function_package_path

  #### Application Configuration ####
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    
    #### Database Connection ####
    DB_HOST            = var.db_host
    DB_USER            = var.db_user
    DB_PASSWORD        = var.db_password
    DB_NAME            = var.db_name
    DB_PORT            = "5432"
    
    #### External APIs ####
    OPENWEATHER_API_KEY = var.openweather_api_key
    
    #### Application Insights Integration ####
    # Automatically tracks: requests, dependencies, exceptions, custom events
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
  }

  #### Security & Network Configuration ####
  site_config {
    #### IP Restrictions - Allow API Management Only ####
    # Security Layer: Function is not publicly accessible
    # Only API Management can invoke the functions
    dynamic "ip_restriction" {
      for_each = toset(var.api_management_ips)
      content {
        name       = "Allow-APIM-${replace(ip_restriction.value, ".", "-")}"
        priority   = 100 + index(var.api_management_ips, ip_restriction.value)
        action     = "Allow"
        ip_address = "${ip_restriction.value}/32"
      }
    }

    #### Deny All Other Traffic ####
    ip_restriction {
      name       = "Deny-All"
      priority   = 200
      action     = "Deny"
      ip_address = "0.0.0.0/0"
    }
    
    #### SCM Access ####
    # Allow Kudu/deployment without main IP restrictions
    scm_use_main_ip_restriction = false

    #### Runtime Configuration ####
    application_stack {
      python_version = "3.10"
    }
  }

  tags = var.tags
}
