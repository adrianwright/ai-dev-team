variable "environment_name" {
  description = "Name of the environment. Used for resource naming and tagging."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group (must already exist)."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus2"
}

variable "backend_image_name" {
  description = "Container image for the backend ACA app."
  type        = string
  default     = "mcr.microsoft.com/dotnet/samples:aspnetapp"
}

variable "powerbi_tenant_id" {
  description = "Entra ID tenant for the Power BI service principal. Defaults to current subscription tenant."
  type        = string
  default     = ""
}

variable "powerbi_client_id" {
  description = "Client (app) ID of the service principal used for Power BI embedding."
  type        = string
  default     = ""
}

variable "powerbi_client_secret" {
  description = "Client secret of the Power BI service principal. Stored in Key Vault."
  type        = string
  sensitive   = true
  default     = ""
}

variable "powerbi_workspace_id" {
  description = "Power BI workspace (group) ID."
  type        = string
  default     = ""
}

variable "powerbi_report_id" {
  description = "Power BI report ID to embed."
  type        = string
  default     = ""
}

variable "sql_location" {
  description = "Azure region for SQL Server. eastus2 has capacity restrictions; westus2 tested OK."
  type        = string
  default     = "westus2"
}

variable "sql_admin_display_name" {
  description = "Display name of the Entra ID user to set as SQL admin."
  type        = string
}

variable "sql_admin_object_id" {
  description = "Object ID of the Entra ID user to set as SQL admin."
  type        = string
}
