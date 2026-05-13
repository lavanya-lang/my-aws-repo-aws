# Creates a single Azure Resource Group in a specified (or default) Azure region using azurerm v4.57.0, with enterprise tag defaults and input validation. Note: input region 'us-east-1' is AWS; this configuration defaults to Azure 'eastus' unless overridden via var.location.
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
  description = "Name of the Azure Resource Group. Must be 1-90 characters and can contain alphanumeric characters, underscores, hyphens, and periods."
  type        = string
  default     = "rg-enterprise-prod-useast1"

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+$", var.resource_group_name))
    error_message = "Resource group name may only contain alphanumeric characters, underscores, hyphens, and periods."
  }
}

variable "location" {
  description = "Azure region for the Resource Group (Azure uses names like eastus, westeurope). Note: the provided requirement 'us-east-1' is an AWS region; defaulting to Azure 'eastus'."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to the Resource Group."
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Standard    = "enterprise"
  }
}

provider "azurerm" {
  {{block_to_replace_cred}}
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

output "resource_group_id" {
  description = "The ID of the created Azure Resource Group."
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "The Azure region where the Resource Group was created."
  value       = azurerm_resource_group.main.location
}

output "resource_group_name" {
  description = "The name of the created Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

output "tenant_id" {
  description = "The Azure AD tenant ID associated with the currently-authenticated identity."
  value       = data.azurerm_client_config.current.tenant_id
}