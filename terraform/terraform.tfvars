# ==============================================================================
# Example Production Application Landing Zone
# ==============================================================================
# This is a reference example for production workload landing zones using the
# new v1.0.4 interface with auto-generated naming and smart defaults.
# ==============================================================================

# ========================================
# Common Configuration
# ========================================

subscription_billing_scope       = "PLACEHOLDER_BILLING_SCOPE" # Update with actual billing scope
subscription_management_group_id = "Corp"
hub_network_resource_id          = "PLACEHOLDER_HUB_VNET_ID" # Update with actual hub VNet ID
github_organization              = "nathlan"
azure_address_space              = "10.100.0.0/16"

tags = {
  managed_by       = "terraform"
  environment_type = "production"
}

# ========================================
# Landing Zones Configuration
# ========================================
#
# Each landing zone is a complete Azure subscription with:
# - Auto-generated naming following Azure conventions
# - Virtual network with hub peering and subnets
# - User-managed identity with OIDC
# - Optional budgets

landing_zones = {
  example-app-prod = {
    workload = "example-app"
    env      = "prod"
    team     = "platform-engineering"
    location = "uksouth"

    subscription_tags = {
      cost_center = "IT-PROD-001"
      criticality = "high"
      owner       = "platform-engineering"
    }

    # Virtual network with subnets
    spoke_vnet = {
      ipv4_address_spaces = {
        default_address_space = {
          address_space_cidr = "/24"
          subnets = {
            default = {
              subnet_prefixes = ["/26"]
            }
            app = {
              subnet_prefixes = ["/26"]
            }
          }
        }
      }
    }

    # Optional: Budget with notifications (uncomment to enable)
    # budget = {
    #   monthly_amount             = 1000
    #   alert_threshold_percentage = 80
    #   alert_contact_emails       = ["platform-team@example.com"]
    # }

    # Optional: GitHub OIDC federated credentials (uncomment to enable)
    # federated_credentials_github = {
    #   repository = "example-app"
    # }
  }

  payments-api-dev = {
    workload = "payments-api"
    env      = "dev"
    team     = "platform-engineering"
    location = "australiaeast"

    subscription_tags = {
      cost_center = "CC-4521"
      criticality = "medium"
      owner       = "platform-engineering"
    }

    # Virtual network with subnets
    spoke_vnet = {
      ipv4_address_spaces = {
        default_address_space = {
          address_space_cidr = "/24"
          subnets = {
            default = {
              subnet_prefixes = ["/26"]
            }
            app = {
              subnet_prefixes = ["/26"]
            }
          }
        }
      }
    }

    # Budget with notifications
    budget = {
      monthly_amount             = 500
      alert_threshold_percentage = 80
      alert_contact_emails       = ["team@example.com"]
    }

    # GitHub OIDC federated credentials
    federated_credentials_github = {
      repository = "test-app-lz"
    }
  }
}
