## Prerequisites Reference

## Azure Requirements

### Subscriptions & Billing

| Requirement | Detail from Repo | How to Obtain |
|-------------|------------------|---------------|
| Billing scope | `subscription_billing_scope` is required and currently set to `PLACEHOLDER_BILLING_SCOPE` in `terraform/terraform.tfvars` | Azure Portal → Cost Management + Billing → Billing scopes (EA/MCA) |
| Management group target | `subscription_management_group_id = "Corp"` | Confirm existing management group ID in tenant |
| Deployment subscription | `AZURE_SUBSCRIPTION_ID` secret is required by workflow for Terraform execution context | Use a management/platform subscription with backend + deployment access |

### Entra ID / Identity

| Requirement | Detail |
|-------------|--------|
| Plan identity | `AZURE_CLIENT_ID_PLAN` secret is used for plan stage; comments indicate Reader-level permissions |
| Apply identity | `AZURE_CLIENT_ID_APPLY` secret is used for apply stage; comments indicate Owner-level permissions |
| Tenant ID | `AZURE_TENANT_ID` secret required for both plan/apply login |
| OIDC federation | Workflow requires `id-token: write`; backend uses `use_oidc = true` |
| Optional workload federation | Landing zones can include `federated_credentials_github.repository` in `landing_zones` entries |

### Infrastructure Prerequisites

| Resource | Configuration in Repo | Purpose |
|----------|------------------------|---------|
| Terraform state resource group | `rg-terraform-state` | Stores remote state storage account |
| Terraform state storage account | `stterraformstate` | State backend |
| Terraform state container | `alz-subscriptions` | State blob container |
| Terraform state key | `landing-zones/main.tfstate` | Shared state file path |
| Hub virtual network | `hub_network_resource_id` variable (currently `PLACEHOLDER_HUB_VNET_ID`) | Spoke VNet peering target |
| Base address space | `azure_address_space = "10.100.0.0/16"` | Allocation pool for auto-calculated spoke prefixes |

### Network Requirements

| Setting | Current Value | Notes |
|---------|---------------|-------|
| Base CIDR | `10.100.0.0/16` | Must not overlap with existing enterprise address space |
| Spoke address declaration | Prefix-only (`/23`, `/24`, etc.) in each `landing_zones[*].spoke_vnet.ipv4_address_spaces[*].address_space_cidr` | Module derives concrete CIDRs from base range |
| Hub DNS override | Optional `dns_servers` list per landing zone | Leave empty to use Azure default behavior |

## GitHub Requirements

### Repository Secrets

| Secret Name | Used By | Purpose | Value Source |
|-------------|---------|---------|--------------|
| `AZURE_CLIENT_ID_PLAN` | `.github/workflows/terraform-deploy.yml` | OIDC auth for Terraform plan identity | Entra app registration or managed identity client ID |
| `AZURE_CLIENT_ID_APPLY` | `.github/workflows/terraform-deploy.yml` | OIDC auth for Terraform apply identity | Entra app registration or managed identity client ID |
| `AZURE_TENANT_ID` | `.github/workflows/terraform-deploy.yml` | Tenant for Azure login | Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | `.github/workflows/terraform-deploy.yml` | Subscription context for deployment | Azure subscription ID |
| `GH_AW_AGENT_TOKEN` | `.github/workflows/alz-vending-dispatcher.lock.yml` | Safe-output writes and GitHub API auth in dispatcher runtime | PAT/App token with required issue and repo access |
| `COPILOT_GITHUB_TOKEN` | `.github/workflows/alz-vending-dispatcher.lock.yml` | Copilot engine auth for agent runs | Copilot runtime token |
| `GH_AW_GITHUB_TOKEN` | `.github/workflows/alz-vending-dispatcher.lock.yml` | GitHub MCP access for read operations | PAT/App token |
| `GH_AW_GITHUB_MCP_SERVER_TOKEN` | `.github/workflows/alz-vending-dispatcher.lock.yml` | MCP server auth | PAT/App token |
| `GITHUB_TOKEN` | Auto-injected in workflow context | Standard GitHub Actions token | GitHub-managed |

### Repository Configuration

| Setting | Required Value | Why |
|---------|----------------|-----|
| Environment | `production` (workflow default input) | Parent reusable workflow expects named environment context |
| Workflow permissions | Must allow `id-token: write` and listed scopes in workflow | Required for OIDC token exchange and PR/status updates |
| Branch model | PRs into `main`; merges to `main` trigger apply | Matches workflow triggers (`pull_request` + `push`) |
| Reusable workflow access | Access to `nathlan/.github-workflows` | `terraform-deploy.yml` calls external reusable workflow |

## OIDC Federation Setup

1. Create two Azure identities (app registrations or UMI-backed workload identities): one for plan, one for apply.
2. Grant least privilege:
   - Plan identity: read-level permissions sufficient for plan and state read.
   - Apply identity: permissions needed to create subscriptions/resources and write state.
3. For each identity, add federated credentials that trust GitHub OIDC with:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Audience: `api://AzureADTokenExchange`
   - Subject pattern aligned to this repository and workflow usage (branch/environment scoping as required).
4. Store client IDs and tenant/subscription IDs in repository secrets.
5. Validate by running a pull request plan and confirming Azure login succeeds without static secrets.

## Required Roles and Scopes (Minimum Model)

| Identity | Scope | Typical Role |
|----------|-------|--------------|
| Plan identity | Management group + state storage scope | Reader (plus state read as needed) |
| Apply identity | Management group / billing scope / state storage scope | Contributor/Owner-equivalent privileges required by subscription vending and resource creation |

## Checklist

- [ ] Replace `PLACEHOLDER_BILLING_SCOPE` with actual EA/MCA billing scope ID.
- [ ] Replace `PLACEHOLDER_HUB_VNET_ID` with hub VNet resource ID (or intentionally set null strategy).
- [ ] Confirm management group ID `Corp` exists (or update variable value).
- [ ] Provision backend storage resources: `rg-terraform-state` / `stterraformstate` / `alz-subscriptions`.
- [ ] Create and configure separate OIDC identities for plan and apply.
- [ ] Configure repository secrets for Azure OIDC and dispatcher workflows.
- [ ] Ensure repository can call reusable workflow `nathlan/.github-workflows`.
- [ ] Create/verify `production` environment settings in repository.
- [ ] Validate base CIDR `10.100.0.0/16` does not overlap existing network allocations.
- [ ] Run a PR to confirm plan succeeds before first merge/apply.
