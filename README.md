# Azure Landing Zone Subscriptions

This repository manages Azure Landing Zone subscription provisioning using Infrastructure as Code (Terraform).

## Overview

This repository contains:
- **Single `terraform.tfvars` file** - All landing zones defined as an array of objects
- **Common variables section** - Shared configuration across all landing zones
- **Terraform root module** - Calls the private `terraform-azurerm-landing-zone-vending` module
- **CI/CD workflows** - Automated plan on PR, apply on merge to main

## Repository Structure

```
.
├── .github/
│   └── workflows/          # GitHub Actions CI/CD workflows
├── landing-zones/          # (Legacy) Individual .tfvars files - use terraform.tfvars instead
├── main.tf                 # Root module with for_each over landing_zones
├── variables.tf            # Input variable definitions (common + landing_zones map)
├── outputs.tf              # Module outputs (map of all landing zones)
├── backend.tf              # Azure Storage backend configuration
├── terraform.tfvars        # ACTIVE: All landing zones defined here
└── terraform.tfvars.example # Example variable structure
```

## How It Works

### New Approach (Recommended)

1. **Define Landing Zones**: Edit `terraform.tfvars` to add/modify landing zones in the `landing_zones` map
2. **Common Variables**: Update shared settings (billing scope, hub network ID) once at the top
3. **Create PR**: Commit changes and create a pull request
4. **Review & Approve**: Platform team reviews the configuration
5. **Merge**: PR merge triggers Terraform apply via GitHub Actions
6. **All Subscriptions Provisioned**: Azure subscriptions created with networking, identity, and budgets

## Usage

### Adding a New Landing Zone

Edit `terraform.tfvars` and add a new entry to the `landing_zones` map:

```hcl
landing_zones = {
  # Existing landing zones...
  
  my-new-app = {
    subscription_display_name = "my-new-app (Production)"
    subscription_alias_name   = "sub-my-new-app-prod"
    subscription_workload     = "Production"
    
    subscription_tags = {
      Environment = "Production"
      Workload    = "my-new-app"
      CostCenter  = "IT-12345"
      Owner       = "platform-engineering"
      CreatedDate = "2026-02-10"
    }
    
    resource_groups = {
      rg_workload = {
        name     = "rg-my-new-app-prod"
        location = "uksouth"
      }
    }
    
    virtual_networks = {
      spoke = {
        name               = "vnet-my-new-app-prod-uksouth"
        resource_group_key = "rg_workload"
        address_space      = ["10.102.0.0/24"]
        location           = "uksouth"
        subnets = {
          default = {
            name             = "snet-default"
            address_prefixes = ["10.102.0.0/26"]
          }
        }
      }
    }
  }
}
```

### Updating Common Variables

Common variables are defined once at the top of `terraform.tfvars` and apply to all landing zones:

```hcl
# ==============================================================================
# COMMON VARIABLES (Applied to All Landing Zones)
# ==============================================================================

common_subscription_billing_scope = "/providers/Microsoft.Billing/..."
common_hub_network_resource_id = "/subscriptions/.../virtualNetworks/vnet-hub"
common_subscription_management_group_id = "Corp"
common_location = "uksouth"
common_github_organization = "nathlan"

common_tags = {
  ManagedBy = "Terraform"
}
```

### Key Benefits

✅ **No duplication** - Common settings defined once  
✅ **Easy to scan** - All landing zones visible in one file  
✅ **Consistent defaults** - Shared values automatically applied  
✅ **Simple additions** - Add new LZ by adding one map entry  
✅ **Single state file** - All landing zones managed together

## Terraform State

State is stored in a single state file in Azure Storage:
- Resource Group: `rg-terraform-state`
- Storage Account: `stterraformstate`
- Container: `alz-subscriptions`
- State File: `landing-zones/terraform.tfstate`

All landing zones are managed in a single Terraform state, allowing for efficient cross-LZ operations and dependencies.

## Required Secrets

GitHub Actions workflows require these repository secrets:
- `AZURE_CLIENT_ID` - Service principal client ID (OIDC)
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Management subscription ID

Configure these in: Settings → Secrets and variables → Actions

## Branch Protection

The `main` branch is protected:
- Require pull request reviews (1 approver)
- Require status checks to pass (terraform-plan)
- Dismiss stale reviews on new commits
- Restrict push access to platform team

## Migration from Legacy Structure

If you have existing `.tfvars` files in `landing-zones/`, they need to be migrated:

1. Copy each landing zone definition from individual `.tfvars` files into the `landing_zones` map in `terraform.tfvars`
2. Extract common values (billing scope, hub network ID) to common variables section
3. Test with `terraform plan` to ensure no unexpected changes
4. Once confirmed, archive or delete the old `.tfvars` files

## Support

For questions or issues:
- Create an issue in this repository
- Contact the platform engineering team
- See the ALZ Vending documentation in `nathlan/.github-private`

## Related Repositories

- **LZ Vending Module**: `nathlan/terraform-azurerm-landing-zone-vending` v1.1.0
- **ALZ Orchestrator Config**: `nathlan/.github-private`
- **Reusable Workflows**: `nathlan/.github-workflows`