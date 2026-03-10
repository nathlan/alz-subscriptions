# Prerequisites Reference

## Overview

This repository provisions Azure Landing Zones via Terraform with GitHub Agentic Workflows for self-service automation. Before you can use this repository in the `insight-agentic-platform-project` organization, you must:

1. **Migrate all org-specific references** from `nathlan` to `insight-agentic-platform-project`
2. **Create or fork external repositories** that this repo depends on
3. **Create Azure identities and OIDC federated credentials** for Terraform
4. **Configure GitHub Actions secrets and variables**
5. **Update Azure subscription and management group references** from placeholders to real values

---

## Migration Checklist

Complete these steps **before** attempting any Terraform deployment:

> ⚠️ **CRITICAL:** Every item below must be completed. Missing any step will cause workflows to fail.

### 1. Repository Migration

- [ ] **Fork/mirror the private Terraform module** to your organization:
  - Source: `github.com/nathlan/terraform-azure-landing-zone-vending`
  - Target: Create as `insight-agentic-platform-project/terraform-azure-landing-zone-vending` (private)
  - Update reference in [terraform/main.tf](terraform/main.tf) line 18

- [ ] **Fork/mirror the reusable workflows repository** to your organization:
  - Source: `nathlan/shared-assets` (contains `azure-terraform-cicd-reusable.yml`)
  - Target: Create as `insight-agentic-platform-project/shared-assets` (private)
  - Update reference in [.github/workflows/azure-terraform-cicd-caller.yml](.github/workflows/azure-terraform-cicd-caller.yml) line 58

- [ ] **Fork/mirror the GitHub configuration repository** to your organization:
  - Source: `nathlan/github-config`
  - Target: Create as `insight-agentic-platform-project/github-config` (private)
  - Update reference in [.github/workflows/alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md) frontmatter

- [ ] **Create or designate a repository template** in your organization:
  - Name: `alz-workload-template`
  - Mark as a template repository in GitHub settings
  - This is used by the `alz-vending` agent to provision workload repositories
  - Referenced in [.github/agents/alz-vending.agent.md](.github/agents/alz-vending.agent.md)

- [ ] **Update all org-specific references in this repository:**
  - File: [terraform/main.tf](terraform/main.tf) — Replace `nathlan` with `insight-agentic-platform-project` in module source
  - File: [terraform/terraform.tfvars](terraform/terraform.tfvars) line 8 — Replace `github_organization = "nathlan"` with `"insight-agentic-platform-project"`
  - File: [.github/workflows/alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md) — Update frontmatter `target-repo` (line 23)
  - File: [.github/workflows/azure-terraform-cicd-caller.yml](.github/workflows/azure-terraform-cicd-caller.yml) — Update `uses` (line 58)
  - File: [.github/agents/alz-vending.agent.md](.github/agents/alz-vending.agent.md) — Replace all `nathlan/` references with `insight-agentic-platform-project/`
  - File: [.github/prompts/alz-vending.prompt.md](.github/prompts/alz-vending.prompt.md) — Update owner/repo references

### 2. Azure Setup

#### Subscription and Management Group References

- [ ] **Update placeholder values in [terraform/terraform.tfvars](terraform/terraform.tfvars):**
  - Line 6: `subscription_billing_scope = "PLACEHOLDER_BILLING_SCOPE"` → Your actual billing scope ARM ID (e.g., `/subscriptions/...`)
  - Line 7: `subscription_management_group_id = "PLACEHOLDER_MANAGEMENT_GROUP_ID"` → Your management group ID (e.g., `/providers/Microsoft.Management/managementGroups/...`)
  - Line 8: `hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID"` → Your hub VNet ARM ID (e.g., `/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/...`)

#### Terraform State Storage

- [ ] **Create or prepare Azure Storage for Terraform state:**
  - Resource group name
  - Storage account name
  - Blob container name
  - Note these values — you'll set them as GitHub Actions variables below

- [ ] **Create an App Registration for state storage access:**
  - Display name: `tf-state-storage-access` (or similar)
  - Purpose: Authenticate to Azure Storage for Terraform state access
  - Note the **Client ID** (Application ID) — set as `AZURE_CLIENT_ID_TFSTATE` variable

#### OIDC Federated Credentials

- [ ] **Create an App Registration for Terraform plan (Reader role):**
  - Display name: `tf-plan-identity` (or similar)
  - Note the **Client ID** — set as repo variable `AZURE_CLIENT_ID_PLAN`
  - Create federated credential linking to GitHub Actions:
    - Issuer: `https://token.actions.githubusercontent.com`
    - Subject: `repo:insight-agentic-platform-project/<your-repo-name>:environment:prod`
    - Name: `github-actions-plan`

- [ ] **Create an App Registration for Terraform apply (Owner role):**
  - Display name: `tf-apply-identity` (or similar)
  - Note the **Client ID** — set as repo variable `AZURE_CLIENT_ID_APPLY`
  - Create federated credential linking to GitHub Actions:
    - Issuer: `https://token.actions.githubusercontent.com`
    - Subject: `repo:insight-agentic-platform-project/<your-repo-name>:environment:prod`
    - Name: `github-actions-apply`

- [ ] **Assign Azure roles to identities:**
  - Assign `tf-plan-identity` the **Reader** role on your target subscription
  - Assign `tf-apply-identity` the **Owner** role on your target subscription
  - (These can also be scoped to specific resource groups if preferred)

- [ ] **Note your Azure AD tenant ID:**
  - Required for OIDC provider configuration
  - Set as `AZURE_TENANT_ID` org variable below

---

## GitHub Configuration

### GitHub Actions Secrets

These secrets must be created in your GitHub organization so that workflows can authenticate to GitHub and assign agents.

| Secret Name | Required By | Purpose | How to Create |
|------------|-------------|---------|---|
| `GH_AW_GITHUB_TOKEN` | Agentic Workflow dispatcher | GitHub MCP read access (to read issues and repositories) | Create a fine-grained Personal Access Token (classic) with: **Issues: Read** + **Contents: Read**. Or create a GitHub App with read-only access to issues and contents. |
| `GH_AW_AGENT_TOKEN` | Agentic Workflow dispatcher | Safe-output write operations (to assign agents, post comments, create issues in github-config) | Create a fine-grained Personal Access Token (classic) with: **Issues: Read and write**. This token is used by the dispatcher to assign the Copilot agent, comment on issues, and create cross-repo issues in `github-config`. |

**Setting These Secrets:**
```bash
# In GitHub UI: Settings > Secrets and variables > Actions > New repository secret
# OR use GitHub CLI:
gh secret set GH_AW_GITHUB_TOKEN --body "<token-value>"
gh secret set GH_AW_AGENT_TOKEN --body "<token-value>"
```

### GitHub Actions Variables — Organization Level

These variables must be set **once at the organization level** and will be inherited by all repositories in the org.

| Variable | Value Source | Purpose |
|----------|---|---|
| `AZURE_CLIENT_ID_TFSTATE` | App Registration for state storage (from Azure setup above) | Client ID of the identity that can access Terraform state in Azure Storage |
| `AZURE_TENANT_ID` | Your Azure AD tenant | Directory ID for OIDC provider configuration |
| `BACKEND_STORAGE_ACCOUNT` | Azure Storage account name | Name of the storage account holding Terraform state |
| `BACKEND_CONTAINER` | Blob container name | Name of the container within the storage account (e.g., `tfstate`) |

**Setting These Variables:**
```bash
# In GitHub UI: Settings > Variables and secrets > Actions > New organization variable
# OR use GitHub CLI:
gh variable set AZURE_CLIENT_ID_TFSTATE --body "<value>"
gh variable set AZURE_TENANT_ID --body "<value>"
gh variable set BACKEND_STORAGE_ACCOUNT --body "<value>"
gh variable set BACKEND_CONTAINER --body "<value>"
```

### GitHub Actions Variables — Repository Level

These variables must be set **in this specific repository** (`insight-agentic-platform-project/alz-vending-machine` or your target repo name).

| Variable | Value Source | Purpose |
|----------|---|---|
| `AZURE_CLIENT_ID_PLAN` | App Registration for plan (Reader role) | Client ID of Managed Identity for Terraform plan operations |
| `AZURE_CLIENT_ID_APPLY` | App Registration for apply (Owner role) | Client ID of Managed Identity for Terraform apply operations |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | Target subscription ID for Terraform deployments |

**Setting These Variables:**
```bash
# In GitHub UI: Settings > Secrets and variables > Actions > Variables > New repository variable
# OR use GitHub CLI:
gh variable set AZURE_CLIENT_ID_PLAN --body "<value>" -R insight-agentic-platform-project/<repo-name>
gh variable set AZURE_CLIENT_ID_APPLY --body "<value>" -R insight-agentic-platform-project/<repo-name>
gh variable set AZURE_SUBSCRIPTION_ID --body "<value>" -R insight-agentic-platform-project/<repo-name>
```

### GitHub Environments

**Production Environment** (`prod`) may be required by your organization's security policy for deployment approval gates.

- [ ] **If your org uses branch protection or environment approval rules, create or confirm the `prod` environment exists:**
  - Settings > Environments > New environment name `prod` (if it doesn't exist)
  - Configure required reviewers or deployment branches as needed
  - The reusable workflow targets this environment for deployments

---

## Terraform Input Variables (Sensitive Values)

The following Terraform variables require values at apply time. They are **not stored in terraform.tfvars** (which is committed to git). Instead, provide them via one of these methods:

| Method | How |
|--------|-----|
| Environment variables | Set `TF_VAR_<variable_name>` before running terraform (e.g., `export TF_VAR_subscription_billing_scope="..."`) |
| `.auto.tfvars` file | Create `.gitignored` file with variables: `subscription_billing_scope = "..."` (local only, not committed) |
| `-var` flag | `terraform apply -var="subscription_billing_scope=..."`  |
| GitHub Actions workflow input | Reusable workflow may accept these as inputs |

### Variables Provided at Apply Time

| Variable | Type | Example | How to Obtain |
|----------|------|---------|---|
| `subscription_billing_scope` | string | `/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Billing/billingAccounts/.../billingProfiles/.../invoiceSections/...` | Azure Portal: Subscriptions > Cost Management > Properties, or ask your billing admin |
| `subscription_management_group_id` | string | `/providers/Microsoft.Management/managementGroups/my-mg` | Azure Portal: Management groups > Your Group > Properties → ID |

---

## Linked Repositories (Must Be Created)

### github-config

**Purpose:** Receives automated issues for workload repository configuration  
**Created By:** ALZ Vending Dispatcher when landing zone issues close  
**Required Contents:** None initially; the dispatcher will create issues here with repository creation requests

**Setup:**
- [ ] Create repository `insight-agentic-platform-project/github-config` (private)
- [ ] Create an automation/bot account with write permissions, or use a GitHub App
- [ ] The dispatcher will write issues here using the `GH_AW_AGENT_TOKEN` secret

### alz-workload-template

**Purpose:** Template for auto-generated workload repositories  
**Used By:** `alz-vending` agent when provisioning workload repositories  
**Required Contents:** Repository structure for workload projects (e.g., `main.tf`, `.github/workflows/`, CI/CD pipeline stubs, etc.)

**Setup:**
- [ ] Create or designate a repository as `insight-agentic-platform-project/alz-workload-template` (public or private)
- [ ] Mark it as a **template repository** in GitHub settings: Settings > Template repository ✓
- [ ] Add typical workload project files (documentation recommends having an example structure)

### shared-assets

**Purpose:** Contains reusable GitHub Actions workflows  
**Used By:** Terraform CI/CD caller workflow (`azure-terraform-cicd-caller.yml`)  
**Required File:** `.github/workflows/azure-terraform-cicd-reusable.yml`

**Setup:**
- [ ] Fork or create `insight-agentic-platform-project/shared-assets` (private)
- [ ] Include `.github/workflows/azure-terraform-cicd-reusable.yml` that:
  - Accepts `working-directory` input (defaults to `terraform/`)
  - Runs `terraform init`, `terraform validate`, `terraform plan`, and `terraform apply`
  - Uses OIDC for Azure authentication
  - References the GitHub Actions variables set at org level

---

## Full Prerequisites Checklist

### Phase 1: Org Migration

- [ ] Fork `nathlan/terraform-azure-landing-zone-vending` → `insight-agentic-platform-project/terraform-azure-landing-zone-vending`
- [ ] Fork `nathlan/shared-assets` → `insight-agentic-platform-project/shared-assets`
- [ ] Fork `nathlan/github-config` → `insight-agentic-platform-project/github-config`
- [ ] Create `insight-agentic-platform-project/alz-workload-template` (mark as template)
- [ ] Update org references in all files (see Migration Checklist section above)

### Phase 2: Azure Resources & Identities

- [ ] Identify or create Azure Storage account for Terraform state
- [ ] Create App Registration: `tf-state-storage-access` (note Client ID)
- [ ] Create App Registration: `tf-plan-identity` with Reader role (note Client ID)
- [ ] Create App Registration: `tf-apply-identity` with Owner role (note Client ID)
- [ ] Configure OIDC federated credentials for both plan and apply identities
- [ ] Note your Azure AD tenant ID
- [ ] Update `terraform/terraform.tfvars` with real Azure values:
  - `subscription_billing_scope`
  - `subscription_management_group_id`
  - `hub_network_resource_id`

### Phase 3: GitHub Secrets & Variables

**Organization Level:**
- [ ] Set `AZURE_CLIENT_ID_TFSTATE` variable (org level)
- [ ] Set `AZURE_TENANT_ID` variable (org level)
- [ ] Set `BACKEND_STORAGE_ACCOUNT` variable (org level)
- [ ] Set `BACKEND_CONTAINER` variable (org level)

**Repository Level:**
- [ ] Set `AZURE_CLIENT_ID_PLAN` variable (this repo)
- [ ] Set `AZURE_CLIENT_ID_APPLY` variable (this repo)
- [ ] Set `AZURE_SUBSCRIPTION_ID` variable (this repo)
- [ ] Create `GH_AW_GITHUB_TOKEN` secret (repo or org level; used by dispatcher)
- [ ] Create `GH_AW_AGENT_TOKEN` secret (repo or org level; used by safe-outputs)

**Environments:**
- [ ] Create or confirm `prod` environment exists (if required by your org's policies)

### Phase 4: Verification

- [ ] `git log` confirms all org reference changes are committed
- [ ] `terraform -version` shows >= 1.10 in devcontainer
- [ ] `gh auth status` confirms GitHub CLI auth in devcontainer
- [ ] Run `terraform validate` in `terraform/` directory (should complete without errors)
- [ ] Trigger test Terraform plan via GitHub Actions (push to PR or manual workflow dispatch)
- [ ] Test local agent: Run `/alz-vending-machine` prompt in VS Code—should prompt for inputs

---

## Troubleshooting

### Workflow: "GH_AW_* secret not found"

**Cause:** Secrets not set in GitHub  
**Fix:** Create the secrets using the GitHub CLI or UI (see GitHub Secrets section above)

### Workflow: "OIDC token failed validation" or "Unauthorized for Storage Account access"

**Cause:** OIDC federated credential misconfigured, or identity lacks permissions  
**Fix:**
- Verify federated credential subject matches: `repo:insight-agentic-platform-project/<repo>:environment:prod`
- Verify both plan and apply identities have correct roles (Reader vs Owner)
- Test OIDC manually: `az login --federated-token '<gh-token>' --username <client-id>`

### Workflow: "Reusable workflow not found" at `nathlan/shared-assets`

**Cause:** Repository path not updated to target org  
**Fix:** Update [.github/workflows/azure-terraform-cicd-caller.yml](.github/workflows/azure-terraform-cicd-caller.yml) line 58 to point to `insight-agentic-platform-project/shared-assets`

### Terraform: "Missing required variable" (e.g., `subscription_billing_scope`)

**Cause:** Placeholder value still in use, or environment variable not set  
**Fix:**
- Replace placeholders in `terraform/terraform.tfvars` with real values
- Or export `TF_VAR_subscription_billing_scope="..."` before running terraform

### Agent: Issue not assigned when created

**Cause:** Dispatcher workflow failed to assign agent (usually missing secrets or permissions)  
**Fix:**
- Check workflow run logs in GitHub Actions
- Verify `GH_AW_AGENT_TOKEN` secret has **Issues: Read and write** permissions
- Verify issue has the `alz-vending` label

---

## Next Steps

1. **Complete the checklist above** in order (org migration → Azure → GitHub → verify)
2. **Read [docs/SETUP.md](../SETUP.md)** for step-by-step deployment guide
3. **Test the local agent** by running `/alz-vending-machine` in VS Code
4. **Monitor your first landing zone request** via GitHub issue and GitHub Actions logs

---

## References

- **Agentic Workflow Documentation:** See [.github/workflows/alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md)
- **Agent Instructions:** See [.github/agents/alz-vending.agent.md](.github/agents/alz-vending.agent.md)
- **Terraform Configuration:** See [terraform/main.tf](terraform/main.tf), [terraform/variables.tf](terraform/variables.tf)
- **Analysis:** See [docs/analysis.md](analysis.md)
