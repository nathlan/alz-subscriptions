# Azure Landing Zone Subscriptions

This repository manages Azure Landing Zone subscription provisioning using Infrastructure as Code (Terraform).

## Overview

This repository is a standard Azure Landing Zone workload repository that:
- **Provisions landing zone infrastructure** using Terraform
- **Calls the LZ vending module** (`terraform-azurerm-landing-zone-vending`)
- **Uses centralized CI/CD workflows** from `nathlan/.github-workflows`
- **Automates plan on PR** and apply on merge to main

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml   # Child workflow: plan on PR
│       └── terraform-apply.yml  # Child workflow: apply on merge
├── terraform/
│   ├── main.tf                  # Root module calling LZ vending module
│   ├── variables.tf             # Input variable definitions
│   ├── outputs.tf               # Module outputs
│   ├── backend.tf               # Azure Storage backend configuration
│   ├── terraform.tfvars         # Variable values for this landing zone
│   └── .terraform-version       # Terraform version constraint
└── README.md
```

## How It Works

This repository uses **child workflows** that call the reusable parent workflow from `nathlan/.github-workflows`:

1. **Make Changes**: Update `terraform/terraform.tfvars` or Terraform code in `terraform/`
2. **Create PR**: Open a pull request with your changes
3. **Automated Plan**: The `terraform-plan.yml` workflow runs, calling the reusable parent workflow to execute `terraform plan`
4. **Review**: Platform team reviews the plan output and configuration changes
5. **Merge**: PR merge triggers `terraform-apply.yml` workflow
6. **Deploy**: The reusable parent workflow executes `terraform apply` to provision infrastructure

### Workflow Architecture

Both workflows call the centralized parent workflow:
- **Parent Workflow**: `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main`
- **Child Workflows**: Local `.github/workflows/terraform-*.yml` files configure and invoke the parent
- **Benefits**: Consistent deployment logic, centralized updates, reduced duplication

## Usage

### Updating Landing Zone Configuration

To modify the landing zone infrastructure:

1. Edit `terraform/terraform.tfvars` with your desired configuration
2. Create a pull request with your changes
3. Review the Terraform plan output in the PR
4. Request review from the platform team
5. Merge to apply changes

### Manual Terraform Operations

For local testing or manual operations:

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes (use with caution)
terraform apply
```

**Note**: The CI/CD workflows use OIDC authentication. For local runs, ensure you have appropriate Azure credentials configured.

## Terraform State

State is stored in Azure Storage:
- **Resource Group**: `rg-terraform-state`
- **Storage Account**: `stterraformstate`
- **Container**: `alz-subscriptions`
- **State File**: `landing-zones/main.tfstate`

The backend configuration is defined in `terraform/backend.tf` and uses OIDC authentication.

## Required Secrets

GitHub Actions workflows require these repository secrets for OIDC authentication:
- `AZURE_CLIENT_ID` - Service principal client ID
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Management subscription ID

Configure these in: **Settings → Secrets and variables → Actions**

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
- See the reusable workflows documentation in `nathlan/.github-workflows`

## Related Repositories

- **LZ Vending Module**: `nathlan/terraform-azurerm-landing-zone-vending` - Private Terraform module for landing zone provisioning
- **Reusable Workflows**: `nathlan/.github-workflows` - Centralized GitHub Actions workflows for Terraform deployments
- **Workload Template**: `nathlan/alz-workload-template` - Template repository for creating new workload repos