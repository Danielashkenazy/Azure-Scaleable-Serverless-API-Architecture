######################################################################################
# Static Website Storage Account
# Purpose: Host HTML/CSS/JS files for public-facing website
# Tier: Standard LRS - lowest cost for static content
# Feature: Built-in static website hosting (eliminates need for web servers)
######################################################################################

resource "azurerm_storage_account" "static" {
  name                     = var.static_storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Locally redundant - sufficient for static content

  #### Static Website Feature ####
  # Automatically serves index.html and handles 404 errors
  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = var.tags
}

######################################################################################
# Function App Storage Account
# Purpose: Required by Azure Functions for state management and logs
# Note: Functions require separate storage from static content
######################################################################################

resource "azurerm_storage_account" "func_storage" {
  name                     = var.function_storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

######################################################################################
# Static Website Content Upload
# Purpose: Deploy HTML/CSS/JS files to $web container
# Note: script.js has API URL dynamically injected
######################################################################################

#### JavaScript with Dynamic API URL ####
resource "azurerm_storage_blob" "script" {
  name                   = "js/script.js"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"

  # Replace ___API_URL___ placeholder with actual CDN endpoint
  source_content = replace(
    file("${var.app_source_path}/js/script.js"),
    "___API_URL___",
    var.api_url
  )
  
  content_type = "application/javascript"
}

#### HTML Files ####
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${var.app_source_path}/index.html"
  content_type           = "text/html"
}

resource "azurerm_storage_blob" "e404" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${var.app_source_path}/404.html"
  content_type           = "text/html"
}

#### CSS File ####
resource "azurerm_storage_blob" "style" {
  name                   = "styles.css"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${var.app_source_path}/style.css"
  content_type           = "text/css"
}
