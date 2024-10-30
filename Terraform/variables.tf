variable "resource_group_name" {
    description = "The name of the resource group in which to create the resources."
    type        = string
    default     = "rg-aca"  
}

variable "location" {
    description = "The location in which to create the resources."
    type        = string
    default     = "West Europe"
}

variable "log_analytics_workspace_name" {
    description = "The name of the Log Analytics Workspace."
    type        = string
    default     = "law-aca"
}

variable "container_app_environment_name" {
    description = "The name of the Container App Environment."
    type        = string
    default     = "env-aca"
}

variable "container_app_name" {
    description = "The name of the Container App."
    type        = string
    default     = "app-aca"
}