# ==============================================================================
# Outputs from Landing Zone Vending Module
# ==============================================================================

output "subscription_ids" {
  description = "Map of landing zone keys to their subscription IDs"
  value       = module.landing_zones.subscription_ids
}

output "subscription_resource_ids" {
  description = "Map of landing zone keys to their subscription resource IDs"
  value       = module.landing_zones.subscription_resource_ids
}

output "landing_zone_names" {
  description = "Map of landing zone keys to their auto-generated subscription names"
  value       = module.landing_zones.landing_zone_names
}

output "virtual_network_resource_ids" {
  description = "Map of landing zone keys to their virtual network resource IDs"
  value       = module.landing_zones.virtual_network_resource_ids
}

output "virtual_network_address_spaces" {
  description = "Map of landing zone keys to their virtual network address spaces"
  value       = module.landing_zones.virtual_network_address_spaces
}

output "resource_group_resource_ids" {
  description = "Map of landing zone keys to their resource group resource IDs"
  value       = module.landing_zones.resource_group_resource_ids
}

output "umi_client_ids" {
  description = "Map of landing zone keys to their UMI client IDs (for OIDC authentication)"
  value       = module.landing_zones.umi_client_ids
  sensitive   = true
}

output "umi_principal_ids" {
  description = "Map of landing zone keys to their UMI principal IDs (for role assignments)"
  value       = module.landing_zones.umi_principal_ids
}

output "umi_resource_ids" {
  description = "Map of landing zone keys to their UMI resource IDs"
  value       = module.landing_zones.umi_resource_ids
}

output "budget_resource_ids" {
  description = "Map of landing zone keys to their budget resource IDs"
  value       = module.landing_zones.budget_resource_ids
}

output "calculated_address_prefixes" {
  description = "The automatically calculated address prefixes for virtual networks"
  value       = module.landing_zones.calculated_address_prefixes
}