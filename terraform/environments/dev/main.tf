terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration will be provided via backend config file or CLI
  }
}

provider "azurerm" {
  features {}
}

module "project" {
  source = "../../project"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
