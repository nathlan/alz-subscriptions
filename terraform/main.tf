# ==============================================================================
# Azure Landing Zone Subscription Vending
# ==============================================================================
# This root module calls the private LZ vending module to provision Corp
# landing zones with subscription, networking, identity, and budgets.
# ==============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

# ==============================================================================
# Landing Zone Vending Module
# ==============================================================================
# Provisions a complete Azure Landing Zone including:
# - Subscription creation and management group association
# - Virtual network with hub peering
# - User-managed identity with OIDC federated credentials
# - Role assignments for workload identity
# - Budget with notification thresholds
# ==============================================================================

module "landing_zone" {
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.1.0"

  # Subscription Configuration
  subscription_alias_enabled                        = var.subscription_alias_enabled
  subscription_billing_scope                        = var.subscription_billing_scope
  subscription_display_name                         = var.subscription_display_name
  subscription_alias_name                           = var.subscription_alias_name
  subscription_workload                             = var.subscription_workload
  subscription_management_group_id                  = var.subscription_management_group_id
  subscription_management_group_association_enabled = var.subscription_management_group_association_enabled
  subscription_tags                                 = var.subscription_tags

  # Resource Groups
  resource_group_creation_enabled = var.resource_group_creation_enabled
  resource_groups                 = var.resource_groups

  # Role Assignments
  role_assignment_enabled = var.role_assignment_enabled
  role_assignments        = var.role_assignments

  # Virtual Network
  virtual_network_enabled = var.virtual_network_enabled
  virtual_networks        = var.virtual_networks

  # User-Managed Identities (UMI)
  umi_enabled             = var.umi_enabled
  user_managed_identities = var.user_managed_identities

  # Budgets
  budget_enabled = var.budget_enabled
  budgets        = var.budgets
}