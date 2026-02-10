# ==============================================================================
# Azure Landing Zone Subscriptions - Terraform Variables
# ==============================================================================
# This file defines all landing zones to be provisioned
# ==============================================================================

# ==============================================================================
# COMMON VARIABLES (Applied to All Landing Zones)
# ==============================================================================
# These variables are shared across all landing zones to ensure consistency
# Update these values once and they will apply to all LZs automatically

# REQUIRED: Azure billing scope for subscription creation
# Get this from your Enterprise Agreement enrollment account
common_subscription_billing_scope = "PLACEHOLDER_BILLING_SCOPE"

# REQUIRED: Hub virtual network resource ID for peering
# All spoke networks will peer to this hub
common_hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID"

# Management group for all subscriptions
common_subscription_management_group_id = "Corp"

# Default Azure region for all resources
common_location = "uksouth"

# GitHub organization for OIDC federated credentials
common_github_organization = "nathlan"

# Tags applied to all subscriptions (merged with LZ-specific tags)
common_tags = {
  ManagedBy = "Terraform"
}

# ==============================================================================
# LANDING ZONES DEFINITION (Array of Objects)
# ==============================================================================
# Each entry in this map represents a landing zone to provision
# The key (e.g., "example-api-dev") is used for state file naming and identification
# ==============================================================================

landing_zones = {
  # ===========================================================================
  # Example API - DevTest
  # ===========================================================================
  example-api-dev = {
    # Subscription Configuration
    subscription_display_name                         = "example-api (DevTest)"
    subscription_alias_name                           = "sub-example-api-dev"
    subscription_workload                             = "DevTest"
    subscription_alias_enabled                        = true
    subscription_management_group_association_enabled = true

    subscription_tags = {
      Environment = "DevTest"
      Workload    = "example-api"
      CostCenter  = "IT-DEV-002"
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
        name                = "vnet-example-api-dev-uksouth"
        resource_group_key  = "rg_workload"
        address_space       = ["10.101.0.0/24"]
        location            = "uksouth"
        hub_peering_enabled = true
        # hub_network_resource_id uses common_hub_network_resource_id by default

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

    # User-Managed Identity with GitHub OIDC (optional - uncomment to use)
    # umi_enabled = true
    # user_managed_identities = {
    #   deploy = {
    #     name               = "umi-example-api-deploy"
    #     location           = "uksouth"
    #     resource_group_key = "rg_identity"
    #
    #     role_assignments = {
    #       subscription_contributor = {
    #         scope_resource_id              = "subscription"
    #         role_definition_id_or_name     = "Contributor"
    #       }
    #     }
    #
    #     federated_credentials_github = {
    #       main = {
    #         name       = "github-main"
    #         repository = "example-api-dev"
    #         entity     = "ref:refs/heads/main"
    #         # organization uses common_github_organization by default
    #       }
    #       pr = {
    #         name       = "github-pr"
    #         repository = "example-api-dev"
    #         entity     = "pull_request"
    #       }
    #     }
    #   }
    # }

    # Monthly Budget with Notifications (optional - uncomment to use)
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
  }

  # ===========================================================================
  # Example App - Production
  # ===========================================================================
  example-app-prod = {
    # Subscription Configuration
    subscription_display_name                         = "example-app (Production)"
    subscription_alias_name                           = "sub-example-app-prod"
    subscription_workload                             = "Production"
    subscription_alias_enabled                        = true
    subscription_management_group_association_enabled = true

    subscription_tags = {
      Environment = "Production"
      Workload    = "example-app"
      CostCenter  = "IT-PROD-001"
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
        name                = "vnet-example-app-prod-uksouth"
        resource_group_key  = "rg_workload"
        address_space       = ["10.100.0.0/24"]
        location            = "uksouth"
        hub_peering_enabled = true
        # hub_network_resource_id uses common_hub_network_resource_id by default

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

    # User-Managed Identity with GitHub OIDC (optional - uncomment to use)
    # umi_enabled = true
    # user_managed_identities = {
    #   deploy = {
    #     name               = "umi-example-app-deploy"
    #     location           = "uksouth"
    #     resource_group_key = "rg_identity"
    #
    #     role_assignments = {
    #       subscription_contributor = {
    #         scope_resource_id              = "subscription"
    #         role_definition_id_or_name     = "Contributor"
    #       }
    #     }
    #
    #     federated_credentials_github = {
    #       main = {
    #         name       = "github-main"
    #         repository = "example-app"
    #         entity     = "ref:refs/heads/main"
    #         # organization uses common_github_organization by default
    #       }
    #       pr = {
    #         name       = "github-pr"
    #         repository = "example-app"
    #         entity     = "pull_request"
    #       }
    #     }
    #   }
    # }

    # Monthly Budget with Notifications (optional - uncomment to use)
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
  }
}
