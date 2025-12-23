terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
  }
}
provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}


####Resource group####
resource "azurerm_resource_group" "rg" {
  name     = "weather-app-rg"
  location = "northeurope"
}


#####PostgreSQL server####
resource "azurerm_postgresql_flexible_server" "db" {
    name                   = "weather-postgres-${random_integer.suffix.result}"
    
    resource_group_name    = azurerm_resource_group.rg.name
    location               = azurerm_resource_group.rg.location
    version                = "15"
    administrator_login    = var.db_admin_username
    administrator_password = var.db_admin_password
    sku_name               = "B_Standard_B1ms"
    storage_mb             = 32768
    zone = "1"
    auto_grow_enabled      = true

    backup_retention_days  = 7    
    }

#####PostgreSQL database####
resource "azurerm_postgresql_flexible_server_database" "appdb" {
  name      = "weatherdb"
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

####Firewall rule to allow only Azure services####
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name      = "AllowAzureServices"
  server_id = azurerm_postgresql_flexible_server.db.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}


####Private DNS Zone for PostgreSQL####

#####Key vault#####
resource "azurerm_key_vault" "kv" {
  name                        = "weather-kv-${random_integer.suffix.result}"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false  
}
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "Set",
    "Delete",
    "List",
    "Purge"
  ]
}

#####Key vault secret for DB password####
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-admin-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [azurerm_key_vault_access_policy.terraform]

}
resource "azurerm_key_vault_secret" "openweather_api_key" {
  name         = "openweather-api-key"
  value        = var.openweather_api_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [azurerm_key_vault_access_policy.terraform]

}
resource "azurerm_key_vault_secret" "db_host" {
  name         = "pg-host"
  value        = azurerm_postgresql_flexible_server.db.fqdn
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [azurerm_key_vault_access_policy.terraform]

}
resource "azurerm_key_vault_secret" "db_username" {
  name         = "pg-username"
  value        = var.db_admin_username
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [azurerm_key_vault_access_policy.terraform]

  
}
#####Storage account for static webiste####
resource "azurerm_storage_account" "static" {
  name                     = "weatherstatic${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
}

#### CDN profile####
resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = "weather-frontdoor-profile"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

#### CDN endpoint####
resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = "weather-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
}

resource "azurerm_cdn_frontdoor_origin_group" "static_group" {
  name                     = "static-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  health_probe {
    protocol = "Https"
    path     = "/"
    request_type        = "GET"
    interval_in_seconds = 120
  }
    load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "static_origin" {
  name                          = "static-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_group.id
  certificate_name_check_enabled = "true"
  host_name = replace(
    replace(azurerm_storage_account.static.primary_web_endpoint, "https://", ""),
    "/",
    ""
  )

  origin_host_header = replace(
    replace(azurerm_storage_account.static.primary_web_endpoint, "https://", ""),
    "/",
    ""
  )

  http_port  = 80
  https_port = 443
  enabled = true
}

resource "azurerm_cdn_frontdoor_origin_group" "apim_group" {
  name                     = "apim-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  health_probe {
    protocol = "Https"
    path     = "/"
    request_type        = "GET"
    interval_in_seconds = 120
  }
    load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "apim_origin" {
  name                          = "apim-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.apim_group.id
certificate_name_check_enabled = "true"
  host_name          = replace(azurerm_api_management.apimm.gateway_url, "https://", "")
  origin_host_header = replace(azurerm_api_management.apimm.gateway_url, "https://", "")

  http_port  = 80
  https_port = 443
  enabled = true
}

resource "azurerm_cdn_frontdoor_route" "api_route" {
  name                          = "api-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.apim_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.apim_origin.id]

  patterns_to_match     = ["/weather", "/weather/*"]
  supported_protocols   = ["Http", "Https"]
  forwarding_protocol   = "HttpsOnly"
  link_to_default_domain = true
  enabled                = true
  
  depends_on = [
    azurerm_cdn_frontdoor_origin.apim_origin
  ]
}

resource "azurerm_cdn_frontdoor_route" "static_route" {
  name                          = "static-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_origin.id]

  patterns_to_match     = ["/", "/*"]
  supported_protocols   = ["Http", "Https"]
  forwarding_protocol   = "HttpsOnly"
  link_to_default_domain = true
  enabled                = true
  
  depends_on = [
    azurerm_cdn_frontdoor_origin.static_origin,
    azurerm_cdn_frontdoor_route.api_route
  ]
}

#####Serverless consumption plan####



#####Storage account for Function App####
resource "azurerm_storage_account" "func_storage" {
  name                     = "weatherfunc${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

####Function App service plan####
resource "azurerm_service_plan" "func_plan" {
  name                = "weather-func-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

####Function app####


resource "azurerm_linux_function_app" "weather_api" {
  name                       = "weather-api-func-${random_integer.suffix.result}"
  service_plan_id            = azurerm_service_plan.func_plan.id

  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key
  zip_deploy_file = data.archive_file.function_zip.output_path



  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"

    DB_HOST            = azurerm_key_vault_secret.db_host.value
    DB_USER            = azurerm_key_vault_secret.db_username.value
    DB_PASSWORD        = azurerm_key_vault_secret.db_password.value
    DB_NAME            = azurerm_postgresql_flexible_server_database.appdb.name
    DB_PORT            = "5432"

    OPENWEATHER_API_KEY      = azurerm_key_vault_secret.openweather_api_key.value
  }
  site_config {
  dynamic "ip_restriction" {
    for_each = toset(azurerm_api_management.apimm.public_ip_addresses)
    content {
      name       = "Allow-APIM-${replace(ip_restriction.value, ".", "-")}"
      priority   = 100 + index(azurerm_api_management.apimm.public_ip_addresses, ip_restriction.value)
      action     = "Allow"
      ip_address = "${ip_restriction.value}/32"
    }
  }

  ip_restriction {
    name       = "Deny-All"
    priority   = 200
    action     = "Deny"
    ip_address = "0.0.0.0/0"
  }
    scm_use_main_ip_restriction = false

    application_stack {
    python_version = "3.10"
  }
  
}

}

#####API managment instance####
resource "azurerm_api_management" "apimm" {
  name                = "weather-apimm-${random_integer.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  publisher_name  = "WeatherCorp"
  publisher_email = "admin@weathercorp.com"

  sku_name = "Standard_1"

}
#####API management API####
resource "azurerm_api_management_api" "weather_api" {
  name                = "weather-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apimm.name

  revision   = "1"
  display_name = "Weather API"
  protocols    = ["https"]

  path = "weather"
    service_url = "https://${azurerm_linux_function_app.weather_api.default_hostname}"

  subscription_required = false

} 


resource "azurerm_api_management_api_operation" "get_weather" {
  operation_id        = "get-weather"
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = azurerm_resource_group.rg.name

  display_name = "Get Weather"
  method       = "GET"
  url_template = "/"
}

resource "azurerm_api_management_api_operation_policy" "get_weather_policy" {
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = azurerm_resource_group.rg.name
  operation_id        = azurerm_api_management_api_operation.get_weather.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>https://${azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name}</origin>
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
    <rewrite-uri template="/weather" />
    <set-backend-service base-url="https://${azurerm_linux_function_app.weather_api.default_hostname}/api"/>
  </inbound>
  <backend>
    <base />
  </backend>
</policies>
XML
depends_on = [
    azurerm_linux_function_app.weather_api
  ]
}


resource "azurerm_api_management_api_operation" "save_weather" {
  operation_id        = "save-weather"
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = azurerm_resource_group.rg.name

  display_name = "Save Weather"
  method       = "POST"
  url_template = "/save"
}

resource "azurerm_api_management_api_operation_policy" "save_weather_policy" {
  api_name            = azurerm_api_management_api.weather_api.name
  api_management_name = azurerm_api_management.apimm.name
  resource_group_name = azurerm_resource_group.rg.name
  operation_id        = azurerm_api_management_api_operation.save_weather.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>https://${azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name}</origin>
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
    <rewrite-uri template="/save" />
    <set-backend-service base-url="https://${azurerm_linux_function_app.weather_api.default_hostname}/api"/>
  </inbound>
</policies>
XML
depends_on = [
    azurerm_linux_function_app.weather_api
  ]
}

####Uploading static content to storage account####
resource "azurerm_storage_blob" "script" {
  name                   = "app.js"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"

  source_content = replace(
  file("${path.module}/../weather-app/static/js/script.js"),
  "___API_URL___",
  "https://${azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name}"
)
content_type           = "application/javascript"  
}
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/../weather-app/static/index.html"
  content_type = "text/html"
}
resource "azurerm_storage_blob" "e404" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/../weather-app/static/404.html"
    content_type = "text/html"
}
resource "azurerm_storage_blob" "style" {
  name                   = "styles.css"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/../weather-app/static/style.css"
    content_type = "text/css"

}


####uploading python code to the Function App####
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../weather-app/app"
  output_path = "${path.module}/function-package.zip"
}



resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}


resource "azurerm_monitor_diagnostic_setting" "apim_logs" {
  name               = "apim-diagnostics"
  target_resource_id = azurerm_api_management.apimm.id
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "GatewayLogs"
  }
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "weather-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}