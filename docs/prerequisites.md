# Prerequisites Reference

> **Migrating to `insight-agentic-platform-project`?** Make sure to also complete the [Migration Checklist](#migration-checklist-for-org-change) section before deployment.

## Azure Requirements

### Subscriptions & Billing

| Requirement | Configuration in Repo | How to Obtain |
|-------------|----------------------|---------------|
| **Billing Scope** | `subscription_billing_scope = "PLACEHOLDER_BILLING_SCOPE"` in `terraform/terraform.tfvars` (line 12) | Azure Portal → Cost Management + Billing → Billing scopes. Requires EA or MCA enrolled account. Format: `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/billingSubscriptions/{billingSubscriptionId}` or `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}` |
| **Management Group** | `subscription_management_group_id = "Corp"` in `terraform/terraform.tfvars` (line 11) | Azure Portal → Management Groups. Confirm existing or create new management group. This is where all landing zone subscriptions will be associated. |
| **Deployment Subscription** | `AZURE_SUBSCRIPTION_ID` secret in GitHub (used for Terraform backend and deployment context) | Azure subscription ID (UUID format) with Owner/Contributor permissions over billing scope and management group. Typically a platform/management subscription. |

### Terraform State Infrastructure

| Resource | Configuration | Purpose | How to Create |
|----------|---------------|---------|---------------|
| **Resource Group** | Name: `rg-terraform-state` | Contains state storage account | `az group create --name rg-terraform-state --location uksouth` |
| **Storage Account** | Name: `stterraformstate`, SKU: Standard_LRS | Terraform state backend | `az storage account create --name stterraformstate --resource-group rg-terraform-state --location uksouth --kind StorageV2 --sku Standard_LRS` |
| **Storage Container** | Name: `alz-subscriptions` | State file location | `az storage container create --name alz-subscriptions --account-name stterraformstate` |
| **State Key** | Path: `landing-zones/main.tfstate` | State file reference (automatically used by terraform backend block) | Auto-created on first `terraform init` |
| **Backend Auth** | OIDC enabled (`use_oidc = true` in `terraform/backend.tf`) | No static secrets in state backend | Configured via OIDC identities (see Identity section) |

### Entra ID / Identity Management

Set up two separate Azure identities (app registrations or managed identities) for least-privilege access:

#### Plan Identity (Read/Query-only)

| Setting | Value | Notes |
|---------|-------|-------|
| **Name** | e.g., `ado-terraform-plan-<org>` | Distinct from apply identity |
| **Application ID / Client ID** | (from app registration) | Store in GitHub secret: `AZURE_CLIENT_ID_PLAN` |
| **Role Assignment** | `Reader` on management group | Scoped to management group containing target subscriptions |
| **State Access** | Read permissions on `stterraformstate` storage | Add Storage Blob Data Reader role on storage account |
| **Federated Credential (GitHub OIDC)** | See [OIDC Setup](#oidc-federation-setup) | Trusts GitHub Actions from this repo |

#### Apply Identity (Provisioning)

| Setting | Value | Notes |
|---------|-------|-------|
| **Name** | e.g., `ado-terraform-apply-<org>` | Distinct from plan identity |
| **Application ID / Client ID** | (from app registration) | Store in GitHub secret: `AZURE_CLIENT_ID_APPLY` |
| **Role Assignment** | `Contributor` or equivalent on management group + `Billing Account Contributor` on billing scope | Required to create subscriptions and manage resources |
| **State Access** | Read/Write permissions on `stterraformstate` storage | Add Storage Blob Data Contributor role on storage account |
| **Federated Credential (GitHub OIDC)** | See [OIDC Setup](#oidc-federation-setup) | Trusts GitHub Actions from this repo |

#### Tenant Information

| Secret | Value Source |
|--------|-------------|
| `AZURE_TENANT_ID` | Azure Portal → Entra ID → Tenant ID (UUID format) |
| `AZURE_SUBSCRIPTION_ID` | Azure Portal → Subscriptions → Subscription ID (UUID format) |

### Network Prerequisites

| Requirement | Current Value | Details |
|-------------|---------------|---------|
| **Base Address Space** | `azure_address_space = "10.100.0.0/16"` in `terraform/terraform.tfvars` (line 14) | Allocation pool for spoke VNets. **Must not overlap** with existing enterprise networks. Module auto-calculates spoke CIDRs from this base. |
| **Hub Virtual Network** | `hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID"` in `terraform/terraform.tfvars` (line 13) | Optional. If provided, landing zone spoke VNets will peer to hub. Format: `/subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/virtualNetworks/{vnet-name}` |
| **DNS Configuration** | Optional per landing zone | If `dns_servers` list is provided for a landing zone, those DNS servers override Azure defaults on that VNet. Leave empty to use Azure DNS. |
| **CIDR Validation** | Prefix-only notation (`/24`, `/23`, `etc.`) in `terraform.tfvars` | For each landing zone's `spoke_vnet.ipv4_address_spaces[*].address_space_cidr` and `subnet_prefixes` — module calculates actual CIDRs from base space. |

---

## GitHub Requirements

### Required Repository Secrets

All secrets must be configured in the repository (GitHub Settings → Secrets and variables → Actions):

| Secret Name | Purpose | Value | Scope |
|-------------|---------|-------|-------|
| **AZURE_CLIENT_ID_PLAN** | OIDC authentication for plan stage | Application/Client ID of plan identity | Used by `.github/workflows/terraform-deploy.yml` |
| **AZURE_CLIENT_ID_APPLY** | OIDC authentication for apply stage | Application/Client ID of apply identity | Used by `.github/workflows/terraform-deploy.yml` |
| **AZURE_TENANT_ID** | Azure AD tenant for login | Tenant ID (UUID) | Used by both plan and apply |
| **AZURE_SUBSCRIPTION_ID** | Subscription context for Terraform | Subscription ID (UUID) | Used for backend and deployment context |

### Repository Configuration

| Setting | Requirement | Impact If Not Set |
|---------|-------------|------------------|
| **Branch Protection** | On `main` branch: Require PRs, at least 1 approval | PRs bypass protection; apply runs occur without review |
| **Environment: production** | Create environment, optionally require reviewers for approval | Optional but recommended; enables human gate before apply |
| **Permissions** | Workflow permissions: `contents: read`, `pull-requests: write`, `id-token: write`, `issues: write`, `security-events: write` | Workflow will fail with permission denied errors |
| **Reusable Workflow Access** | Repository can call workflows from `<YOUR_GITHUB_ORG>/.github-workflows` | Workflow call will fail; child workflow cannot access parent |
| **Copilot Subscription** | Organization-level GitHub Copilot subscription (if using agents) | Agent workflows will not execute; manual-only workflow mode |

### Optional Dispatcher Workflow Secrets

If using the `alz-vending-dispatcher.md` workflow for agent automation:

| Secret Name | Purpose | Scope |
|-------------|---------|-------|
| **GH_AW_GITHUB_TOKEN** | GitHub API access for dispatcher workflow | Issues, repos toolset access |
| **GH_AW_AGENT_TOKEN** | Safe-output token for agent writes (issue comments, new issues) | Auto-injected by dispatcher runtime |
| **COPILOT_GITHUB_TOKEN** | Copilot engine authentication | Auto-injected by Copilot runtime |

> Note: These are optional if not using the Copilot agent workflow. Basic PR-based workflow (`terraform-deploy.yml`) only requires the four Azure secrets above.

---

## OIDC Federation Setup

### Prerequisites
- Two Azure app registrations (or managed identities) created
- Tenant ID and subscription ID obtained

### Step-by-Step Configuration

1. **Navigate to Azure Portal**
   - Entra ID → App registrations → `ado-terraform-plan-<org>` (plan identity)

2. **Add Federated Credential**
   - Click "Certificates & secrets" → "Federated credentials"
   - Click "+ Add credential"
   - Select "GitHub Actions deploying Azure resources"

3. **Configure Trust Policy**
   - **Organization:** `insight-agentic-platform-project` (or `<YOUR_GITHUB_ORG>`)
   - **Repository:** `azure-landing-zone-vending-machine` (or `<YOUR_REPO_NAME>`)
   - **Entity type:** Branch
   - **Branch name:** `main`
   - **Audience:** `api://AzureADTokenExchange`
   - **Issuer:** `https://token.actions.githubusercontent.com` (auto-filled)

4. **Repeat** for apply identity (`ado-terraform-apply-<org>`)

5. **Verify**
   ```bash
   # Test OIDC token generation locally
   gh auth token | jq -R 'split(".") | .[1] | @base64d | fromjson'
   ```

### Azure CLI Alternative

```bash
# Plan identity
az ad app federated-credential create \
  --id <plan-app-id> \
  --parameters '{"name":"GitHub-<YOUR_GITHUB_ORG>-<YOUR_REPO_NAME>","issuer":"https://token.actions.githubusercontent.com","subject":"repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:ref:refs/heads/main","audiences":["api://AzureADTokenExchange"]}'

# Apply identity (same, but different --id parameter)
az ad app federated-credential create \
  --id <apply-app-id> \
  --parameters '{"name":"GitHub-<YOUR_GITHUB_ORG>-<YOUR_REPO_NAME>","issuer":"https://token.actions.githubusercontent.com","subject":"repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:ref:refs/heads/main","audiences":["api://AzureADTokenExchange"]}'
```

---

## Implementation Checklist

Complete these steps in order before first deployment:

### 1. Azure Setup
- [ ] **Billing Scope**: Obtain EA/MCA billing scope ID; update `terraform.tfvars` line 12
- [ ] **Management Group**: Confirm management group ID; update `terraform.tfvars` line 11 if not `Corp`
- [ ] **Resource Group**: Create `rg-terraform-state`
- [ ] **Storage Account**: Create `stterraformstate` in resource group
- [ ] **Storage Container**: Create `alz-subscriptions` container in storage account
- [ ] **Plan Identity**: Create app registration `ado-terraform-plan-<org>`; grant Reader on management group + Storage Blob Data Reader on storage
- [ ] **Apply Identity**: Create app registration `ado-terraform-apply-<org>`; grant Contributor on management group + Billing Account Contributor + Storage Blob Data Contributor
- [ ] **OIDC Federated Credentials**: Add credentials to both app registrations with GitHub OIDC trust
- [ ] **Hub VNet** (optional): If peering required, create/identify hub VNet; update `terraform.tfvars` line 13
- [ ] **Network Validation**: Confirm `10.100.0.0/16` does not overlap existing address space

### 2. GitHub Setup
- [ ] **Branch Protection**: Enable on `main` (require PR, 1 approval)
- [ ] **Repository Secrets**: Configure all four Azure secrets (`AZURE_CLIENT_ID_PLAN`, `AZURE_CLIENT_ID_APPLY`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`)
- [ ] **Workflow Permissions**: Ensure `id-token: write` and other scopes are set
- [ ] **Environment: production**: Create if using environment-gated approval
- [ ] **Reusable Workflow Repo**: Ensure `<YOUR_GITHUB_ORG>/.github-workflows` exists and is accessible

### 3. Repository Configuration
- [ ] **Update Module Source** in `terraform/main.tf`: Change `github.com/nathlan/terraform-azurerm-landing-zone-vending` to `github.com/<YOUR_GITHUB_ORG>/terraform-azurerm-landing-zone-vending` (after forking the module)
- [ ] **Update github_organization** in `terraform/terraform.tfvars`: Change `nathlan` to `<YOUR_GITHUB_ORG>` (for OIDC credentials in landing zones)
- [ ] **Update Parent Workflow** in `.github/workflows/terraform-deploy.yml`: Change `nathlan/.github-workflows/...` to `<YOUR_GITHUB_ORG>/.github-workflows/...`
- [ ] **Test Run**: Push a branch with a small test landing zone; validate plan succeeds

### 4. First Deployment
- [ ] Create a PR adding a new landing zone to `terraform/terraform.tfvars`
- [ ] Review plan output in PR comments
- [ ] Merge to `main` (if using environment gate, approve deployment)
- [ ] Verify apply succeeds and subscription is created
- [ ] Check Terraform state in storage account

---

## Migration Checklist for Org Change

This checklist is **critical** if migrating this repository from the source organization (`nathlan`) to the target organization (`insight-agentic-platform-project`):

### Pre-Migration Planning
- [ ] Confirm target org slug: `insight-agentic-platform-project`
- [ ] Confirm target repo name: `azure-landing-zone-vending-machine`
- [ ] Identify who owns the target org's `.github-workflows` repository (or plan to create it)
- [ ] Identify who will manage the private Terraform module in the target org

### Module & Workflow Preparation
- [ ] **Fork private module** `nathlan/terraform-azurerm-landing-zone-vending` into `insight-agentic-platform-project` org
  - Mirror or import the repo as-is; no edits needed initially
  - Ensure it has the same structure and versions
- [ ] **Create or copy reusable workflow repository** `insight-agentic-platform-project/.github-workflows`
  - If already exists: verify parent workflow `azure-terraform-deploy.yml` exists and is callable
  - If creating: copy structure and workflows from source org

### File Updates (In Target Repo)
Update these files **before running any Terraform**:

1. **`terraform/main.tf`** (line ~20)
   - [ ] Change module source:
     ```terraform
     # FROM:
     source = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
     # TO:
     source = "github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
     ```

2. **`terraform/terraform.tfvars`** (line ~13)
   - [ ] Update organization name:
     ```terraform
     # FROM:
     github_organization = "nathlan"
     # TO:
     github_organization = "insight-agentic-platform-project"
     ```

3. **`.github/workflows/terraform-deploy.yml`** (line ~53)
   - [ ] Update reusable workflow call:
     ```yaml
     # FROM:
     uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
     # TO:
     uses: insight-agentic-platform-project/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
     ```

4. **`.github/workflows/alz-vending-dispatcher.md`** (line ~39, optional)
   - [ ] Update cross-repo automation target (if not needed, can skip):
     ```markdown
     # FROM:
     target-repo: "nathlan/github-config"
     # TO:
     target-repo: "insight-agentic-platform-project/github-config"
     ```

5. **`.github/agents/alz-vending.agent.md`** (lines ~83, ~94, optional)
   - [ ] Update agent's repo references (local agent only):
     ```markdown
     # FROM:
     owner: nathlan
     repo: alz-subscriptions
     # TO:
     owner: insight-agentic-platform-project
     repo: azure-landing-zone-vending-machine
     ```

### Verification
- [ ] Commit and push changes
- [ ] Update Azure app federated credentials if migrating between orgs (subject: `repo:insight-agentic-platform-project/...` instead of `repo:nathlan/...`)
- [ ] Run PR to trigger plan; verify no module source or workflow errors
- [ ] Merge and run apply if plan succeeds

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Module source not found | Module source points to `nathlan/...` in wrong org | Fork module into target org; update source in `terraform/main.tf` |
| Reusable workflow not found | Parent workflow not accessible or `.github-workflows` repo missing | Create `.github-workflows` repo in target org or mirror from source |
| OIDC login fails in plan | Federated credential not configured or org mismatch | Verify credential subject matches `repo:<TARGET_ORG>/<TARGET_REPO>:ref:refs/heads/main` |
| State lock timeout | Another plan/apply already in progress | Check recent workflow runs; wait for completion |
| Address space conflict | Base CIDR overlaps enterprise network | Update `azure_address_space` in `terraform.tfvars` to non-overlapping range |
