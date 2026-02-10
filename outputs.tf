# ==============================================================================
# Outputs from Landing Zone Vending Module
# ==============================================================================

output "landing_zones" {
  description = "Map of all landing zone outputs indexed by landing zone name"
  value = {
    for lz_key, lz in module.landing_zone : lz_key => {
      subscription_id              = lz.subscription_id
      subscription_resource_id     = lz.subscription_resource_id
      virtual_network_resource_ids = lz.virtual_network_resource_ids
      resource_group_resource_ids  = lz.resource_group_resource_ids
      umi_principal_ids            = lz.umi_principal_ids
      budget_resource_ids          = lz.budget_resource_ids
    }
  }
}

output "landing_zone_subscription_ids" {
  description = "Map of landing zone names to subscription IDs"
  value = {
    for lz_key, lz in module.landing_zone : lz_key => lz.subscription_id
  }
}

output "landing_zone_umi_client_ids" {
  description = "Map of landing zone names to UMI client IDs (for OIDC authentication)"
  value = {
    for lz_key, lz in module.landing_zone : lz_key => lz.umi_client_ids
  }
  sensitive = true
}