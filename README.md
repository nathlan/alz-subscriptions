# Azure Landing Zone Subscriptions

This repository manages Azure Landing Zone subscription provisioning using Infrastructure as Code (Terraform).

## Overview

This repository contains:
- **Landing zone `.tfvars` files** - One file per vended subscription in `landing-zones/`
- **Terraform root module** - Calls the private `terraform-azurerm-landing-zone-vending` module
- **CI/CD workflows** - Automated plan on PR, apply on merge to main

## Repository Structure

```
.
├── .github/
│   └── workflows/          # GitHub Actions CI/CD workflows
├── landing-zones/          # One .tfvars file per landing zone
│   ├── example-app-prod.tfvars
│   └── example-api-dev.tfvars
├── main.tf                 # Root module calling LZ vending module
├── variables.tf            # Input variable definitions
├── outputs.tf              # Module outputs
├── backend.tf              # Azure Storage backend configuration
└── terraform.tfvars.example # Example variable values
```

## How It Works

1. **Request a Landing Zone**: Use the ALZ Vending orchestrator agent (`@alz-vending`) to create a new subscription
2. **PR Created**: Agent creates a PR with a new `.tfvars` file in `landing-zones/`
3. **Review & Approve**: Platform team reviews the configuration
4. **Merge**: PR merge triggers Terraform apply via GitHub Actions
5. **Subscription Provisioned**: Azure subscription created with networking, identity, and budgets

## Usage

### Using the ALZ Vending Orchestrator

```
@alz-vending

workload_name: my-app
environment: Production
location: uksouth
team_name: platform-engineering
address_space: 10.100.0.0/24
cost_center: IT-12345
```

### Manual Landing Zone Creation

If not using the orchestrator agent, you can manually create a `.tfvars` file:

1. Copy `terraform.tfvars.example` to `landing-zones/your-workload-name.tfvars`
2. Update all values for your workload
3. Create a PR with the new file
4. Request review from platform team
5. Merge to provision

## Terraform State

State is stored in Azure Storage with one state file per landing zone:
- Resource Group: `rg-terraform-state`
- Storage Account: `stterraformstate`
- Container: `alz-subscriptions`
- State File: `landing-zones/{workload-name}.tfstate`

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

## Support

For questions or issues:
- Create an issue in this repository
- Contact the platform engineering team
- See the ALZ Vending documentation in `nathlan/.github-private`

## Related Repositories

- **LZ Vending Module**: `nathlan/terraform-azurerm-landing-zone-vending` v1.1.0
- **ALZ Orchestrator Config**: `nathlan/.github-private`
- **Reusable Workflows**: `nathlan/.github-workflows`