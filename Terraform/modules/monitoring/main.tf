######################################################################################
# Log Analytics Workspace
# Purpose: Central repository for all logs and metrics
# Cost: ~$2.30/GB ingested after 5GB free tier
######################################################################################

resource "azurerm_log_analytics_workspace" "logs" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days

  tags = var.tags
}

######################################################################################
# Application Insights
# Purpose: APM for Function App - tracks requests, failures, dependencies
# Key Features: 
#   - Request/response tracking
#   - Dependency tracking (DB, external APIs)
#   - Exception logging
#   - Performance metrics
######################################################################################

resource "azurerm_application_insights" "app_insights" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"

  tags = var.tags
}
