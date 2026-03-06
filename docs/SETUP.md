## How to set up and run the first deployment

This guide takes you from a fresh repository to the first successful Azure
Landing Zone subscription deployment using the existing Terraform and GitHub
Actions configuration.

## Client-specific values to replace first

Replace these values before running deployment:

| Location | Current value in repo | Replace with |
|---|---|---|
| `terraform/terraform.tfvars` | `PLACEHOLDER_BILLING_SCOPE` | `<REPLACE_WITH_YOUR_BILLING_SCOPE>` |
| `terraform/terraform.tfvars` | `PLACEHOLDER_HUB_VNET_ID` | `<REPLACE_WITH_YOUR_HUB_VNET_RESOURCE_ID>` |
| `terraform/terraform.tfvars` | `subscription_management_group_id = "Corp"` | `<REPLACE_IF_YOUR_MG_IS_NOT_Corp>` |
| `terraform/terraform.tfvars` | `github_organization = "nathlan"` | `<REPLACE_WITH_YOUR_GITHUB_ORGANIZATION_IF_DIFFERENT>` |

## Step 1: Prepare Azure backend resources

Create or confirm the Terraform state backend resources defined in
`terraform/backend.tf`:

- Resource group: `rg-terraform-state`
- Storage account: `stterraformstate`
- Container: `alz-subscriptions`
- Key: `landing-zones/main.tfstate`

You should see these exact names available in Azure, matching the backend
configuration.

## Step 2: Prepare Azure identities for OIDC

Create two Azure identities for GitHub OIDC (plan/apply split), as required by
the workflow in `.github/workflows/terraform-deploy.yml`:

- Plan identity (`AZURE_CLIENT_ID_PLAN`) with read-level access for plan/state
- Apply identity (`AZURE_CLIENT_ID_APPLY`) with permissions needed for apply

Configure federated credentials with:

- Issuer: `https://token.actions.githubusercontent.com`
- Audience: `api://AzureADTokenExchange`

You should see both client IDs available and mapped to federated credentials for
this repository.

## Step 3: Update Terraform configuration values

Edit `terraform/terraform.tfvars` and replace the client-specific placeholders
from the table above. Keep required variables present, including:

- `subscription_billing_scope`
- `subscription_management_group_id`
- `azure_address_space`
- `landing_zones`

You should see no `PLACEHOLDER_...` values remaining in the tfvars file.

## Step 4: Configure GitHub repository secrets

In repository **Settings → Secrets and variables → Actions**, set the required
secrets used by deployment workflow:

- `AZURE_CLIENT_ID_PLAN`
- `AZURE_CLIENT_ID_APPLY`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

You should see all four secret names present in repository Actions secrets.

## Step 5: Confirm workflow deployment path and environment

The deployment workflow triggers on:

- Pull requests to `main` (plan)
- Pushes to `main` (apply)
- Optional manual dispatch (`production` default)

See `.github/workflows/terraform-deploy.yml`.

Ensure the `production` environment exists if your repository policies require
it (workflow default input is `production`).

You should see a workflow named **Terraform Deployment** in the Actions tab.

## Step 6: Run the first plan (PR validation)

Create a branch, commit your setup changes (typically in `terraform/`), and open
a pull request to `main`.

The workflow should run plan automatically due to PR trigger path filters.

You should see a successful PR workflow run for **Terraform Deployment**.

## Step 7: Run the first apply (merge deployment)

After plan review, merge the PR to `main`.

The workflow runs again on push to `main`, calling the reusable workflow
`nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main`
for apply.

You should see a successful post-merge workflow run with apply completed.

## Step 8: Verify deployed outputs

After apply succeeds, verify Terraform outputs from `terraform/outputs.tf`,
including:

- `subscription_ids`
- `landing_zone_names`
- `virtual_network_resource_ids`
- `budget_resource_ids`
- `calculated_address_prefixes`

You should see output values populated for your landing zone keys (for example,
keys defined under `landing_zones` in tfvars).

## Troubleshooting

### Workflow did not trigger

- **Cause:** Changed files outside workflow path filters.
- **Fix:** Ensure changes are under `terraform/**` or update
  `.github/workflows/terraform-deploy.yml`.

### OIDC login/authentication failure

- **Cause:** Missing/incorrect `AZURE_CLIENT_ID_PLAN`, `AZURE_CLIENT_ID_APPLY`,
  `AZURE_TENANT_ID`, or `AZURE_SUBSCRIPTION_ID`.
- **Fix:** Re-check secret values and federated credential issuer/audience.

### Backend initialization/state access failure

- **Cause:** Backend resources do not exist or identity lacks access.
- **Fix:** Confirm `rg-terraform-state`, `stterraformstate`,
  `alz-subscriptions` exist and identities can read/write state as needed.

### Terraform validation fails for landing zones

- **Cause:** Invalid `env` or CIDR prefix formats.
- **Fix:** Use `env` values only from `dev`, `test`, `prod`; use CIDR prefix
  format like `/24` and subnet prefixes like `/26` as defined in
  `terraform/variables.tf`.

### Apply fails before subscription provisioning

- **Cause:** Placeholder values not replaced.
- **Fix:** Replace billing scope and hub VNet placeholders in
  `terraform/terraform.tfvars` and re-run PR/merge.
