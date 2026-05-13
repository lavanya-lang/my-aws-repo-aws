# Creates a single Azure Resource Group using azurerm v4.57.0 with GitOps-friendly variable defaults for naming, region, and tags. Note: the provided region 'us-east-1' is an AWS region; default is set to the Azure equivalent 'eastus'.
# Generated Terraform code for AZURE in us-east-1

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.57.0"
    }
  }
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
  default     = "rg-enterprise-prod-eastus-001"

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region for resources. Use an Azure region name (e.g., eastus, westeurope)."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to the Resource Group."
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

provider "azurerm" {
  {{block_to_replace_cred}}
  features {}
  skip_provider_registration = true
}

resource "azurerm_resource_group" "main" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

output "resource_group_id" {
  description = "The ID of the created Resource Group."
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "The name of the created Resource Group."
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The Azure region of the created Resource Group."
  value       = azurerm_resource_group.main.location
}