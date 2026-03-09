# Prerequisites Reference

This document outlines all Azure, GitHub, and network prerequisites required to deploy and operate the Azure Landing Zone Vending Machine in your target environment.

> **Migrating to `insight-agentic-platform-project`?** All references to `nathlan` in the source repository must be updated. See the [Migration Checklist](#migration-checklist) section below for a complete list of required changes.

---

## Azure Prerequisites

### 1. Billing Scope (Required)

**What:** The Azure billing scope under which new subscriptions will be created.

**Obtain from:**
- **EA (Enterprise Agreement):** Azure Portal → Subscriptions → Your EA subscription → Billing scope
- **MCA (Microsoft Customer Agreement):** Azure Portal → Cost Management → Billing scopes

**Value type:** Full resource ID (e.g., `/providers/Microsoft.Billing/billingAccounts/12345678/agreementType/EnterpriseAgreement` or `/providers/Microsoft.Billing/billingAccounts/12345678/billingProfiles/98765432/invoiceSections/87654321`)

**In terraform.tfvars:**
```hcl
subscription_billing_scope = "PLACEHOLDER_BILLING_SCOPE"  # Replace with actual scope
```

**Why:** Required by Terraform to create new Azure subscriptions as subscription aliases.

---

### 2. Management Group Hierarchy (Required)

**What:** The management group structure where landing zone subscriptions will be organized.

**Obtain from:** Azure Portal → Management Groups (or via Azure CLI: `az account management-group list`)

**Typical structure:**
```
Root Management Group (Tenant Root)
├── Corp (or Enterprise)
│   ├── Platform (for platform/hub resources)
│   └── Landing Zones
│       ├── Dev
│       ├── Test
│       └── Prod
├── Sandbox
└── Decommissioned
```

**Key value:** Management group ID (e.g., `Corp` or a UUID)

**In terraform.tfvars:**
```hcl
subscription_management_group_id = "Corp"  # Update with your management group ID
```

**Why:** The module associates each new landing zone subscription with a management group for centralized policy, governance, and billing management.

---

### 3. Hub Virtual Network (Optional but Recommended)

**What:** An existing hub/core virtual network in your organization for peering with landing zone spoke virtual networks.

**Obtain from:** Azure Portal → Virtual Networks → Hub/Core VNet → Copy Resource ID

**Expected value:** Full Azure resource ID
```
/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/virtualNetworks/{vnet-name}
```

**In terraform.tfvars:**
```hcl
hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID"  # Update with actual hub VNet ID
```

**Why:** Enables automatic VNet peering between landing zone spokes and your organization's hub for centralized routing, security, and shared services.

**If not using hub peering:**
- Set to `null` in terraform.tfvars
- Landing zone VNets will be created in isolation
- Manual peering can be configured later

---

### 4. Terraform State Storage (Required)

**What:** Azure Storage Account for storing Terraform state files.

**Who sets it up:** Your platform/DevOps team (before developers use this repository)

**Azure resources needed:**
- **Resource Group:** For organizing state storage
  - Example name: `rg-terraform-state`
  - Location: Centrally located region

- **Storage Account:** For state file blob storage
  - Example name: `stterraformstate` (must be globally unique)
  - Performance tier: Standard
  - Replication: LRS or GRS (recommended for production)
  - Access tier: Hot
  - Minimum TLS version: 1.2
  - Allow public access: Disabled (security best practice)

- **Storage Container:** For organizing state files
  - Example name: `alz-subscriptions`
  - Access level: Private

**Configuration for `terraform init`:**
```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=alz-subscriptions" \
  -backend-config="key=terraform.tfstate"
```

**Why:** Terraform state must be stored remotely for team collaboration. Local state files are not portable and cannot be shared.

---

### 5. Azure AD / Entra ID Service Principals (Required for OIDC)

**What:** Two separate User-Assigned Managed Identities (or App Registrations) for GitHub OIDC authentication.

**Why two identities:**
- **Plan identity:** Reader role (read-only access to resources)
- **Apply identity:** Owner/Contributor role (ability to modify resources)
- This follows the principle of least privilege

**For each identity, set up:**

#### Identity 1: Plan Identity
- **Name:** `id-alz-subscriptions-plan` (example)
- **Roles assigned:**
  - `Reader` scoped to the **billing scope** (required to read subscription properties)
  - `Reader` scoped to the **management group** (required to verify MG associations)
- **OIDC Federated Credential Configuration:**
  - **Issuer:** `https://token.actions.githubusercontent.com`
  - **Subject:** `repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:ref:refs/heads/main` (for main branch only)
  - OR: `repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:pull_request` (for PRs)
  - **Audience:** `api://AzureADTokenExchange`

#### Identity 2: Apply Identity
- **Name:** `id-alz-subscriptions-apply` (example)
- **Roles assigned:**
  - `Billing Account Contributor` scoped to the **billing scope** (can create subscriptions)
  - `Owner` or `Contributor` scoped to the **management group** (can manage subscriptions)
  - Additional roles as needed (e.g., `Network Contributor` if managing hub peering)
- **OIDC Federated Credential Configuration:**
  - **Issuer:** `https://token.actions.githubusercontent.com`
  - **Subject:** `repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:ref:refs/heads/main` (production branch only)
  - **Audience:** `api://AzureADTokenExchange`

**How to create (Azure CLI example):**

```bash
# Create Plan Identity
az identity create \
  --name id-alz-subscriptions-plan \
  --resource-group rg-terraform-state

# Get Plan Identity Client ID
PLAN_CLIENT_ID=$(az identity show \
  --name id-alz-subscriptions-plan \
  --resource-group rg-terraform-state \
  --query clientId -o tsv)

# Assign Reader role
az role assignment create \
  --assignee $PLAN_CLIENT_ID \
  --role "Reader" \
  --scope "/providers/Microsoft.Billing/billingAccounts/{billing-account-id}"

# Similar steps for Apply Identity with elevated roles
```

---

### 6. Network Allocation

**What:** A CIDR block to use as the base for automatic address space calculation.

**Obtain from:** Your network team (ensure it doesn't overlap with existing networks)

**Typical allocation:**
- **Base CIDR:** `10.100.0.0/16` (provides 256 subnets of /24 for landing zones)
- **Subnet sizing:** Each landing zone typically uses `/24` (256 addresses per zone)

**In terraform.tfvars:**
```hcl
azure_address_space = "10.100.0.0/16"
```

**Validation:**
- Must be valid CIDR notation (e.g., `10.100.0.0/16`)
- Must not overlap with:
  - Hub VNet address space
  - Existing on-premises networks (if hybrid-connected)
  - Any other Azure landing zones

**Why:** The module uses this base CIDR to automatically calculate and assign unique address spaces to each landing zone spoke VNet, preventing overlaps.

---

## GitHub Prerequisites

### 1. Repository Configuration

**What:** GitHub repository settings that must be configured before deployment.

**Access needed:**
- Repository owner or admin access
- Ability to create environments and secrets

**Required settings:**

| Setting | Value | Why |
|---------|-------|-----|
| **Repository visibility** | Private | Sensitive variables and infrastructure config should not be public |
| **Branch protection** | Require reviews on `main` | Enforce PR approval before landing zone deployments |
| **OIDC tokens** | Enabled | Required for Azure authentication without hardcoded credentials |

---

### 2. GitHub Secrets (Repository-level)

**What:** Secure storage for Azure authentication credentials.

**Create these secrets in:** GitHub → Your repository → Settings → Secrets and variables → Actions → **New repository secret**

| Secret Name | Value | Where to get |
|-------------|-------|-------------|
| `AZURE_CLIENT_ID_PLAN` | Plan identity client ID (UUID) | Azure Portal → Managed Identities → Your Plan Identity → Copy "Client ID" |
| `AZURE_CLIENT_ID_APPLY` | Apply identity client ID (UUID) | Azure Portal → Managed Identities → Your Apply Identity → Copy "Client ID" |
| `AZURE_TENANT_ID` | Azure AD tenant ID (UUID) | Azure Portal → Azure AD → Overview → Copy "Tenant ID" |
| `AZURE_SUBSCRIPTION_ID` | Management subscription ID (UUID) | Azure Portal → Subscriptions → Copy subscription ID |
| `GH_AW_GITHUB_TOKEN` | GitHub personal access token (PAT) | Create via GitHub → Settings → Developer settings → Personal access tokens → Generate new token |
| `GH_AW_AGENT_TOKEN` | GitHub personal access token (PAT) | Same as above (can be same as `GH_AW_GITHUB_TOKEN`) |

**Scopes needed for GitHub PATs:**
- `repo` (full control of private repositories)
- `workflow` (manage GitHub Actions workflows)
- `admin:org_hook` (if cross-org issue creation is needed)

---

### 3. GitHub Environment (production)

**What:** A GitHub environment for deployment approvals and protection rules.

**Create via:** GitHub → Your repository → Settings → Environments → **New environment** → Name: `production`

**Protection rules:**
- ✅ **Require reviewers:** Enable (configure approving users/teams)
- ✅ **Branch restriction:** Allow deployments from `main` only
- ✅**Required status checks:** None (or configure as needed)

**Why:** The `terraform-deploy.yml` workflow targets the `production` environment, which acts as a gate requiring human approval before Terraform apply.

---

### 4. OIDC Federated Credentials (GitHub Secrets Integration)

**What:** Azure trusts GitHub Actions to authenticate without hardcoded credentials.

**Setup:**

For each managed identity (plan and apply), add a federated credential:

1. **Azure Portal → Managed Identities → Your Identity → Federated credentials**
2. **Add credential:**
   - **Federated credential scenario:** `GitHub Actions deploying Azure resources`
   - **Organization:** `<YOUR_GITHUB_ORG>` (e.g., `insight-agentic-platform-project`)
   - **Repository:** `<YOUR_REPO_NAME>` (e.g., `azure-landing-zone-vending-machine`)
   - **Entity type:** Branch
   - **GitHub branch:** `main`
   - **Name:** `terraform-deploy` (descriptive name)

**Result:** When GitHub Actions runs on the `main` branch, Azure automatically validates the JWT and grants access without needing secrets.

---

### 5. Reusable Workflow Repository (Required)

**What:** Central `.github-workflows` repository for shared CI/CD workflows.

**Must exist in your GitHub org:** `insight-agentic-platform-project/.github-workflows`

**Must contain:** Reusable workflow file `.github/workflows/azure-terraform-deploy.yml` with inputs for:
- `environment` (GitHub environment name)
- `working-directory` (path to Terraform code)
- `terraform-version` (optional override)
- `azure-region` (optional override)

And secrets:
- `AZURE_CLIENT_ID_PLAN`, `AZURE_CLIENT_ID_APPLY`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

**If it doesn't exist:**
- Create the repository in `insight-agentic-platform-project`
- OR: Fork from the source org `nathlan/.github-workflows` if available
- OR: Create a minimal reusable workflow template

---

### 6. Private Terraform Module Repository (Required)

**What:** The private `terraform-azurerm-landing-zone-vending` module that provides all landing zone infrastructure logic.

**Must exist in your GitHub org:** `insight-agentic-platform-project/terraform-azurerm-landing-zone-vending`

**Status:** Currently sourced from `nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6`

**Setup options:**
1. **Fork the repository** from the source org (if permissions are available)
2. **Clone and mirror** into your org
3. **Mirror from GitHub Enterprise** if you have custom versions
4. **Copy source code** and create new repository (least preferred — loses upstream updates)

**After migrating:**
- Update `terraform/main.tf` to reference your organization:
  ```hcl
  module "landing_zones" {
    source = "github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
    # ...
  }
  ```

---

### 7. Cross-Repo Issue Automation Target (Required)

**What:** The `github-config` repository where landing zone completion notifications are created.

**Must exist in your GitHub org:** `insight-agentic-platform-project/github-config`

**Purpose:** When a landing zone is provisioned and the issue is closed, the dispatcher workflow automatically creates an issue in this repository to trigger workload repository creation.

**Minimum requirements:**
- Repository exists and is accessible
- Has an `Issues` feature enabled
- Allows issue creation via GitHub Actions

---

## Checklist

Use this checklist to verify all prerequisites are in place before deploying:

### Azure Setup
- [ ] **Billing scope obtained** and noted (will be used in terraform.tfvars)
- [ ] **Management group ID identified** (e.g., `Corp`)
- [ ] **Hub VNet resource ID obtained** (optional; set to `null` if not using hub peering)
- [ ] **Terraform state storage set up** (Resource Group, Storage Account, Container)
- [ ] **Plan identity created** with:
  - [ ] Client ID noted
  - [ ] Reader role assigned to billing scope
  - [ ] Reader role assigned to management group
  - [ ] OIDC federated credential configured
- [ ] **Apply identity created** with:
  - [ ] Client ID noted
  - [ ] Billing Account Contributor role assigned
  - [ ] Owner/Contributor role assigned to management group
  - [ ] OIDC federated credential configured
- [ ] **Network CIDR allocated** (e.g., `10.100.0.0/16`) with no overlaps confirmed

### GitHub Setup
- [ ] **Repository created** in target org (`insight-agentic-platform-project/azure-landing-zone-vending-machine`)
- [ ] **Repository secrets configured:**
  - [ ] `AZURE_CLIENT_ID_PLAN`
  - [ ] `AZURE_CLIENT_ID_APPLY`
  - [ ] `AZURE_TENANT_ID`
  - [ ] `AZURE_SUBSCRIPTION_ID`
  - [ ] `GH_AW_GITHUB_TOKEN`
  - [ ] `GH_AW_AGENT_TOKEN`
- [ ] **GitHub environment `production` created** with reviewers configured
- [ ] **OIDC setup validated** (federated credentials configured for both identities)
- [ ] **`.github-workflows` repository exists** in target org with `azure-terraform-deploy.yml`
- [ ] **`terraform-azurerm-landing-zone-vending` module forked/mirrored** into target org
- [ ] **`github-config` repository exists** in target org for issue handoff

### Pre-Deployment Configuration
- [ ] **`terraform.tfvars` updated** with:
  - [ ] `subscription_billing_scope` (replace placeholder)
  - [ ] `subscription_management_group_id` (update if different from `Corp`)
  - [ ] `hub_network_resource_id` (replace placeholder or set to `null`)
  - [ ] `github_organization` (update to `insight-agentic-platform-project`)
  - [ ] `azure_address_space` (verify no overlaps)
- [ ] **`terraform/main.tf` updated** to reference module in target org
- [ ] **`.github/workflows/terraform-deploy.yml` updated** to call reusable workflow from target org

---

## Migration Checklist

Complete this checklist when migrating from the source repository (`nathlan/alz-subscriptions`) to your target organization (`insight-agentic-platform-project/azure-landing-zone-vending-machine`):

### Step 1: Update Terraform Configuration

- [ ] **`terraform/main.tf`** — Update module source:
  ```hcl
  # OLD:
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
  
  # NEW:
  source = "github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
  ```

- [ ] **`terraform/terraform.tfvars`** — Update GitHub organization variable:
  ```hcl
  # OLD:
  github_organization = "nathlan"
  
  # NEW:
  github_organization = "insight-agentic-platform-project"
  ```

### Step 2: Update GitHub Workflow Files

- [ ] **`.github/workflows/terraform-deploy.yml`** — Update reusable workflow reference:
  ```yaml
  # OLD:
  uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
  
  # NEW:
  uses: insight-agentic-platform-project/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
  ```

### Step 3: Update Agentic Workflow Definition

- [ ] **`.github/workflows/alz-vending-dispatcher.md`** — Update 3 references:
  1. Line 32: Safe-output `target-repo` field:
     ```yaml
     # OLD:
     target-repo: "nathlan/github-config"
     
     # NEW:
     target-repo: "insight-agentic-platform-project/github-config"
     ```

  2. Line 102: Agent link in instructions:
     ```markdown
     # OLD:
     https://github.com/nathlan/alz-subscriptions/blob/main/.github/agents/alz-vending.agent.md
     
     # NEW:
     https://github.com/insight-agentic-platform-project/azure-landing-zone-vending-machine/blob/main/.github/agents/alz-vending.agent.md
     ```

  3. Multiple lines: Cross-repo issue targets (search for `nathlan/github-config` and replace with `insight-agentic-platform-project/github-config`)

### Step 4: Update Agent Files

- [ ] **`.github/agents/alz-vending.agent.md`** — Update 8 occurrences:
  - Line 17: Repository reference
  - Line 31: Repository reference in instructions
  - Line 50: Issue creation owner
  - Line 206: Example config `github_organization`
  - Line 516, 521: Template and org references
  - Line 555, 560: Cross-repo handoff targets
  - Line 578: Example `github_organization` value
  - Line 687: Example error message org reference

### Step 5: Update Prompt Files

- [ ] **`.github/prompts/alz-vending.prompt.md`** — Update 2 references:
  - Line 47: Repository reference for config fetch
  - Line 80: Issue creation owner

### Step 6: Verify and Test

- [ ] **Commit all changes** to `main` branch
- [ ] **Run `terraform init`** with backend config:
  ```bash
  cd terraform
  terraform init -backend-config="resource_group_name=rg-terraform-state" \
    -backend-config="storage_account_name=stterraformstate" \
    -backend-config="container_name=alz-subscriptions" \
    -backend-config="key=terraform.tfstate"
  ```
- [ ] **Run `terraform validate`** to ensure syntax is correct
- [ ] **Run `terraform plan`** (with Azure login) to verify no immediate errors
- [ ] **Test workspace:** Create test landing zone via `/landing-zone-vending` prompt
- [ ] **Verify PR creation and merge workflow** works end-to-end

---

## Troubleshooting

### "Provider not found" error

**Cause:** Terraform module source is inaccessible (network, permissions, or wrong organization)

**Fix:**
1. Verify the private module repository exists in your organization
2. Verify the GitHub token in secrets has `repo` scope
3. Verify network connectivity (if using private endpoints)

### "Access denied creating subscriptions"

**Cause:** Apply identity doesn't have sufficient permissions

**Fix:**
1. Verify Apply identity has `Billing Account Contributor` on the billing scope
2. Verify it has `Owner` or `Contributor` on the management group
3. Verify federated credential is configured correctly for the main branch

### "Management group not found"

**Cause:** `subscription_management_group_id` in terraform.tfvars is incorrect

**Fix:**
1. Verify the management group ID via Azure Portal
2. Ensure it matches the value in terraform.tfvars

### "CIDR overlap detected"

**Cause:** Proposed address space overlaps with existing networks

**Fix:**
1. Change `azure_address_space` to a range that doesn't overlap
2. Verify with network team that no other networks use the proposed CIDR
3. Check existing landing zones for address space conflicts

---

## Next Steps

1. **Complete all prerequisites** using the checklist above
2. **Update terraform.tfvars** with your Azure values
3. **Push to main branch** (after PR review)
4. **Run first deployment** to verify end-to-end workflow
5. **Proceed with Setup Guide** (docs/SETUP.md) for step-by-step instructions

For detailed setup steps, see [Setup Guide](SETUP.md).

For architecture explanation, see [Architecture Overview](ARCHITECTURE.md).
