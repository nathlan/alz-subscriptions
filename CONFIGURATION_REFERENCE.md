# Azure Landing Zone Subscriptions - Configuration Reference Guide

This document provides a comprehensive reference of all configuration values extracted from the repository. Use this as a quick reference when implementing or configuring the agent.

---

## 1. Terraform Backend Configuration

**File:** `terraform/backend.tf`

These values configure where Terraform state is stored in Azure.

| Configuration | Value | Type | Required | Status |
|---|---|---|---|---|
| **Backend Type** | `azurerm` | string | ✓ | ✅ Confirmed |
| **Resource Group Name** | `rg-terraform-state` | string | ✓ | ✅ Confirmed |
| **Storage Account Name** | `stterraformstate` | string | ✓ | ✅ Confirmed |
| **Container Name** | `alz-subscriptions` | string | ✓ | ✅ Confirmed |
| **State File Path** | `landing-zones/main.tfstate` | string | ✓ | ✅ Confirmed |
| **Authentication Method** | `use_oidc = true` | boolean | ✓ | ✅ Confirmed (OIDC) |

### Backend Configuration Example
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "alz-subscriptions"
    key                  = "landing-zones/main.tfstate"
    use_oidc             = true
  }
}
```

---

## 2. Terraform Module Configuration

**File:** `terraform/main.tf`

The root module calls a private landing zone vending module to provision complete Azure landing zones.

| Configuration | Value | Type | Required | Status |
|---|---|---|---|---|
| **Module Source** | `github.com/nathlan/terraform-azurerm-landing-zone-vending` | string | ✓ | ✅ Confirmed |
| **Module Version** | `v1.0.4` | string (ref tag) | ✓ | ✅ Confirmed |
| **Terraform Min Version** | `>= 1.10.0` | string | ✓ | ✅ Confirmed |
| **AzureRM Provider** | `hashicorp/azurerm` | string | ✓ | ✅ Confirmed |
| **AzureRM Provider Version** | `~> 4.0` | string | ✓ | ✅ Confirmed |
| **Time Provider** | `hashicorp/time` | string | ✓ | ✅ Confirmed |
| **Time Provider Version** | `>= 0.9, < 1.0` | string | ✓ | ✅ Confirmed |
| **Provider Authentication** | `use_oidc = true` | boolean | ✓ | ✅ Confirmed (OIDC) |

### Module Source URL Pattern
```
https://github.com/nathlan/terraform-azurerm-landing-zone-vending/tree/v1.0.4
```

### Module Features
The module provisions complete Azure Landing Zones including:
- Subscription creation and management group association
- Virtual network with hub peering and subnets
- User-managed identity with OIDC federated credentials
- Role assignments for workload identity
- Budget with notification thresholds
- Auto-generated resource names following Azure naming conventions

---

## 3. Terraform Variables (terraform.tfvars)

**File:** `terraform/terraform.tfvars`

These are the input variables that configure the landing zone deployments.

### Common Configuration Variables

| Variable Name | Current Value | Type | Required | Status | Notes |
|---|---|---|---|---|---|
| **subscription_billing_scope** | `PLACEHOLDER_BILLING_SCOPE` | string | ✓ | 🔴 PLACEHOLDER | Update with actual billing scope ID |
| **subscription_management_group_id** | `Corp` | string | ✓ | ✅ Confirmed | Management group for subscriptions |
| **hub_network_resource_id** | `PLACEHOLDER_HUB_VNET_ID` | string | ✓ | 🔴 PLACEHOLDER | Update with actual hub VNet resource ID |
| **github_organization** | `nathlan` | string | Optional | ✅ Confirmed | For federated GitHub OIDC credentials |
| **azure_address_space** | `10.100.0.0/16` | string (CIDR) | ✓ | ✅ Confirmed | Base address space for IP automation |

### Tags Configuration

```hcl
tags = {
  managed_by       = "terraform"
  environment_type = "production"
}
```

| Tag Key | Tag Value | Status |
|---|---|---|
| `managed_by` | `terraform` | ✅ Confirmed |
| `environment_type` | `production` | ✅ Confirmed |

### Landing Zones Configuration

The repository includes an example landing zone configuration:

| Landing Zone Key | Value | Type | Status |
|---|---|---|---|
| **Name** | `example-app-prod` | string | ✅ Confirmed (Example) |
| **Workload** | `example-app` | string | ✅ Confirmed (Example) |
| **Environment** | `prod` | string (enum: dev/test/prod) | ✅ Confirmed (Example) |
| **Team** | `platform-engineering` | string | ✅ Confirmed (Example) |
| **Location** | `uksouth` | string (Azure region) | ✅ Confirmed (Example) |

#### Virtual Network Configuration (Example)
```hcl
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
```

#### Optional Features (Commented Out)
- **Budget**: Monthly amount with alert thresholds
- **GitHub OIDC**: Federated credentials for GitHub Actions

---

## 4. GitHub Actions Workflow Configuration

**File:** `.github/workflows/terraform-deploy.yml`

The workflow calls a reusable parent workflow for Azure Terraform deployments.

| Configuration | Value | Type | Status |
|---|---|---|---|
| **Workflow Name** | `Terraform Deployment` | string | ✅ Confirmed |
| **Trigger Branches** | `main` | string | ✅ Confirmed |
| **Terraform Version** | `1.10.5` | string | ✅ Confirmed (Default) |
| **Working Directory** | `terraform` | string | ✅ Confirmed |
| **Azure Region** | `uksouth` | string | ✅ Confirmed (Default) |
| **Parent Workflow** | `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main` | string | ✅ Confirmed |
| **Environment (Workflow Dispatch)** | `azure-landing-zones` | string | ✅ Confirmed |

### Workflow Triggers

| Trigger Type | Paths | Status |
|---|---|---|
| **Push** | `terraform/**`, `.github/workflows/terraform-deploy.yml` | ✅ Confirmed |
| **Pull Request** | `terraform/**`, `.github/workflows/terraform-deploy.yml` | ✅ Confirmed |
| **Workflow Dispatch** | Manual trigger with environment selection | ✅ Confirmed |

### Workflow Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
  id-token: write
  issues: write
```

### Required GitHub Secrets

These secrets must be configured in the GitHub repository settings:

| Secret Name | Type | Status | Notes |
|---|---|---|---|
| **AZURE_CLIENT_ID** | string | 🔴 PLACEHOLDER | Service principal/managed identity client ID |
| **AZURE_TENANT_ID** | string | 🔴 PLACEHOLDER | Azure AD tenant ID |
| **AZURE_SUBSCRIPTION_ID** | string | 🔴 PLACEHOLDER | Azure subscription ID for state management |

---

## 5. Placeholder Values That Need Configuration

These values are marked as `PLACEHOLDER` and **MUST** be updated before deployment:

### Critical Placeholders

| Placeholder | File | Variable | Format | Example |
|---|---|---|---|---|
| `PLACEHOLDER_BILLING_SCOPE` | `terraform.tfvars` | `subscription_billing_scope` | `/subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/{billingAccountId}` | `/subscriptions/12345678-1234-1234-1234-123456789012/providers/Microsoft.Billing/billingAccounts/1234567890` |
| `PLACEHOLDER_HUB_VNET_ID` | `terraform.tfvars` | `hub_network_resource_id` | `/subscriptions/{subId}/resourceGroups/{rgName}/providers/Microsoft.Network/virtualNetworks/{vnetName}` | `/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub` |
| `AZURE_CLIENT_ID` | GitHub Secrets | N/A (GitHub Actions) | UUID | `12345678-1234-1234-1234-123456789abc` |
| `AZURE_TENANT_ID` | GitHub Secrets | N/A (GitHub Actions) | UUID | `87654321-4321-4321-4321-abcdef123456` |
| `AZURE_SUBSCRIPTION_ID` | GitHub Secrets | N/A (GitHub Actions) | UUID | `11111111-2222-3333-4444-555555555555` |

### How to Find Placeholder Values

#### `PLACEHOLDER_BILLING_SCOPE`
1. In Azure Portal, navigate to **Subscriptions**
2. Select the subscription used for creating new subscriptions
3. Copy the subscription ID
4. Format: `/subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingAccounts/{billingAccountId}`
5. You can use Azure CLI: `az billing account list --output json`

#### `PLACEHOLDER_HUB_VNET_ID`
1. In Azure Portal, navigate to **Virtual Networks**
2. Find your hub network (typically in a shared services/connectivity subscription)
3. Copy the **Resource ID** from the Overview page
4. Format: `/subscriptions/{subId}/resourceGroups/{rgName}/providers/Microsoft.Network/virtualNetworks/{vnetName}`
5. You can use Azure CLI: `az network vnet show --resource-group <rg> --name <vnet> --query id`

#### GitHub Secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`)
1. In GitHub repository settings, go to **Secrets and variables** → **Actions**
2. Click **New repository secret** for each value
3. The values come from your Azure service principal or managed identity
4. You can retrieve them using Azure CLI:
   - `az ad sp show --id <client-id> --query appId`
   - `az account show --query tenantId`
   - `az account show --query id`

---

## 6. Confirmed Correct Values

These values are confirmed correct and do NOT need to be changed:

### Backend & Storage
- ✅ **Backend Type**: `azurerm`
- ✅ **Resource Group**: `rg-terraform-state`
- ✅ **Storage Account**: `stterraformstate`
- ✅ **Container**: `alz-subscriptions`
- ✅ **State File**: `landing-zones/main.tfstate`
- ✅ **Authentication**: OIDC enabled (`use_oidc = true`)

### Module & Providers
- ✅ **Module Source**: `github.com/nathlan/terraform-azurerm-landing-zone-vending`
- ✅ **Module Version**: `v1.0.4`
- ✅ **Terraform Version**: `>= 1.10.0` (workflow uses 1.10.5)
- ✅ **AzureRM Provider**: `~> 4.0`
- ✅ **Time Provider**: `>= 0.9, < 1.0`

### Variables
- ✅ **Management Group ID**: `Corp`
- ✅ **GitHub Organization**: `nathlan`
- ✅ **Azure Address Space**: `10.100.0.0/16`
- ✅ **Tags - managed_by**: `terraform`
- ✅ **Tags - environment_type**: `production`

### GitHub Actions
- ✅ **Parent Workflow**: `nathlan/.github-workflows` repository
- ✅ **Working Directory**: `terraform`
- ✅ **Azure Region**: `uksouth`
- ✅ **Terraform Version (Workflow)**: `1.10.5`
- ✅ **Environment**: `azure-landing-zones`
- ✅ **Workflow Triggers**: Push & PR on `main` branch with terraform path changes

---

## 7. Configuration Examples for Agent Implementation

### Example 1: How to Use in a GitHub Actions Workflow

If you're creating an agent that deploys using these values:

```yaml
name: Agent Landing Zone Deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: Target environment
        type: choice
        options:
          - azure-landing-zones
        default: azure-landing-zones

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Terraform Deploy
        uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
        with:
          environment: ${{ inputs.environment }}
          terraform-version: '1.10.5'
          working-directory: 'terraform'
          azure-region: 'uksouth'
        secrets:
          AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Example 2: How to Initialize Terraform

If you're creating an agent that initializes Terraform:

```bash
#!/bin/bash

# Initialize Terraform with the configured backend
cd terraform/

terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=alz-subscriptions" \
  -backend-config="key=landing-zones/main.tfstate" \
  -backend-config="use_oidc=true"

# Validate configuration
terraform validate

# Plan deployment
terraform plan \
  -var-file="terraform.tfvars" \
  -out=tfplan
```

### Example 3: How to Update terraform.tfvars Programmatically

If your agent needs to update configuration values:

```hcl
# Example of updating terraform.tfvars with actual values
subscription_billing_scope       = "/subscriptions/12345678-1234-1234-1234-123456789012/providers/Microsoft.Billing/billingAccounts/1234567890"
subscription_management_group_id = "Corp"
hub_network_resource_id          = "/subscriptions/87654321-4321-4321-4321-abcdef123456/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
github_organization              = "nathlan"
azure_address_space              = "10.100.0.0/16"

tags = {
  managed_by       = "terraform"
  environment_type = "production"
  deployment_date  = "2024-02-11"
}

landing_zones = {
  example-app-prod = {
    workload = "example-app"
    env      = "prod"
    team     = "platform-engineering"
    location = "uksouth"
    # ... rest of configuration
  }
}
```

### Example 4: How to Validate Landing Zone Configuration

If your agent needs to validate landing zone configurations:

```hcl
# Validation rules that must be satisfied

# 1. Environment must be one of: dev, test, prod
env = "prod"  # ✅ Valid

# 2. Address space CIDR format must be valid
azure_address_space = "10.100.0.0/16"  # ✅ Valid format: X.X.X.X/XX

# 3. Address space prefix format must be valid
address_space_cidr = "/24"  # ✅ Valid format: /XX

# 4. Subnet prefix format must be valid
subnet_prefixes = ["/26", "/28"]  # ✅ Valid format: /XX

# Invalid examples that agent should reject:
# env = "staging"                    # ❌ Not in [dev, test, prod]
# azure_address_space = "10.100.0.0" # ❌ Missing CIDR notation
# address_space_cidr = "24"          # ❌ Missing leading slash
# subnet_prefixes = ["26"]           # ❌ Missing leading slash
```

### Example 5: How to Structure Multi-Landing-Zone Configuration

If your agent is deploying multiple landing zones:

```hcl
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
    spoke_vnet = {
      ipv4_address_spaces = {
        default_address_space = {
          address_space_cidr = "/24"
          subnets = {
            default = { subnet_prefixes = ["/26"] }
            app = { subnet_prefixes = ["/26"] }
          }
        }
      }
    }
  }
  
  # Additional landing zones would follow the same structure
  analytics-prod = {
    workload = "analytics"
    env      = "prod"
    team     = "data-engineering"
    location = "uksouth"
    # ... configuration
  }
}
```

---

## 8. Quick Configuration Checklist

Use this checklist when implementing the agent:

### Before Deployment
- [ ] ✅ Verify Terraform version >= 1.10.0
- [ ] ✅ Verify AzureRM provider version compatible with ~> 4.0
- [ ] ✅ Verify backend storage account exists: `stterraformstate`
- [ ] ✅ Verify backend container exists: `alz-subscriptions`
- [ ] ✅ **UPDATE**: Replace `PLACEHOLDER_BILLING_SCOPE` with actual value
- [ ] **UPDATE**: Replace `PLACEHOLDER_HUB_VNET_ID` with actual value
- [ ] **UPDATE**: Configure GitHub secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- [ ] Verify management group exists: `Corp`
- [ ] Verify Azure address space doesn't conflict: `10.100.0.0/16`

### During Deployment
- [ ] Verify Terraform plan includes expected landing zones
- [ ] Verify OIDC authentication is working
- [ ] Verify all placeholders have been replaced
- [ ] Verify landing zone environment is valid (dev/test/prod)
- [ ] Verify subnet CIDR notation is correct (/24, /26, etc.)

### After Deployment
- [ ] Verify state file exists in blob storage at `landing-zones/main.tfstate`
- [ ] Verify subscriptions created in management group `Corp`
- [ ] Verify virtual networks peered with hub network
- [ ] Verify user-managed identities created for OIDC
- [ ] Verify tags applied to all resources

---

## 9. Common Configuration Scenarios

### Scenario: Deploy to Different Azure Region

To deploy landing zones to a region other than `uksouth`:

1. **Option A**: Update workflow (one-time change)
   ```yaml
   with:
     azure-region: 'australiaeast'  # or other region
   ```

2. **Option B**: Update landing zone configuration
   ```hcl
   landing_zones = {
     example-app-prod = {
       location = "australiaeast"  # Change per landing zone
       # ... rest of config
     }
   }
   ```

### Scenario: Enable Budget Alerts

To add budget monitoring to a landing zone:

```hcl
budget = {
  monthly_amount             = 1000
  alert_threshold_percentage = 80
  alert_contact_emails       = ["platform-team@example.com"]
}
```

### Scenario: Enable GitHub OIDC

To enable GitHub Actions authentication without secrets:

```hcl
federated_credentials_github = {
  repository = "example-app"
}
```

This creates a federated identity credential that allows the GitHub Actions workflow to authenticate to Azure without storing secrets.

---

## 10. Support & References

### Official Documentation
- [Azure Landing Zone Module](https://github.com/nathlan/terraform-azurerm-landing-zone-vending)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub OIDC with Azure](https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation)
- [Azure Billing Scope Format](https://learn.microsoft.com/en-us/azure/billing/)

### Configuration Files in This Repository
- `terraform/backend.tf` - Backend configuration
- `terraform/main.tf` - Module configuration and provider setup
- `terraform/variables.tf` - Variable definitions and validation
- `terraform/terraform.tfvars` - Variable values
- `.github/workflows/terraform-deploy.yml` - Deployment workflow

### Key Contact
- **Module Author**: nathlan
- **Repository**: [terraform-azurerm-landing-zone-vending](https://github.com/nathlan/terraform-azurerm-landing-zone-vending)

---

## Document Information

- **Generated**: 2024-02-11
- **Version**: 1.0
- **Terraform Module Version**: v1.0.4
- **Terraform Version**: >= 1.10.0 (workflow: 1.10.5)
- **Azure Provider Version**: ~> 4.0
