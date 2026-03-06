## Setup Guide: Azure Landing Zone Vending Machine

This guide walks you through deploying the ALZ subscription vending machine for your organization. Follow each step in order to configure Azure infrastructure, identity management, GitHub repository, and deployment automation.

---

## Before You Begin: Source Organization References

This repository was originally configured for the `nathlan` organization. If you are migrating to a different organization, you **must** update all references listed below before proceeding with deployment.

| File | Current Value | Replace With | Impact |
|------|---------------|--------------|--------|
| `terraform/main.tf` (line 20) | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | `github.com/<YOUR_GITHUB_ORG>/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | Module source — Terraform will fail to fetch without correct module path |
| `terraform/terraform.tfvars` (line 14) | `github_organization = "nathlan"` | `github_organization = "<YOUR_GITHUB_ORG>"` | OIDC federated credentials — Landing zones will fail to authenticate to GitHub Actions |
| `.github/workflows/terraform-deploy.yml` (line 50) | `uses: nathlan/.github-workflows/...` | `uses: <YOUR_GITHUB_ORG>/.github-workflows/...` | Reusable workflow reference — Deployment pipeline will not execute without correct parent workflow |
| `.github/prompts/alz-vending.prompt.md` (line 67) | `owner: nathlan` | `owner: <YOUR_GITHUB_ORG>` | Agent workflow owner — Prompt-based issue creation will target wrong organization |

**For target organization `insight-agentic-platform-project`:**
- Replace all instances of `nathlan` with `insight-agentic-platform-project`
- Verify module source resolves to: `github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending`
- Update repository secrets to use the correct organization name

---

## Step 1: Set Up Azure Infrastructure

### Terraform State Backend

Terraform state management is handled by the **reusable pipeline** — this repository does not include a `backend.tf`. The reusable workflow in `<YOUR_GITHUB_ORG>/.github-workflows` configures the backend at runtime.

Consult the reusable pipeline documentation for state storage provisioning steps. Ensure the state backend infrastructure is in place before running the first deployment.

### Determine Required Azure Resource IDs

Gather these values from your Azure environment (needed for `terraform.tfvars`):

**Billing Scope ID:**
```bash
# List billing scopes accessible to your account
az billing account list --query "[].id" -o tsv

# For EA accounts (example format):
# /providers/Microsoft.Billing/billingAccounts/1234567890/billingSubscriptions/9876543210

# For MCA accounts:
# /providers/Microsoft.Billing/billingAccounts/1234567890
```

**Management Group ID:**
```bash
# List management groups
az account management-group list --output table

# You should have a management group where landing zone subscriptions will be placed
# Example: "Corp" or "landing-zones"
```

**Hub Virtual Network ID (optional, but recommended):**
```bash
# If you have an existing hub network for peering
az network vnet list --query "[].id" -o tsv

# Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Network/virtualNetworks/{vnet-name}
```

**Update `terraform/terraform.tfvars` with actual values:**
```hcl
subscription_billing_scope       = "/providers/Microsoft.Billing/billingAccounts/YOUR_BILLING_ID"
subscription_management_group_id = "Corp"  # or your management group name
hub_network_resource_id          = "/subscriptions/YOUR_SUB_ID/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub"
github_organization              = "insight-agentic-platform-project"  # Your target org
```

---

## Step 2: Set Up Entra ID and OIDC Identities

Create two separate Azure app registrations for least-privilege Terraform authentication:

### Create Plan Identity (Read-only)

```bash
PLAN_ID_NAME="ado-terraform-plan-alz"

# Create app registration
az ad app create --display-name $PLAN_ID_NAME

# Get application (client) ID
PLAN_CLIENT_ID=$(az ad app list --filter "displayName eq '$PLAN_ID_NAME'" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $PLAN_CLIENT_ID

# Assign Reader role on management group (scoped to landing zones)
MGMT_GROUP_ID="Corp"  # Your management group
az role assignment create \
  --assignee $PLAN_CLIENT_ID \
  --role "Reader" \
  --scope "/providers/Microsoft.Management/managementGroups/$MGMT_GROUP_ID"

# Grant read access to the state backend (consult reusable pipeline docs for scope)
# az role assignment create \
#   --assignee $PLAN_CLIENT_ID \
#   --role "Storage Blob Data Reader" \
#   --scope "<STATE_BACKEND_RESOURCE_ID>"

echo "Plan Identity Client ID: $PLAN_CLIENT_ID"
```

### Create Apply Identity (Provisioning)

```bash
APPLY_ID_NAME="ado-terraform-apply-alz"

# Create app registration
az ad app create --display-name $APPLY_ID_NAME

# Get application (client) ID
APPLY_CLIENT_ID=$(az ad app list --filter "displayName eq '$APPLY_ID_NAME'" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $APPLY_CLIENT_ID

# Assign Contributor role on management group
MGMT_GROUP_ID="Corp"
az role assignment create \
  --assignee $APPLY_CLIENT_ID \
  --role "Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/$MGMT_GROUP_ID"

# Assign Billing Account Contributor (required for subscription creation)
BILLING_SCOPE="/providers/Microsoft.Billing/billingAccounts/YOUR_BILLING_ID"
az role assignment create \
  --assignee $APPLY_CLIENT_ID \
  --role "Billing Account Contributor" \
  --scope "$BILLING_SCOPE"

# Grant read/write access to the state backend (consult reusable pipeline docs for scope)
# az role assignment create \
#   --assignee $APPLY_CLIENT_ID \
#   --role "Storage Blob Data Contributor" \
#   --scope "<STATE_BACKEND_RESOURCE_ID>"

echo "Apply Identity Client ID: $APPLY_CLIENT_ID"
```

### Create GitHub OIDC Federated Credentials

For each identity, establish federated credentials so GitHub Actions can authenticate without static secrets:

```bash
# Get your tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# For Plan Identity
PLAN_CLIENT_ID="YOUR_PLAN_CLIENT_ID"
az ad app federated-credential create \
  --id $PLAN_CLIENT_ID \
  --parameters '{
    "name": "github-actions-plan",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:insight-agentic-platform-project/azure-landing-zone-vending-machine:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For Apply Identity
APPLY_CLIENT_ID="YOUR_APPLY_CLIENT_ID"
az ad app federated-credential create \
  --id $APPLY_CLIENT_ID \
  --parameters '{
    "name": "github-actions-apply",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:insight-agentic-platform-project/azure-landing-zone-vending-machine:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**Verification:**
```bash
# List federated credentials for plan identity
az ad app federated-credential list --id $PLAN_CLIENT_ID

# Should show one entry with issuer "https://token.actions.githubusercontent.com"
```

---

## Step 3: Configure GitHub Repository Secrets

Store all Azure credentials as repository secrets. These enable OIDC authentication without exposing sensitive keys.

**In GitHub repository settings (Settings → Secrets and variables → Actions):**

| Secret Name | Value | How to Get |
|-------------|-------|----------|
| `AZURE_TENANT_ID` | Your Azure tenant UUID | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | Backend subscription UUID | `az account show --query id -o tsv` |
| `AZURE_CLIENT_ID_PLAN` | Plan identity app ID | From Step 2 output or `az ad sp list --filter "displayName eq 'ado-terraform-plan-alz'" --query "[0].appId" -o tsv` |
| `AZURE_CLIENT_ID_APPLY` | Apply identity app ID | From Step 2 output or `az ad sp list --filter "displayName eq 'ado-terraform-apply-alz'" --query "[0].appId" -o tsv` |

**Example command to set secrets (using GitHub CLI):**
```bash
gh secret set AZURE_TENANT_ID --body "00000000-0000-0000-0000-000000000000"
gh secret set AZURE_SUBSCRIPTION_ID --body "11111111-1111-1111-1111-111111111111"
gh secret set AZURE_CLIENT_ID_PLAN --body "22222222-2222-2222-2222-222222222222"
gh secret set AZURE_CLIENT_ID_APPLY --body "33333333-3333-3333-3333-333333333333"
```

### Set Up Branch Protection and Permissions

1. **Enable branch protection on `main`:**
   - Settings → Branches → Add rule for `main`
   - Require pull request reviews (at least 1)
   - Require status checks to pass before merging
   - Include administrators

2. **Set workflow permissions:**
   - Settings → Actions → General → Workflow permissions
   - Select "Read and write permissions"
   - Allow GitHub Actions to create and approve pull requests

**Verification:**
- Attempt to push directly to `main` — should be blocked
- Draft a test PR to verify branch protection rules appear

---

## Step 4: Update Repository Files for Migration

If migrating from `nathlan` to `insight-agentic-platform-project`, update the following files:

### Update terraform/main.tf (Module Source)

Replace the module source to point to your organization's private module:

```hcl
module "landing_zones" {
  source = "github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
  # ... rest of configuration
}
```

### Update .github/workflows/terraform-deploy.yml (Reusable Workflow Reference)

Update the workflow call to reference your organization's `.github-workflows` repository:

```yaml
  deploy:
    name: Deploy to Azure
    uses: insight-agentic-platform-project/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    # ... rest of configuration
```

### Update terraform/terraform.tfvars (GitHub Organization)

Set the organization to match your target:

```hcl
github_organization = "insight-agentic-platform-project"
```

### Update .github/prompts/alz-vending.prompt.md (Agent Workflow Owner)

If using agent workflows, update the issue creation owner:

```markdown
owner: insight-agentic-platform-project
repo: azure-landing-zone-vending-machine
```

**Verification after file updates:**
```bash
# Initialize Terraform (validates module source syntax)
cd terraform
terraform init -backend=false

# Should succeed without errors
```

---

## Step 5: First Deployment & Verification

Deploy the first set of landing zones to verify the entire pipeline works end-to-end.

### Initialize Terraform

```bash
cd terraform

# Initialize Terraform (backend is configured by the reusable pipeline at runtime)
terraform init

# Should complete with "Terraform has been successfully initialized"
```

### Validate and Plan Locally

```bash
# Validate Terraform syntax
terraform validate

# Plan the deployment (requires Azure credentials)
terraform plan -out=tfplan

# Review the plan output for:
# - Number of resources to create
# - Subscription creation requests
# - VNet and subnet creation
```

### Create a Pull Request with Example Landing Zone

1. Create a feature branch:
```bash
git checkout -b feature/initial-landing-zones
```

2. Example terraform.tfvars (with YOUR values):
```hcl
subscription_billing_scope       = "/providers/Microsoft.Billing/billingAccounts/YOUR_ID"
subscription_management_group_id = "Corp"
hub_network_resource_id          = "/subscriptions/YOUR_HUB_SUB/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
github_organization              = "insight-agentic-platform-project"
azure_address_space              = "10.100.0.0/16"

tags = {
  managed_by       = "terraform"
  environment_type = "production"
}

landing_zones = {
  example-api-prod = {
    workload = "example-api"
    env      = "prod"
    team     = "platform-engineering"
    location = "uksouth"
    subscription_tags = {
      cost_center = "CC-001"
      owner       = "platform-engineering"
    }
    spoke_vnet = {
      ipv4_address_spaces = {
        default_address_space = {
          address_space_cidr = "/24"
          subnets = {
            default = { subnet_prefixes = ["/26"] }
            app     = { subnet_prefixes = ["/26"] }
          }
        }
      }
    }
    budget = {
      monthly_amount             = 1000
      alert_threshold_percentage = 80
      alert_contact_emails       = ["platform@example.com"]
    }
    federated_credentials_github = {
      repository = "api-service-repo"
    }
  }
}
```

3. Commit and push:
```bash
git add terraform/terraform.tfvars
git commit -m "Initial landing zones configuration"
git push origin feature/initial-landing-zones
```

4. Open a pull request on GitHub. The `terraform-deploy.yml` workflow will:
   - Run `terraform plan` and post the plan as a PR comment
   - Wait for approval before proceeding

### Merge and Deploy

Once the PR is approved:
1. Merge the PR to `main`
2. The workflow automatically triggers `terraform apply`
3. Monitor the workflow run in GitHub Actions

**Verification of successful deployment:**

```bash
# Check subscription exists in management group
az account management-group entities list \
  --group-name "Corp" \
  --query "[?displayName contains 'example-api']"

# Check landing zone subscription
az account list --query "[?displayName contains 'example-api']"

# Verify subscription is associated with management group
SUBSCRIPTION_ID="YOUR_NEW_SUBSCRIPTION_ID"
az account management-group entities list \
  --group-name "Corp" \
  --query "[?name=='$SUBSCRIPTION_ID']"
```

**Check Terraform outputs:**
```bash
terraform output

# Should show outputs like:
# - subscription_id
# - subscription_name
# - tenant_id
# - identity information
# - vnet details
```

---

## Next Steps

After successful deployment:

1. **Validate landing zone access:** Log in with new subscription identity
2. **Test agent workflows:** Use `/alz-vending` prompt in Copilot to provision additional zones
3. **Configure budget notifications:** Ensure alert emails are received
4. **Customize tfvars:** Add additional landing zones based on your workload needs
5. **Set up monitoring:** Configure Azure Monitor for subscription health

For architectural details, see [docs/ARCHITECTURE.md](ARCHITECTURE.md).
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
- **Fix:** Confirm the state backend infrastructure is provisioned per the
  reusable pipeline documentation and identities have appropriate access.

### Terraform validation fails for landing zones

- **Cause:** Invalid `env` or CIDR prefix formats.
- **Fix:** Use `env` values only from `dev`, `test`, `prod`; use CIDR prefix
  format like `/24` and subnet prefixes like `/26` as defined in
  `terraform/variables.tf`.

### Apply fails before subscription provisioning

- **Cause:** Placeholder values not replaced.
- **Fix:** Replace billing scope and hub VNet placeholders in
  `terraform/terraform.tfvars` and re-run PR/merge.
