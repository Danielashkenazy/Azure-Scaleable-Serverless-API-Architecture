######################################################################################
# Database Module Outputs
######################################################################################

output "server_id" {
  description = "ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.db.id
}

output "server_fqdn" {
  description = "Fully qualified domain name of the database server"
  value       = azurerm_postgresql_flexible_server.db.fqdn
}

output "database_name" {
  description = "Name of the application database"
  value       = azurerm_postgresql_flexible_server_database.appdb.name
}

output "admin_username" {
  description = "Database admin username"
  value       = var.admin_username
  sensitive   = true
}
