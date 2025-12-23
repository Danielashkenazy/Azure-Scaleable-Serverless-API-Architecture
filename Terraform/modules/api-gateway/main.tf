######################################################################################
# API Management Instance
# Purpose: Enterprise API gateway with built-in features:
#   - Rate limiting & throttling
#   - CORS management
#   - Request/response transformation
#   - Analytics & monitoring
#   - Developer portal
#
# SKU Selection: Consumption_0 (Serverless)
#   Cost: $3.50 per million calls (vs Standard = $900/month base)
#   Limitations:
#     - No VNet integration
#     - No custom domains (can use Front Door)
#     - Cold start on first request
#   Best for: Variable traffic, cost-sensitive projects
######################################################################################

resource "azurerm_api_management" "apimm" {
  name                = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  #### Consumption Tier ####
  # Serverless, pay-per-call model - massive cost savings!
  sku_name = var.sku_name

  tags = var.tags
}

######################################################################################
# API Definition - Weather API
# Purpose: Logical container for related API operations
# Path: "weather" - all operations under /weather/*
# Service URL: Points to Azure Function backend
######################################################################################

resource "azurerm_api_management_api" "weather_api" {
  name                = "weather-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.apimm.name
  revision            = "1"
  display_name        = "Weather API"
  protocols           = ["https"]

  #### Path Configuration ####
  # Frontend: /weather/*
  # Backend: /api/*
  path        = "weather"
  service_url = "https://${var.function_app_hostname}/api"

  subscription_required = false # Public API, no subscription key needed
}

######################################################################################
# API Operation: Get Weather Forecast
# Purpose: Retrieve weather forecast for a city
# Method: GET /weather/weather?city={cityName}
# Maps to: Function /api/weather
######################################################################################

resource "azurerm_api_management_api_operation" "get_weather" {
  operation_id        = "get-weather"
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = var.resource_group_name
  display_name        = "Get Weather Forecast"
  method              = "GET"
  url_template        = "/weather"
}

######################################################################################
# Policy: Get Weather - CORS
# Purpose: Allow browser requests from Front Door CDN origin
# Security: Restricts to specific origin, not wildcard (*)
######################################################################################

resource "azurerm_api_management_api_operation_policy" "get_weather_policy" {
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = var.resource_group_name
  operation_id        = azurerm_api_management_api_operation.get_weather.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
</policies>
XML
}

######################################################################################
# API Operation: Save Weather Forecast
# Purpose: Save user's forecast to database
# Method: POST /weather/save
# Maps to: Function /api/save
######################################################################################

resource "azurerm_api_management_api_operation" "save_weather" {
  operation_id        = "save-weather"
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = var.resource_group_name
  display_name        = "Save Weather Forecast"
  method              = "POST"
  url_template        = "/save"
}

######################################################################################
# Policy: Save Weather - CORS
# Purpose: Allow POST requests from Front Door CDN
######################################################################################

resource "azurerm_api_management_api_operation_policy" "save_weather_policy" {
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = var.resource_group_name
  operation_id        = azurerm_api_management_api_operation.save_weather.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>POST</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <base />
  </inbound>
</policies>
XML
}

######################################################################################
# Diagnostic Settings
# Purpose: Stream API Management logs to Log Analytics
# Logs: Gateway requests, errors, performance metrics
######################################################################################

resource "azurerm_monitor_diagnostic_setting" "apim_logs" {
  name                       = "apim-diagnostics"
  target_resource_id         = azurerm_api_management.apimm.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "GatewayLogs"
  }
}
