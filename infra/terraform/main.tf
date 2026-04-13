terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azapi" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ---------- Locals ----------

locals {
  normalized_env = lower(replace(var.environment_name, "_", "-"))
  token          = substr(md5("${azurerm_resource_group.rg.id}-${var.environment_name}-${var.location}"), 0, 6)
  sql_token      = substr(md5("${azurerm_resource_group.rg.id}-${var.environment_name}-${var.sql_location}"), 0, 6)
  name_base      = lower(replace(local.normalized_env, "-", ""))

  log_analytics_name              = "law-${substr(local.normalized_env, 0, min(20, length(local.normalized_env)))}-${local.token}"
  app_insights_name               = "appi-${substr(local.normalized_env, 0, min(28, length(local.normalized_env)))}-${local.token}"
  container_apps_environment_name = "acae-${substr(local.normalized_env, 0, min(20, length(local.normalized_env)))}-${local.token}"
  backend_container_app_name      = "aca-backend-${substr(local.normalized_env, 0, min(12, length(local.normalized_env)))}-${local.token}"
  container_registry_name         = "acr${substr(local.name_base, 0, min(20, length(local.name_base)))}${local.token}"
  acr_identity_name               = "id-acr-${substr(local.normalized_env, 0, min(20, length(local.normalized_env)))}-${local.token}"
  sql_mi_name                     = "id-sql-${substr(local.normalized_env, 0, min(20, length(local.normalized_env)))}-${local.token}"
  sql_server_name                 = "sqlw-${substr(local.normalized_env, 0, min(19, length(local.normalized_env)))}-${local.token}"
  sql_database_name               = "at-db"
  key_vault_name                  = "kv${substr(local.name_base, 0, min(16, length(local.name_base)))}${local.token}"

  has_powerbi = var.powerbi_client_id != "" && var.powerbi_client_secret != ""

  powerbi_tenant_id = var.powerbi_tenant_id != "" ? var.powerbi_tenant_id : data.azurerm_client_config.current.tenant_id

  tags = {
    "azd-env-name" = var.environment_name
    project        = "astraterra-at"
  }
}

# ---------- Log Analytics ----------

resource "azurerm_log_analytics_workspace" "law" {
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# ---------- Application Insights ----------

resource "azurerm_application_insights" "appi" {
  name                = local.app_insights_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = local.tags
}

# ---------- Container Registry ----------

resource "azurerm_container_registry" "acr" {
  name                   = local.container_registry_name
  location               = var.location
  resource_group_name    = azurerm_resource_group.rg.name
  sku                    = "Basic"
  admin_enabled          = false
  public_network_access_enabled = true
  tags                   = local.tags
}

# ---------- Key Vault ----------

resource "azurerm_key_vault" "kv" {
  name                       = local.key_vault_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  public_network_access_enabled = true
  tags                       = local.tags
}

# ---------- Azure SQL (serverless, AAD-only, MI auth) ----------

resource "azurerm_user_assigned_identity" "sql_mi" {
  name                = local.sql_mi_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_mssql_server" "sql" {
  name                          = local.sql_server_name
  location                      = var.sql_location
  resource_group_name           = azurerm_resource_group.rg.name
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  tags                          = local.tags

  azuread_administrator {
    login_username              = var.sql_admin_display_name
    object_id                   = var.sql_admin_object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_mssql_database" "db" {
  name         = local.sql_database_name
  server_id    = azurerm_mssql_server.sql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  sku_name     = "GP_S_Gen5_1"
  auto_pause_delay_in_minutes = 60
  min_capacity = 0.5
  tags         = local.tags
}

# ---------- ACR Pull Identity ----------

resource "azurerm_user_assigned_identity" "acr_identity" {
  name                = local.acr_identity_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_identity.principal_id
  principal_type       = "ServicePrincipal"
}

# ---------- Container Apps Environment ----------

resource "azurerm_container_app_environment" "env" {
  name                       = local.container_apps_environment_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                       = local.tags
}

# ---------- Power BI secret in Key Vault ----------

resource "azurerm_key_vault_secret" "powerbi_client_secret" {
  count        = local.has_powerbi ? 1 : 0
  name         = "PowerBIClientSecret"
  value        = var.powerbi_client_secret
  key_vault_id = azurerm_key_vault.kv.id
}

# ---------- Backend Container App ----------

locals {
  sql_connection_string = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=${local.sql_database_name};Authentication=Active Directory Default;User Id=${azurerm_user_assigned_identity.sql_mi.client_id};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

  base_env_vars = [
    { name = "ASPNETCORE_URLS", value = "http://+:5000" },
    { name = "APPLICATIONINSIGHTS_CONNECTION_STRING", value = azurerm_application_insights.appi.connection_string },
    { name = "KEY_VAULT_URI", value = azurerm_key_vault.kv.vault_uri },
    { name = "ConnectionStrings__AstraTerraDb", value = local.sql_connection_string },
  ]

  powerbi_env_vars = local.has_powerbi ? [
    { name = "PowerBI__TenantId", value = local.powerbi_tenant_id },
    { name = "PowerBI__ClientId", value = var.powerbi_client_id },
    { name = "PowerBI__WorkspaceId", value = var.powerbi_workspace_id },
    { name = "PowerBI__ReportId", value = var.powerbi_report_id },
  ] : []
}

resource "azurerm_container_app" "backend" {
  name                         = local.backend_container_app_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  tags = merge(local.tags, {
    appRole          = "backend"
    "azd-service-name" = "backend"
  })

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.acr_identity.id,
      azurerm_user_assigned_identity.sql_mi.id,
    ]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.acr_identity.id
  }

  dynamic "secret" {
    for_each = local.has_powerbi ? [1] : []
    content {
      name                = "powerbi-client-secret"
      key_vault_secret_id = "${azurerm_key_vault.kv.vault_uri}secrets/PowerBIClientSecret"
      identity            = "System"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "backend"
      image  = var.backend_image_name
      cpu    = 0.5
      memory = "1Gi"

      dynamic "env" {
        for_each = concat(local.base_env_vars, local.powerbi_env_vars)
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = local.has_powerbi ? [1] : []
        content {
          name       = "PowerBI__ClientSecret"
          secret_name = "powerbi-client-secret"
        }
      }

      liveness_probe {
        path             = "/health"
        port             = 8080
        transport        = "HTTP"
        initial_delay    = 30
        interval_seconds = 30
        timeout          = 10
        failure_count_threshold = 5
      }

      readiness_probe {
        path             = "/health"
        port             = 8080
        transport        = "HTTP"
        initial_delay    = 15
        interval_seconds = 15
        timeout          = 10
        failure_count_threshold = 5
      }
    }
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}

# ---------- RBAC: Key Vault Secrets User for backend ----------

resource "azurerm_role_assignment" "backend_kv_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app.backend.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
