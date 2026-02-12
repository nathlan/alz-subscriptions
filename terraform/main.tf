# ==============================================================================
# Azure Landing Zone Subscription Vending
# ==============================================================================

# ==============================================================================
# Landing Zone Vending Module
# ==============================================================================
# Provisions complete Azure Landing Zones including:
# - Subscription creation and management group association
# - Virtual network with hub peering and subnets
# - User-managed identity with OIDC federated credentials
# - Role assignments for workload identity
# - Budget with notification thresholds
# - Auto-generated resource names following Azure naming conventions
# ==============================================================================

module "landing_zones" {
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6"

  # Common configuration shared across all landing zones
  subscription_billing_scope       = var.subscription_billing_scope
  subscription_management_group_id = var.subscription_management_group_id
  hub_network_resource_id          = var.hub_network_resource_id
  github_organization              = var.github_organization
  azure_address_space              = var.azure_address_space
  tags                             = var.tags

  # Map of landing zones to deploy
  landing_zones = var.landing_zones
}
