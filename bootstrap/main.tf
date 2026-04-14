terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Azure region for the storage account"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name for the TF state storage"
  type        = string
  default     = "rg-terraform-state"
}

variable "storage_account_name" {
  description = "Storage account name (must be globally unique, 3-24 lowercase alphanumeric)"
  type        = string
}

variable "container_name" {
  description = "Blob container name for storing state files"
  type        = string
  default     = "tfstate"
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Environment = "shared"
    Purpose     = "terraform-state"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}

output "primary_access_key" {
  value     = azurerm_storage_account.tfstate.primary_access_key
  sensitive = true
}
