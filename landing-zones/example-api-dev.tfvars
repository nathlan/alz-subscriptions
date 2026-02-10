# ==============================================================================
# Example DevTest API Landing Zone
# ==============================================================================
# This is a reference example for a dev/test workload
# ==============================================================================

# REQUIRED: State file name (must match workload name)
tfvars_file_name = "example-api-dev"

# REQUIRED: Subscription Configuration
subscription_alias_enabled    = true
subscription_billing_scope    = "PLACEHOLDER_BILLING_SCOPE" # Update with actual billing scope
subscription_display_name     = "example-api (DevTest)"
subscription_alias_name       = "sub-example-api-dev"
subscription_workload         = "DevTest"
subscription_management_group_id = "Corp"
subscription_management_group_association_enabled = true

subscription_tags = {
  Environment = "DevTest"
  Workload    = "example-api"
  CostCenter  = "IT-DEV-002"
  ManagedBy   = "Terraform"
  Owner       = "platform-engineering"
  CreatedDate = "2026-02-10"
}

# Resource Groups
resource_group_creation_enabled = true
resource_groups = {
  rg_workload = {
    name     = "rg-example-api-dev"
    location = "uksouth"
  }
  rg_identity = {
    name     = "rg-example-api-identity"
    location = "uksouth"
  }
  rg_network = {
    name     = "NetworkWatcherRG"
    location = "uksouth"
  }
}

# Virtual Network with Hub Peering
virtual_network_enabled = true
virtual_networks = {
  spoke = {
    name                    = "vnet-example-api-dev-uksouth"
    resource_group_key      = "rg_workload"
    address_space           = ["10.101.0.0/24"] # Update with allocated CIDR
    location                = "uksouth"
    hub_peering_enabled     = true
    hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID" # Update with actual hub VNet ID

    subnets = {
      default = {
        name             = "snet-default"
        address_prefixes = ["10.101.0.0/26"]
      }
      api = {
        name             = "snet-api"
        address_prefixes = ["10.101.0.64/26"]
      }
    }
  }
}

# User-Managed Identity with GitHub OIDC (example - uncomment to use)
# umi_enabled = true
# user_managed_identities = {
#   deploy = {
#     name               = "umi-example-api-deploy"
#     location           = "uksouth"
#     resource_group_key = "rg_identity"
#
#     role_assignments = {
#       subscription_contributor = {
#         scope_resource_id       = "subscription"
#         role_definition_id_or_name = "Contributor"
#       }
#     }
#
#     federated_credentials_github = {
#       main = {
#         name         = "github-main"
#         organization = "nathlan"
#         repository   = "example-api-dev"
#         entity       = "ref:refs/heads/main"
#       }
#       pr = {
#         name         = "github-pr"
#         organization = "nathlan"
#         repository   = "example-api-dev"
#         entity       = "pull_request"
#       }
#     }
#   }
# }

# Monthly Budget with Notifications (example - uncomment to use)
# budget_enabled = true
# budgets = {
#   monthly = {
#     name              = "Monthly Budget - Example API Dev"
#     amount            = 500
#     time_grain        = "Monthly"
#     time_period_start = "2026-02-01T00:00:00Z"
#     time_period_end   = "2026-12-31T23:59:59Z"
#
#     notifications = {
#       threshold_80 = {
#         enabled        = true
#         operator       = "GreaterThan"
#         threshold      = 80
#         contact_emails = ["dev-team@example.com"]
#         threshold_type = "Actual"
#       }
#     }
#   }
# }
