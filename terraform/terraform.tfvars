# ==============================================================================
# Example Production Application Landing Zone
# ==============================================================================
# This is a reference example for production workload landing zones
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
  example-api-prod = {
    workload = "example-api-prod"
    env      = "prod"
    team     = "platform-engineering"
    location = "australiaeast"

    subscription_tags = {
      cost_center = "COST-01"
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
      repository = "alz-prod-api-repo"
    }
  }

  graphql-dev = {
    workload = "graphql"
    env      = "dev"
    team     = "app-dev-team"
    location = "australiaeast"

    subscription_tags = {
      cost_center = "CC-12"
      owner       = "app-dev-team"
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
      alert_contact_emails       = ["appdev@example.com"]
    }

    # GitHub OIDC federated credentials
    federated_credentials_github = {
      repository = "graphql-repo"
    }
  }
}

# ========================================
# GitHub Repository Configuration
# ========================================

github_repositories = {
  alz-handover-prod = {
    name        = "alz-handover-prod"
    description = "Production workload repository for handover team - Azure Landing Zone"
    visibility  = "internal"
    topics      = ["azure", "terraform", "handover"]

    # Use the standard workload template
    template = {
      owner      = "nathlan"
      repository = "alz-workload-template"
    }

    # Repository Settings
    has_issues             = true
    has_projects           = false
    has_wiki               = false
    delete_branch_on_merge = true
    allow_squash_merge     = true
    allow_merge_commit     = false
    allow_rebase_merge     = false

    # Team Access
    team_access = {
      platform-engineering = "admin"
    }

    # Branch Protection for main branch
    branch_protection = {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      required_status_checks = [
        { context = "terraform-plan" },
        { context = "security-scan" }
      ]
      strict_required_status_checks_policy = true
      non_fast_forward                     = true
    }
  }
}
