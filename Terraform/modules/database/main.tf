######################################################################################
# PostgreSQL Flexible Server
# Purpose: Managed database for storing user forecast data
# Tier: Burstable B1ms - cost-optimized for small workloads
# Zone: Single zone (multi-zone would increase cost 2x)
# Network: Public access restricted to Azure services only
######################################################################################

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgres_version
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  
  #### SKU Configuration ####
  # B_Standard_B1ms: 1 vCore, 2GB RAM, burstable - best cost/performance for low traffic
  sku_name               = var.sku_name
  storage_mb             = var.storage_mb
  
  #### Availability Configuration ####
  # Zone 1: Single zone deployment (multi-zone adds cost)
  # Auto-grow: Prevents storage full issues
  zone                   = "1"
  auto_grow_enabled      = true
  
  #### Backup Configuration ####
  # 7 days: Minimum for production, balances cost vs recovery needs
  backup_retention_days  = var.backup_retention_days

  tags = var.tags
}

######################################################################################
# Database Creation
# Purpose: Application-specific database within the server
# Collation: en_US.utf8 for English language support
######################################################################################

resource "azurerm_postgresql_flexible_server_database" "appdb" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

######################################################################################
# Firewall Rule - Azure Services Only
# Purpose: Allow connections only from Azure services (Function App)
# Security: Blocks all external access, only internal Azure resources
# 0.0.0.0 = Special Azure keyword for "Azure Services"
######################################################################################

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name      = "AllowAzureServices"
  server_id = azurerm_postgresql_flexible_server.db.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
