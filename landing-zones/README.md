# Landing Zones Directory - DEPRECATED

⚠️ **This directory is deprecated and no longer used for new landing zones.**

## New Approach

All landing zones are now defined in the root `terraform.tfvars` file as an array of objects.

### Benefits:
- Common variables (billing scope, hub network, etc.) defined once
- All landing zones visible in one place
- No duplication of configuration
- Easier to add new landing zones

## Migration

The example files in this directory (`example-*.tfvars`) have been migrated to `terraform.tfvars` in the root directory.

For detailed migration instructions, see: [MIGRATION.md](../MIGRATION.md)

## Where to Define New Landing Zones

**Do not create new `.tfvars` files in this directory.**

Instead, edit `terraform.tfvars` in the root directory and add your landing zone to the `landing_zones` map:

```hcl
landing_zones = {
  # Existing landing zones...
  
  my-new-app = {
    subscription_display_name = "my-new-app (Production)"
    subscription_alias_name   = "sub-my-new-app-prod"
    subscription_workload     = "Production"
    # ... rest of configuration
  }
}
```

See `terraform.tfvars.example` for a complete example.
