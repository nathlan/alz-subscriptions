# ==============================================================================
# Input Variables for Landing Zone Vending
# ==============================================================================

variable "tfvars_file_name" {
  type        = string
  description = "Name of the tfvars file (without extension) for state key"
}

# Subscription Configuration
variable "subscription_alias_enabled" {
  type        = bool
  description = "Enable subscription alias creation"
  default     = true
}

variable "subscription_billing_scope" {
  type        = string
  description = "Billing scope for subscription creation (Enterprise Agreement enrollment account ID)"
}

variable "subscription_display_name" {
  type        = string
  description = "Display name for the subscription"
}

variable "subscription_alias_name" {
  type        = string
  description = "Alias name for the subscription (must be unique)"
}

variable "subscription_workload" {
  type        = string
  description = "Workload type (Production or DevTest)"
  default     = "Production"

  validation {
    condition     = contains(["Production", "DevTest"], var.subscription_workload)
    error_message = "Subscription workload must be either 'Production' or 'DevTest'."
  }
}

variable "subscription_management_group_id" {
  type        = string
  description = "Management group ID to associate subscription with"
  default     = "Corp"
}

variable "subscription_management_group_association_enabled" {
  type        = bool
  description = "Enable management group association"
  default     = true
}

variable "subscription_tags" {
  type        = map(string)
  description = "Tags to apply to the subscription"
  default     = {}
}

# Resource Groups
variable "resource_group_creation_enabled" {
  type        = bool
  description = "Enable resource group creation"
  default     = true
}

variable "resource_groups" {
  type        = map(any)
  description = "Resource groups to create in the subscription"
  default     = {}
}

# Role Assignments
variable "role_assignment_enabled" {
  type        = bool
  description = "Enable role assignments"
  default     = false
}

variable "role_assignments" {
  type        = map(any)
  description = "Role assignments to create"
  default     = {}
}

# Virtual Network
variable "virtual_network_enabled" {
  type        = bool
  description = "Enable virtual network creation"
  default     = true
}

variable "virtual_networks" {
  type        = map(any)
  description = "Virtual networks to create with hub peering"
  default     = {}
}

# User-Managed Identities
variable "umi_enabled" {
  type        = bool
  description = "Enable user-managed identity creation"
  default     = false
}

variable "user_managed_identities" {
  type        = map(any)
  description = "User-managed identities with OIDC federated credentials"
  default     = {}
}

# Budgets
variable "budget_enabled" {
  type        = bool
  description = "Enable budget creation"
  default     = false
}

variable "budgets" {
  type        = map(any)
  description = "Budgets with notification thresholds"
  default     = {}
}