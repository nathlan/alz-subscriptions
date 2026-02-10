# ==============================================================================
# Input Variables for Landing Zone Vending
# ==============================================================================

# ==============================================================================
# Common Variables (Applied to All Landing Zones)
# ==============================================================================

variable "common_subscription_billing_scope" {
  type        = string
  description = "Common billing scope for all subscriptions (Enterprise Agreement enrollment account ID)"
}

variable "common_subscription_management_group_id" {
  type        = string
  description = "Common management group ID to associate all subscriptions with"
  default     = "Corp"
}

variable "common_hub_network_resource_id" {
  type        = string
  description = "Common hub virtual network resource ID for peering all spoke networks"
  default     = ""
}

variable "common_location" {
  type        = string
  description = "Common Azure region for all resources"
  default     = "uksouth"
}

variable "common_github_organization" {
  type        = string
  description = "Common GitHub organization for OIDC federated credentials"
  default     = "nathlan"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all subscriptions (will be merged with LZ-specific tags)"
  default = {
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# Landing Zones Definition (Array of Objects)
# ==============================================================================

variable "landing_zones" {
  type = map(object({
    # Subscription Configuration
    subscription_display_name                         = string
    subscription_alias_name                           = string
    subscription_workload                             = string
    subscription_alias_enabled                        = optional(bool, true)
    subscription_management_group_association_enabled = optional(bool, true)
    subscription_tags                                 = optional(map(string), {})

    # Resource Groups
    resource_group_creation_enabled = optional(bool, true)
    resource_groups = optional(map(object({
      name     = string
      location = string
    })), {})

    # Virtual Network
    virtual_network_enabled = optional(bool, true)
    virtual_networks = optional(map(object({
      name                    = string
      resource_group_key      = string
      address_space           = list(string)
      location                = string
      hub_peering_enabled     = optional(bool, true)
      hub_network_resource_id = optional(string, "")
      subnets = optional(map(object({
        name             = string
        address_prefixes = list(string)
      })), {})
    })), {})

    # User-Managed Identities
    umi_enabled = optional(bool, false)
    user_managed_identities = optional(map(object({
      name               = string
      location           = string
      resource_group_key = string
      role_assignments = optional(map(object({
        scope_resource_id          = string
        role_definition_id_or_name = string
      })), {})
      federated_credentials_github = optional(map(object({
        name         = string
        organization = optional(string, "")
        repository   = string
        entity       = string
      })), {})
    })), {})

    # Role Assignments
    role_assignment_enabled = optional(bool, false)
    role_assignments        = optional(map(any), {})

    # Budgets
    budget_enabled = optional(bool, false)
    budgets = optional(map(object({
      name              = string
      amount            = number
      time_grain        = string
      time_period_start = string
      time_period_end   = string
      notifications = optional(map(object({
        enabled        = bool
        operator       = string
        threshold      = number
        contact_emails = list(string)
        threshold_type = string
      })), {})
    })), {})
  }))

  description = "Map of landing zones to provision. Each key is the landing zone name used for state file naming."

  validation {
    condition = alltrue([
      for lz_key, lz in var.landing_zones :
      contains(["Production", "DevTest"], lz.subscription_workload)
    ])
    error_message = "All landing zone subscription_workload values must be either 'Production' or 'DevTest'."
  }
}