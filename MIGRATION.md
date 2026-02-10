# Migration Guide: Individual tfvars → Single terraform.tfvars

This guide explains how to migrate from the old structure (individual `.tfvars` files per landing zone) to the new structure (single `terraform.tfvars` with landing zones as a map).

## Overview

### Old Structure (Before)
```
landing-zones/
  ├── app1-prod.tfvars
  ├── app2-dev.tfvars
  └── app3-prod.tfvars
```

Each landing zone had its own `.tfvars` file with duplicated common settings.

### New Structure (After)
```
terraform.tfvars  (all landing zones defined here)
```

All landing zones are defined in a single file with common variables extracted.

## Benefits of New Structure

✅ **No duplication** - Common settings (billing scope, hub network ID) defined once  
✅ **Easy to scan** - See all landing zones in one place  
✅ **Consistent defaults** - Shared values automatically applied  
✅ **Simple additions** - Add new LZ by adding one map entry  
✅ **Single state file** - All landing zones managed together efficiently

## Migration Steps

### Step 1: Backup Existing Configuration

```bash
# Create a backup of your existing landing-zones directory
cp -r landing-zones landing-zones.backup
```

### Step 2: Extract Common Variables

Review your existing `.tfvars` files and identify common values:

```hcl
# Common across all LZs:
subscription_billing_scope = "/providers/Microsoft.Billing/..."
subscription_management_group_id = "Corp"
hub_network_resource_id = "/subscriptions/.../virtualNetworks/vnet-hub"
```

### Step 3: Convert Each Landing Zone

For each existing `.tfvars` file, convert it to a map entry in `terraform.tfvars`:

#### Before (landing-zones/my-app-prod.tfvars):
```hcl
tfvars_file_name = "my-app-prod"
subscription_billing_scope = "/providers/Microsoft.Billing/..."
subscription_display_name = "my-app (Production)"
subscription_alias_name = "sub-my-app-prod"
subscription_workload = "Production"
subscription_management_group_id = "Corp"

resource_groups = {
  rg_workload = {
    name     = "rg-my-app-prod"
    location = "uksouth"
  }
}

virtual_networks = {
  spoke = {
    name                    = "vnet-my-app-prod-uksouth"
    address_space           = ["10.100.0.0/24"]
    hub_network_resource_id = "/subscriptions/.../virtualNetworks/vnet-hub"
    # ... rest of config
  }
}
```

#### After (terraform.tfvars):
```hcl
# Common variables (defined once at top of file)
common_subscription_billing_scope = "/providers/Microsoft.Billing/..."
common_subscription_management_group_id = "Corp"
common_hub_network_resource_id = "/subscriptions/.../virtualNetworks/vnet-hub"

# Landing zones map
landing_zones = {
  my-app-prod = {  # Key is the landing zone name (used to be tfvars_file_name)
    subscription_display_name = "my-app (Production)"
    subscription_alias_name   = "sub-my-app-prod"
    subscription_workload     = "Production"
    
    resource_groups = {
      rg_workload = {
        name     = "rg-my-app-prod"
        location = "uksouth"
      }
    }
    
    virtual_networks = {
      spoke = {
        name          = "vnet-my-app-prod-uksouth"
        address_space = ["10.100.0.0/24"]
        # hub_network_resource_id now uses common_hub_network_resource_id automatically
        # ... rest of config
      }
    }
  }
}
```

### Step 4: Update terraform.tfvars

Edit `terraform.tfvars` and:

1. Set common variables at the top
2. Add all your landing zones to the `landing_zones` map
3. Remove duplicate values that are now in common variables

See `terraform.tfvars.example` for a complete reference.

### Step 5: Test the Configuration

```bash
# Format the files
terraform fmt

# Initialize (note: single state file now)
terraform init

# Plan to verify no unexpected changes
terraform plan

# Review the plan output carefully:
# - There should be NO changes to existing resources
# - Terraform is just reorganizing its state
```

### Step 6: Apply State Migration (if needed)

If you have existing infrastructure:

```bash
# The state backend has changed from per-LZ to single state
# You may need to migrate state or use terraform import

# Option 1: Import existing resources into new state
terraform import 'module.landing_zone["my-app-prod"].azurerm_subscription.this' /subscriptions/...

# Option 2: Let Terraform recreate (NOT RECOMMENDED for production)
# This will destroy and recreate resources
```

**Important**: For production environments, consult with your platform team before applying state changes.

### Step 7: Clean Up Old Files

Once migration is complete and tested:

```bash
# Archive old tfvars files
mkdir -p archive/
mv landing-zones/*.tfvars archive/

# Or delete them (after confirming migration is successful)
rm landing-zones/*.tfvars
```

## Rollback Plan

If you need to rollback:

1. Restore your backup: `cp -r landing-zones.backup/* landing-zones/`
2. Revert the code changes: `git revert <commit-hash>`
3. Re-initialize Terraform: `terraform init -reconfigure`

## Troubleshooting

### Issue: State file conflicts

**Problem**: Terraform is trying to create resources that already exist.

**Solution**: Use `terraform import` to import existing resources into the new state structure.

### Issue: Module not found

**Problem**: Error about landing_zone module not being installed.

**Solution**: Ensure the module source in `main.tf` points to the correct repository and version.

### Issue: Variables not recognized

**Problem**: Terraform complains about unknown variables.

**Solution**: Ensure all required common variables are defined at the top of `terraform.tfvars`.

## Example: Complete Migration

Here's a complete before/after example:

### Before: landing-zones/api-dev.tfvars
```hcl
tfvars_file_name = "api-dev"
subscription_billing_scope = "/providers/Microsoft.Billing/billingAccounts/..."
subscription_display_name = "api (DevTest)"
subscription_alias_name = "sub-api-dev"
subscription_workload = "DevTest"
subscription_management_group_id = "Corp"

subscription_tags = {
  Environment = "DevTest"
  Workload    = "api"
  ManagedBy   = "Terraform"
}

resource_groups = {
  rg_workload = {
    name     = "rg-api-dev"
    location = "uksouth"
  }
}

virtual_networks = {
  spoke = {
    name                    = "vnet-api-dev-uksouth"
    address_space           = ["10.101.0.0/24"]
    hub_network_resource_id = "/subscriptions/.../virtualNetworks/vnet-hub"
    location                = "uksouth"
    resource_group_key      = "rg_workload"
    
    subnets = {
      default = {
        name             = "snet-default"
        address_prefixes = ["10.101.0.0/26"]
      }
    }
  }
}
```

### After: terraform.tfvars
```hcl
# ==============================================================================
# COMMON VARIABLES
# ==============================================================================
common_subscription_billing_scope = "/providers/Microsoft.Billing/billingAccounts/..."
common_hub_network_resource_id = "/subscriptions/.../virtualNetworks/vnet-hub"
common_subscription_management_group_id = "Corp"
common_location = "uksouth"

common_tags = {
  ManagedBy = "Terraform"
}

# ==============================================================================
# LANDING ZONES
# ==============================================================================
landing_zones = {
  api-dev = {
    subscription_display_name = "api (DevTest)"
    subscription_alias_name   = "sub-api-dev"
    subscription_workload     = "DevTest"
    
    subscription_tags = {
      Environment = "DevTest"
      Workload    = "api"
    }
    
    resource_groups = {
      rg_workload = {
        name     = "rg-api-dev"
        location = "uksouth"
      }
    }
    
    virtual_networks = {
      spoke = {
        name               = "vnet-api-dev-uksouth"
        address_space      = ["10.101.0.0/24"]
        location           = "uksouth"
        resource_group_key = "rg_workload"
        
        subnets = {
          default = {
            name             = "snet-default"
            address_prefixes = ["10.101.0.0/26"]
          }
        }
      }
    }
  }
}
```

## Support

For assistance with migration:
- Create an issue in this repository
- Contact the platform engineering team
- Reference this guide in your migration PR
