terraform {
  required_version = ">= 1.9"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9, < 1.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
