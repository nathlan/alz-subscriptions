# ==============================================================================
# Azure Landing Zone Subscription Vending
# ==============================================================================
# This root module calls the private LZ vending module to provision Corp
# landing zones with subscription, networking, identity, and budgets.
#
# Each landing zone is defined in a separate .tfvars file in landing-zones/
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
# Landing Zone Vending Module (for_each over landing_zones)
# ==============================================================================
# Provisions complete Azure Landing Zones including:
# - Subscription creation and management group association
# - Virtual network with hub peering
# - User-managed identity with OIDC federated credentials
# - Role assignments for workload identity
# - Budget with notification thresholds
#
# Each landing zone is defined in the landing_zones variable as a map entry.
# ==============================================================================

module "landing_zone" {
  source   = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.1.0"
  for_each = var.landing_zones

  # Subscription Configuration
  subscription_alias_enabled                        = each.value.subscription_alias_enabled
  subscription_billing_scope                        = var.common_subscription_billing_scope
  subscription_display_name                         = each.value.subscription_display_name
  subscription_alias_name                           = each.value.subscription_alias_name
  subscription_workload                             = each.value.subscription_workload
  subscription_management_group_id                  = var.common_subscription_management_group_id
  subscription_management_group_association_enabled = each.value.subscription_management_group_association_enabled
  subscription_tags                                 = merge(var.common_tags, each.value.subscription_tags)

  # Resource Groups
  resource_group_creation_enabled = each.value.resource_group_creation_enabled
  resource_groups                 = each.value.resource_groups

  # Role Assignments
  role_assignment_enabled = each.value.role_assignment_enabled
  role_assignments        = each.value.role_assignments

  # Virtual Network (with common hub network resource ID fallback)
  virtual_network_enabled = each.value.virtual_network_enabled
  virtual_networks = {
    for vnet_key, vnet in each.value.virtual_networks : vnet_key => merge(
      vnet,
      {
        # Use LZ-specific hub if provided, otherwise fall back to common hub
        hub_network_resource_id = vnet.hub_network_resource_id != "" ? vnet.hub_network_resource_id : var.common_hub_network_resource_id
      }
    )
  }

  # User-Managed Identities (UMI) with common GitHub org fallback
  umi_enabled = each.value.umi_enabled
  user_managed_identities = {
    for umi_key, umi in each.value.user_managed_identities : umi_key => merge(
      umi,
      {
        federated_credentials_github = {
          for fed_key, fed in umi.federated_credentials_github : fed_key => merge(
            fed,
            {
              # Use LZ-specific GitHub org if provided, otherwise fall back to common org
              organization = fed.organization != "" ? fed.organization : var.common_github_organization
            }
          )
        }
      }
    )
  }

  # Budgets
  budget_enabled = each.value.budget_enabled
  budgets        = each.value.budgets
}