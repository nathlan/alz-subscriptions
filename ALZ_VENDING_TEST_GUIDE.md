# ALZ Vending Test Guide

## Overview

The Azure Landing Zone (ALZ) Vending Machine is an automated provisioning system that creates standardized Azure landing zones (subscriptions) for workloads. This guide documents the end-to-end testing process for the ALZ vending mechanism, demonstrating how a new landing zone is created, configured, and deployed.

The vending process ensures:
- **Consistency**: All landing zones follow organization standards and naming conventions
- **Validation**: Inputs are validated before resources are created
- **Automation**: Terraform workflows handle all Azure resource provisioning
- **Traceability**: All configurations are version-controlled in Git

This test demonstrates the complete workflow from configuration creation through Azure resource deployment.

---

## Test Scenario

### Test Landing Zone: `test-workload-api-prod`

We created a test landing zone configuration to validate the entire vending process:

| Property | Value |
|----------|-------|
| **Workload Name** | test-workload-api |
| **Environment** | Production |
| **Location** | UK South (uksouth) |
| **Team Owner** | platform-engineering |
| **Address Space** | 10.0.0.0/24 |
| **Subscription Name** | sub-test-workload-api-prod |

This test configuration represents a typical production API workload that would be deployed to UK South region and managed by the platform engineering team.

---

## Validation Checklist

All inputs and configurations are validated before being committed. The following validations were performed:

### ✅ Workload Name Format
- **Rule**: Must be in kebab-case (lowercase with hyphens)
- **Value**: `test-workload-api`
- **Status**: ✓ Valid
- **Example**: `my-app-api`, `data-pipeline`, `web-frontend`

### ✅ Environment Validation
- **Rule**: Environment must map to a valid Azure environment code
  - `Development` → `dev`
  - `Staging` → `stg`
  - `Production` → `prod`
- **Value**: `Production` → `prod`
- **Status**: ✓ Valid
- **Error Prevention**: Invalid environments are rejected before configuration is saved

### ✅ Location Validation
- **Rule**: Must be a valid Azure region short code
- **Value**: `uksouth`
- **Status**: ✓ Valid
- **Valid Regions**: uksouth, eastus, westeurope, etc.
- **Error Prevention**: Non-existent regions are rejected

### ✅ Team Existence Validation
- **Rule**: Team must exist in team registry before landing zone can reference it
- **Value**: `platform-engineering`
- **Status**: ✓ Valid
- **Impact**: Ensures proper RBAC and cost allocation
- **Error Prevention**: Non-existent teams are rejected

### ✅ Address Space Format
- **Rule**: Must be in CIDR notation with /24 prefix (supports 256 IP addresses)
- **Value**: `10.0.0.0/24`
- **Status**: ✓ Valid
- **Allocation**: /24 allows for 3 subnets with sufficient capacity per workload
- **Format Examples**: `10.0.1.0/24`, `172.16.5.0/24`
- **Error Prevention**: Invalid CIDR notation is rejected

### ✅ No Duplicate Landing Zone Keys
- **Rule**: Each landing zone must have a unique combination of (workload-name, environment, location)
- **Value**: `test-workload-api-prod-uksouth`
- **Status**: ✓ No duplicates found
- **Impact**: Prevents accidental configuration overwrites
- **Error Prevention**: Duplicate keys are detected and rejected

### ✅ No CIDR Overlaps
- **Rule**: Address spaces must not overlap with existing landing zones
- **Value**: `10.0.0.0/24`
- **Status**: ✓ No overlaps detected
- **Scope**: Checked against all existing landing zones in the configuration
- **Error Prevention**: Overlapping CIDRs are detected and rejected
- **Impact**: Ensures proper network isolation between workloads

---

## Configuration Generated

The following configuration was added to the landing zones definition:

```hcl
# Example location in your landing zones configuration file:
# This represents the test landing zone added during vending

landing_zones = {
  "test-workload-api-prod-uksouth" = {
    workload_name = "test-workload-api"
    environment   = "prod"
    location      = "uksouth"
    team_name     = "platform-engineering"
    address_space = "10.0.0.0/24"
    
    # Automatically generated metadata
    subscription_name = "sub-test-workload-api-prod"
    description       = "Landing zone for test-workload-api production workload"
  }
}
```

### Configuration Details

- **Key**: Uniquely identifies the landing zone (`test-workload-api-prod-uksouth`)
- **Workload Name**: Used in all resource naming conventions
- **Environment Code**: Ensures consistent naming (prod, dev, stg)
- **Location**: Azure region where resources will be deployed
- **Team Name**: Linked to your organization's team structure for billing and RBAC
- **Address Space**: Network CIDR block for the virtual network
- **Subscription Name**: Azure subscription naming convention follows: `sub-{workload}-{environment}`

---

## Expected Resources

Once deployed, the following Azure resources will be created in the `sub-test-workload-api-prod` subscription:

### Azure Subscription
- **Subscription Name**: `sub-test-workload-api-prod`
- **Billing Account**: Associated with `platform-engineering` team
- **Status**: Will be created by Terraform during workflow execution

### Resource Group
- **Naming Convention**: `rg-test-workload-api-prod-{location}`
- **Location**: `uksouth`
- **Purpose**: Contains all deployed resources for this landing zone
- **Access**: Managed identity with OIDC authentication

### Virtual Network
- **Name**: `vnet-test-workload-api-prod-{location}`
- **Address Space**: `10.0.0.0/24` (256 IP addresses total)
- **Location**: `uksouth`
- **Subnets**: 3 automatically created subnets:
  - **Default Subnet**: `10.0.0.0/26` (64 IPs, typically for compute)
  - **Data Subnet**: `10.0.0.64/26` (64 IPs, for databases)
  - **Services Subnet**: `10.0.0.128/26` (64 IPs, for managed services)
- **Network Security**: NSGs automatically applied to subnets

### User-Managed Identity
- **Name**: `uai-test-workload-api-prod-{location}`
- **Purpose**: Service authentication and authorization
- **OIDC Configuration**: Enabled for GitHub Actions and other CI/CD systems
- **Permissions**: RBAC roles assigned based on team requirements

### Budget & Cost Alerts
- **Name**: `budget-test-workload-api-prod`
- **Alert Thresholds**: Configured to notify at 80%, 100%, and 120% of budget
- **Owner**: `platform-engineering` team
- **Notifications**: Email alerts to team distribution list

### Additional Configuration
- **Tags**: Applied to all resources for cost tracking and governance
  - `environment = prod`
  - `workload = test-workload-api`
  - `team = platform-engineering`
  - `location = uksouth`

---

## Next Steps

### 1. Pull Request Review

The landing zone configuration is submitted as a pull request:

- **Code Review**: Team members review the configuration
- **Validation**: Automated checks verify the syntax and naming conventions
- **Approval**: At least one approval from the `platform-engineering` team

### 2. Merge and Workflow Trigger

Once approved and merged to the main branch:

- **GitHub Actions Trigger**: Terraform workflow automatically executes
- **State Lock**: Terraform state is locked to prevent concurrent changes
- **Plan Review**: Terraform plan is generated and reviewed for approval
- **Status Check**: PR status updated with workflow results

### 3. Terraform Workflow Execution

The CI/CD pipeline performs the following:

```
Step 1: Initialize
  └─ Download Terraform modules
  └─ Configure backend (state storage)
  └─ Validate provider credentials

Step 2: Plan
  └─ Analyze configuration
  └─ Determine required resources
  └─ Generate changeset

Step 3: Review & Approval
  └─ Manual approval required for production changes
  └─ Verify Terraform plan matches expectations

Step 4: Apply
  └─ Create Azure subscription
  └─ Provision resource groups
  └─ Deploy virtual network and subnets
  └─ Configure managed identity with OIDC
  └─ Set up budget and alerts
  └─ Apply tags and naming conventions

Step 5: Output
  └─ Store subscription ID
  └─ Export network information
  └─ Document resource IDs
  └─ Update inventory
```

### 4. Resource Provisioning Timeline

- **Subscription Creation**: 5-10 minutes
- **Resource Group**: < 1 minute
- **Virtual Network**: 2-3 minutes
- **Subnets & NSGs**: 2-3 minutes
- **Managed Identity**: < 1 minute
- **OIDC Configuration**: < 1 minute
- **Budget Setup**: < 1 minute
- **Total Time**: ~15-20 minutes for full deployment

### 5. Output Extraction

After successful deployment, the following outputs are available:

```bash
# Subscription ID
subscription_id = "00000000-0000-0000-0000-000000000000"

# Virtual Network Details
vnet_id = "/subscriptions/.../resourceGroups/rg-test-workload-api-prod-uksouth/providers/Microsoft.Network/virtualNetworks/vnet-test-workload-api-prod-uksouth"
vnet_name = "vnet-test-workload-api-prod-uksouth"

# Managed Identity
managed_identity_id = "/subscriptions/.../resourceGroups/rg-test-workload-api-prod-uksouth/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-test-workload-api-prod-uksouth"
managed_identity_principal_id = "00000000-0000-0000-0000-000000000000"

# Network Information
address_space = ["10.0.0.0/24"]
subnets = {
  "default"  = "10.0.0.0/26"
  "data"     = "10.0.0.64/26"
  "services" = "10.0.0.128/26"
}
```

### 6. Handoff & Workload Deployment

Once resources are provisioned:

- **Credentials**: Team receives access to the subscription
- **Documentation**: Generated runbooks and configuration details
- **Workload Deployment**: Team can now deploy their applications
- **Monitoring**: Cost tracking and resource monitoring activated

---

## Cleanup

If you need to remove the test landing zone after validation, follow these steps:

### Step 1: Remove Configuration

1. Open the landing zones configuration file
2. Locate the `test-workload-api-prod-uksouth` entry
3. Delete the entire configuration block:

```diff
  landing_zones = {
-   "test-workload-api-prod-uksouth" = {
-     workload_name = "test-workload-api"
-     environment   = "prod"
-     location      = "uksouth"
-     team_name     = "platform-engineering"
-     address_space = "10.0.0.0/24"
-     subscription_name = "sub-test-workload-api-prod"
-     description   = "Landing zone for test-workload-api production workload"
-   }
  }
```

### Step 2: Commit & Push

```bash
git add .
git commit -m "Remove test landing zone: test-workload-api-prod"
git push origin your-branch
```

### Step 3: Create Pull Request

- Create a PR with the deletion
- Request review from team members
- Ensure no active workloads depend on this subscription

### Step 4: Merge & Trigger Workflow

- Merge PR to main branch
- Terraform workflow will execute and destroy resources
- Monitor the workflow for completion

### Step 5: Azure Cleanup

After Terraform completes:

1. **Subscription**: Will be removed from Azure
2. **Resources**: All resources within the subscription are deleted
3. **Billing**: Stops immediately (no ongoing costs)
4. **Data**: Permanently deleted (ensure no important data remains)

### Step 6: Verification

Confirm cleanup completion:

```bash
# Check subscription is gone (if using Azure CLI)
az account list --query "[].name"

# Verify in Azure Portal
# Navigate to Subscriptions → Confirm test-sub-test-workload-api-prod no longer appears
```

### ⚠️ Important Warnings

- **Data Loss**: Deletion is permanent. Ensure no critical data is in the subscription.
- **Dependencies**: Verify no applications are accessing resources in this subscription.
- **Billing**: Remove any budget alerts to prevent false notifications.
- **Access**: Revoke any manual access granted to the subscription.

---

## Troubleshooting

### Configuration Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Invalid workload name format | Contains uppercase or underscores | Use kebab-case (lowercase with hyphens) |
| Environment not recognized | Typo in environment value | Use exact values: `Development`, `Staging`, `Production` |
| Team not found | Team doesn't exist in registry | Create team first or use existing team name |
| CIDR overlap detected | Address space conflicts with existing network | Choose different /24 block |
| Duplicate landing zone key | Combination of name, env, location already exists | Modify one of the values |

### Deployment Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Subscription creation fails | Azure quota exceeded | Contact Azure support |
| Network creation fails | CIDR reservation issue | Verify address space is unique |
| OIDC configuration fails | Missing service principal | Re-run Terraform apply |
| Workflow stuck | State lock held by previous run | Contact DevOps team |

### Post-Deployment Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Can't access subscription | RBAC not configured | Team admin must assign roles |
| Networking issues | NSG too restrictive | Update network security group rules |
| Cost alerts not working | Budget misconfigured | Verify budget threshold and email |

---

## Support & Documentation

For additional help:

- **Questions**: Contact the platform engineering team
- **Documentation**: See main README.md for architecture details
- **Terraform Code**: Review `modules/` directory for implementation details
- **Examples**: Check `examples/` for additional landing zone configurations

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024 | Initial guide creation, test scenario documentation |

---

**Last Updated**: 2024
**Document Owner**: Platform Engineering Team
**Status**: Published
