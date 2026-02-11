# ==============================================================================
# Example Production Application Landing Zone
# ==============================================================================
# This is a reference example for a production workload
# ==============================================================================

# REQUIRED: Subscription Configuration
subscription_alias_enabled    = true
subscription_billing_scope    = "PLACEHOLDER_BILLING_SCOPE" # Update with actual billing scope
subscription_display_name     = "example-app (Production)"
subscription_alias_name       = "sub-example-app-prod"
subscription_workload         = "Production"
subscription_management_group_id = "Corp"
subscription_management_group_association_enabled = true

subscription_tags = {
  Environment = "Production"
  Workload    = "example-app"
  CostCenter  = "IT-PROD-001"
  ManagedBy   = "Terraform"
  Owner       = "platform-engineering"
  CreatedDate = "2026-02-10"
}

# Resource Groups
resource_group_creation_enabled = true
resource_groups = {
  rg_workload = {
    name     = "rg-example-app-prod"
    location = "uksouth"
  }
  rg_identity = {
    name     = "rg-example-app-identity"
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
    name                    = "vnet-example-app-prod-uksouth"
    resource_group_key      = "rg_workload"
    address_space           = ["10.100.0.0/24"] # Update with allocated CIDR
    location                = "uksouth"
    hub_peering_enabled     = true
    hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID" # Update with actual hub VNet ID

    subnets = {
      default = {
        name             = "snet-default"
        address_prefixes = ["10.100.0.0/26"]
      }
      app = {
        name             = "snet-app"
        address_prefixes = ["10.100.0.64/26"]
      }
    }
  }
}

# User-Managed Identity with GitHub OIDC (example - uncomment to use)
# umi_enabled = true
# user_managed_identities = {
#   deploy = {
#     name               = "umi-example-app-deploy"
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
#         repository   = "example-app"
#         entity       = "ref:refs/heads/main"
#       }
#       pr = {
#         name         = "github-pr"
#         organization = "nathlan"
#         repository   = "example-app"
#         entity       = "pull_request"
#       }
#     }
#   }
# }

# Monthly Budget with Notifications (example - uncomment to use)
# budget_enabled = true
# budgets = {
#   monthly = {
#     name              = "Monthly Budget - Example App Prod"
#     amount            = 1000
#     time_grain        = "Monthly"
#     time_period_start = "2026-02-01T00:00:00Z"
#     time_period_end   = "2026-12-31T23:59:59Z"
#
#     notifications = {
#       threshold_80 = {
#         enabled        = true
#         operator       = "GreaterThan"
#         threshold      = 80
#         contact_emails = ["platform-team@example.com"]
#         threshold_type = "Actual"
#       }
#       threshold_100 = {
#         enabled        = true
#         operator       = "GreaterThan"
#         threshold      = 100
#         contact_emails = ["platform-team@example.com"]
#         threshold_type = "Actual"
#       }
#     }
#   }
# }
