# ==============================================================================
# Outputs from Landing Zone Vending Module
# ==============================================================================

output "subscription_id" {
  description = "The subscription ID of the vended landing zone"
  value       = module.landing_zone.subscription_id
}

output "subscription_resource_id" {
  description = "The full Azure resource ID of the subscription"
  value       = module.landing_zone.subscription_resource_id
}

output "virtual_network_resource_ids" {
  description = "Resource IDs of created virtual networks"
  value       = module.landing_zone.virtual_network_resource_ids
}

output "resource_group_resource_ids" {
  description = "Resource IDs of created resource groups"
  value       = module.landing_zone.resource_group_resource_ids
}

output "umi_client_ids" {
  description = "Client IDs of user-managed identities (for OIDC authentication)"
  value       = module.landing_zone.umi_client_ids
  sensitive   = true
}

output "umi_principal_ids" {
  description = "Principal IDs of user-managed identities (for role assignments)"
  value       = module.landing_zone.umi_principal_ids
}

output "budget_resource_ids" {
  description = "Resource IDs of created budgets"
  value       = module.landing_zone.budget_resource_ids
}