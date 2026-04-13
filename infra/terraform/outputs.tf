output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "backend_container_app_fqdn" {
  value = azurerm_container_app.backend.ingress[0].fqdn
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.appi.connection_string
  sensitive = true
}

output "container_registry_name" {
  value = azurerm_container_registry.acr.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  value = azurerm_container_registry.acr.login_server
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_name" {
  value = azurerm_mssql_database.db.name
}
