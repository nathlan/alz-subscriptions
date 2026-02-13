terraform {
  required_version = "~> 1.10"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.5"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9, < 1.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
