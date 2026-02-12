# ==============================================================================
# Example Production Application Landing Zone
# ==============================================================================
# This is a reference example for production workload landing zones using the
# new v1.0.4 (v3.0.0) interface with auto-generated naming and smart defaults.
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

  # ==============================================================================
  # Test Landing Zone for ALZ Vending Process
  # ==============================================================================
  # This landing zone is used for testing the Azure Landing Zone (ALZ) vending
  # automation, including subscription creation, resource provisioning, and
  # GitHub OIDC federated credentials setup. This is a reference implementation
  # for the e2e vending test process.
  # ==============================================================================
  test-workload-api-prod = {
    workload = "test-workload-api"
    env      = "prod"
    team     = "platform-engineering"
    location = "uksouth"

    subscription_tags = {
      cost_center = "TEST-CC-001"
      owner       = "platform-engineering"
      purpose     = "e2e-vending-test"
      created_by  = "alz-vending-agent"
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
            database = {
              subnet_prefixes = ["/27"]
            }
          }
        }
      }
    }

    # Budget with notifications
    budget = {
      monthly_amount             = 750
      alert_threshold_percentage = 85
      alert_contact_emails       = ["platform-engineering@example.com"]
    }

    # GitHub OIDC federated credentials
    federated_credentials_github = {
      repository = "test-workload-api"
    }
  }
}
