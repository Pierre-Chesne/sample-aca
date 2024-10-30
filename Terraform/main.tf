resource "azurerm_resource_group" "rg_0" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "law_0" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg_0.location
  resource_group_name = azurerm_resource_group.rg_0.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env_0" {
    name = var.container_app_environment_name
    resource_group_name = azurerm_resource_group.rg_0.name
    location = azurerm_resource_group.rg_0.location
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law_0.id
}

resource "azurerm_container_app" "app_0" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.env_0.id
  resource_group_name          = azurerm_resource_group.rg_0.name
  revision_mode                = "Single"

  template {
    container {
      name   = var.container_app_name
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled = true
    target_port = 80
    traffic_weight {
      percentage = 100
    }
  }
}