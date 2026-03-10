# ALZ Vending Machine — Setup Guide

This guide walks you through deploying alz-vending-machine in the `insight-agentic-platform-project` organization. Follow each phase in order—migration from `nathlan` must be completed before any Azure deployment.

---

## Before You Begin: Migration Checklist

⚠️ **CRITICAL:** This repository was originally developed in the `nathlan` organization. Every reference to `nathlan` must be migrated to your organization (`insight-agentic-platform-project`) **before** attempting any deployment. Missing any step below will cause workflows to fail.

### Files That Reference `nathlan` — Must Update All

| File | Line(s) | Current Value | Update To | Why |
|------|---------|---------------|-----------|-----|
| `terraform/main.tf` | ~18 | `source = "github.com/nathlan/terraform-azure-landing-zone-vending` | `github.com/insight-agentic-platform-project/terraform-azure-landing-zone-vending` | Module source |
| `terraform/terraform.tfvars` | ~8 | `github_organization = "nathlan"` | `github_organization = "insight-agentic-platform-project"` | OIDC federated credentials |
| `.github/workflows/alz-vending-dispatcher.md` | ~23 | `target-repo: "nathlan/github-config"` | `target-repo: "insight-agentic-platform-project/github-config"` | Cross-repo issue creation |
| `.github/workflows/azure-terraform-cicd-caller.yml` | ~58 | `uses: nathlan/shared-assets@main` | `uses: insight-agentic-platform-project/shared-assets@main` | Reusable workflow |
| `.github/agents/alz-vending.agent.md` | multiple | All `nathlan/<repo>` references | `insight-agentic-platform-project/<repo>` | Repository queries |
| `.github/prompts/alz-vending.prompt.md` | multiple | All `nathlan/<repo>` references | `insight-agentic-platform-project/<repo>` | Agent instructions |

### Critical: Fork/Mirror These Repositories First

✅ Create these in `insight-agentic-platform-project` **before** proceeding:

1. **terraform-azure-landing-zone-vending** (private module)
   - Source: `nathlan/terraform-azure-landing-zone-vending`
   - Status: Private GitHub repository
   - Action: Fork or mirror to your organization

2. **shared-assets** (reusable workflows)
   - Source: `nathlan/shared-assets`
   - Contains: `.github/workflows/azure-terraform-cicd-reusable.yml`
   - Action: Fork or mirror to your organization (private)

3. **github-config** (automation target)
   - Source: `nathlan/github-config`
   - Action: Fork or create in your organization (private)

4. **alz-workload-template** (repository template)
   - Action: Create in your organization (can be based on `nathlan/alz-workload-template`)
   - Mark as **template repository** in GitHub settings

---

## What You'll Need

### Prerequisites (Detailed version: see [docs/prerequisites.md](prerequisites.md))

- [ ] GitHub CLI (`gh`) installed and authenticated
- [ ] Terraform >= 1.10 installed locally
- [ ] Azure CLI or Azure Portal access with permissions to:
  - Create App Registrations
  - Create/manage Azure Storage accounts
  - Assign Azure roles (Reader, Owner)
  - Create management groups (or reference existing ones)
- [ ] Access to create GitHub Environments and Actions secrets/variables
- [ ] Azure tenant ID (from Azure Portal > Azure Active Directory > Properties)
- [ ] Billing scope ARM ID and management group ID (from Azure Portal or billing admin)

---

## Phase 1: Repository Setup

### Step 1a: Fork External Repositories

For each repository below, fork it to your organization using GitHub UI:

1. Go to `https://github.com/nathlan/terraform-azure-landing-zone-vending`  
   Click **Fork** → Select `insight-agentic-platform-project` → Create

2. Go to `https://github.com/nathlan/shared-assets`  
   Click **Fork** → Select `insight-agentic-platform-project` → Create

3. Go to `https://github.com/nathlan/github-config`  
   Click **Fork** → Select `insight-agentic-platform-project` → Create

4. Go to `https://github.com/nathlan/alz-workload-template` (optional)  
   Use as reference to create `insight-agentic-platform-project/alz-workload-template`

**Verify:** Check each repository exists at `github.com/insight-agentic-platform-project/<repo-name>`

### Step 1b: Update Organization References

Clone this repository and update all `nathlan` references:

```bash
git clone https://github.com/insight-agentic-platform-project/alz-vending-machine.git
cd alz-vending-machine
```

Sed commands to automate replacements:

```bash
# Update main.tf
sed -i 's|github.com/nathlan/terraform-azure-landing-zone-vending|github.com/insight-agentic-platform-project/terraform-azure-landing-zone-vending|g' terraform/main.tf

# Update terraform.tfvars
sed -i 's|github_organization = "nathlan"|github_organization = "insight-agentic-platform-project"|g' terraform/terraform.tfvars

# Update workflows
sed -i 's|nathlan/shared-assets|insight-agentic-platform-project/shared-assets|g' .github/workflows/azure-terraform-cicd-caller.yml
sed -i 's|nathlan/github-config|insight-agentic-platform-project/github-config|g' .github/workflows/alz-vending-dispatcher.md

# Update agent and prompt files
sed -i 's|nathlan/|insight-agentic-platform-project/|g' .github/agents/alz-vending.agent.md
sed -i 's|nathlan/|insight-agentic-platform-project/|g' .github/prompts/alz-vending.prompt.md
```

**Verify:**
```bash
grep -r "nathlan" .
```
Should return no results. Commit changes:
```bash
git add .
git commit -m "Migration: Update org references from nathlan to insight-agentic-platform-project"
git push origin main
```

---

## Phase 2: Azure Identity & OIDC Setup

### Step 2a: Create App Registrations

**For Terraform state access:**
```bash
az ad app create --display-name "tf-state-storage-access" --output table
```
Note the **appId** (Client ID).

**For Terraform plan (Reader role):**
```bash
az ad app create --display-name "tf-plan-identity" --output table
```
Note the **appId**.

**For Terraform apply (Owner role):**
```bash
az ad app create --display-name "tf-apply-identity" --output table
```
Note the **appId**.

### Step 2b: Create Storage Account for Terraform State

```bash
RESOURCE_GROUP="my-resource-group"
STORAGE_ACCOUNT="tfstateXXXX"  # Must be unique globally, lowercase alphanumeric
CONTAINER_NAME="tfstate"

az storage account create --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --sku Standard_LRS
az storage container create --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT"
```

**Verify:** `az storage account show --name "$STORAGE_ACCOUNT"`

### Step 2c: Assign Azure Roles

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TF_PLAN_CLIENT_ID="<Client ID from tf-plan-identity>"
TF_APPLY_CLIENT_ID="<Client ID from tf-apply-identity>"

# Reader role for plan
az role assignment create --assignee "$TF_PLAN_CLIENT_ID" --role Reader --scope /subscriptions/"$SUBSCRIPTION_ID"

# Owner role for apply
az role assignment create --assignee "$TF_APPLY_CLIENT_ID" --role Owner --scope /subscriptions/"$SUBSCRIPTION_ID"
```

### Step 2d: Configure OIDC Federated Credentials

For each App Registration (plan and apply), create a federated credential:

```bash
REPO_NAME="alz-vending-machine"  # Your repository name
ORG="insight-agentic-platform-project"

# For tf-plan-identity
az ad app federated-credential create \
  --id "<tf-plan-identity appId>" \
  --parameters @- << EOF
{
  "name": "github-actions-plan",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$ORG/$REPO_NAME:environment:prod",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

# For tf-apply-identity
az ad app federated-credential create \
  --id "<tf-apply-identity appId>" \
  --parameters @- << EOF
{
  "name": "github-actions-apply",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$ORG/$REPO_NAME:environment:prod",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
```

**Verify:** In Azure Portal → App Registration → Certificates & Secrets → Federated credentials. You should see both credentials listed.

---

## Phase 3: GitHub Configuration

### Step 3a: Create Organization-Level Variables

These values are used by all repositories in your organization:

```bash
AZURE_TENANT_ID="<Your Azure tenant ID>"
AZURE_CLIENT_ID_TFSTATE="<tf-state-storage-access appId>"
BACKEND_STORAGE_ACCOUNT="tfstateXXXX"
BACKEND_CONTAINER="tfstate"

gh variable set AZURE_TENANT_ID --body "$AZURE_TENANT_ID" -o insight-agentic-platform-project
gh variable set AZURE_CLIENT_ID_TFSTATE --body "$AZURE_CLIENT_ID_TFSTATE" -o insight-agentic-platform-project
gh variable set BACKEND_STORAGE_ACCOUNT --body "$BACKEND_STORAGE_ACCOUNT" -o insight-agentic-platform-project
gh variable set BACKEND_CONTAINER --body "$BACKEND_CONTAINER" -o insight-agentic-platform-project
```

### Step 3b: Create Repository-Level Variables

Specific to the alz-vending-machine repository:

```bash
REPO="alz-vending-machine"
AZURE_CLIENT_ID_PLAN="<tf-plan-identity appId>"
AZURE_CLIENT_ID_APPLY="<tf-apply-identity appId>"
AZURE_SUBSCRIPTION_ID="<Your subscription ID>"

gh variable set AZURE_CLIENT_ID_PLAN --body "$AZURE_CLIENT_ID_PLAN" -R insight-agentic-platform-project/"$REPO"
gh variable set AZURE_CLIENT_ID_APPLY --body "$AZURE_CLIENT_ID_APPLY" -R insight-agentic-platform-project/"$REPO"
gh variable set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID" -R insight-agentic-platform-project/"$REPO"
```

### Step 3c: Create GitHub Actions Secrets

📌 **Note:** Use Personal Access Tokens (fine-grained) with minimal permissions.

```bash
# Set GH_AW_GITHUB_TOKEN (read-only: issues, contents)
gh secret set GH_AW_GITHUB_TOKEN -o insight-agentic-platform-project --body "<PAT>"

# Set GH_AW_AGENT_TOKEN (read-write: issues)
gh secret set GH_AW_AGENT_TOKEN -o insight-agentic-platform-project --body "<PAT>"
```

**Verify:**
```bash
gh variable list -o insight-agentic-platform-project
```
Should show all four org-level variables.

---

## Phase 4: Terraform State Configuration

### Step 4a: Update terraform/terraform.tfvars

Replace placeholder values with real Azure values:

```bash
cd terraform/

# Get your values and update the file
vim terraform.tfvars
```

Update these lines:
```hcl
subscription_billing_scope = "/subscriptions/XXXX.../billingAccounts/.../invoiceSections/..."  # From Azure Portal
subscription_management_group_id = "/providers/Microsoft.Management/managementGroups/my-mg"  # Your management group
hub_network_resource_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/hub-vnet"  # Optional; can remain null
github_organization = "insight-agentic-platform-project"  # Already updated in Phase 1b
```

### Step 4b: Validate Terraform Configuration

```bash
terraform init
terraform validate
```

**Verify:** Command completes without errors.

---

## Phase 5: First Deployment

### Step 5a: Test Local Agent

Return to repository root and open in VS Code:

```bash
cd ..
code .
```

In VS Code:
1. Open Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
2. Type `/alz-vending-machine`
3. Press Enter
4. Follow the prompts to submit a test landing zone request
5. Confirm submission

**Verify:** A new GitHub issue is created in `insight-agentic-platform-project/alz-vending-machine` with the `alz-vending` label.

### Step 5b: Monitor Agent Assignment

```bash
gh issue view <issue-number> -R insight-agentic-platform-project/alz-vending-machine
```

**Verify:** Issue shows assignee: **alz-vending** (Copilot agent)

### Step 5c: Monitor Workflow Execution

```bash
gh run list -R insight-agentic-platform-project/alz-vending-machine -w azure-terraform-cicd-caller.yml
```

**Verify:** Workflow run completes successfully (green checkmark). Check logs for:
- OIDC token exchange success
- Terraform init, plan, and apply outputs
- No authentication errors

---

## Phase 6: Troubleshooting

### Symptom: "Reusable workflow not found" in CI/CD logs

**Diagnosis:**
```bash
grep "uses:" .github/workflows/azure-terraform-cicd-caller.yml
```

**Fix:** If path shows `nathlan/shared-assets`, re-run Phase 1b migration steps. Commit and push.

### Symptom: OIDC token validation fails with "Token exchange failed"

**Diagnosis:**
```bash
az ad app federated-credential list --id "<appId>" --query "[0].subject"
```
Verify subject matches: `repo:insight-agentic-platform-project/alz-vending-machine:environment:prod`

**Fix:** If subject doesn't match, delete and recreate the federated credential (Step 2d).

### Symptom: "Issue not assigned to agent" or "Dispatcher workflow failed"

**Diagnosis:**
```bash
gh run list -R insight-agentic-platform-project/alz-vending-machine -w alz-vending-dispatcher.lock.yml -L 5
gh run view <run-id>
```

**Fix:**
- Verify `GH_AW_GITHUB_TOKEN` and `GH_AW_AGENT_TOKEN` secrets are set (Step 3c)
- Verify PAT permissions are correct (Issues: Read and write)
- Verify dispatcher workflow file exists at `.github/workflows/alz-vending-dispatcher.lock.yml`

### Symptom: Terraform plan/apply fails with "Unauthorized" for storage account

**Diagnosis:**
```bash
az role assignment list --assignee "<tf-plan-identity appId>" --query "[0]"
```

**Fix:** Ensure both identities have assignments:
- `tf-plan-identity` → Reader role
- `tf-apply-identity` → Owner role
Run Step 2c again if missing.

### Symptom: "Missing required variable terraform.tfvars"

**Diagnosis:**
```bash
grep -E "PLACEHOLDER|null" terraform/terraform.tfvars
```

**Fix:** Replace all placeholder values (Step 4a). For optional values like `hub_network_resource_id`, use `null` if unavailable.

---

## Next Steps

✅ Once all phases complete and the first deployment succeeds:

1. **Create a test landing zone** with the `/alz-vending-machine` agent
2. **Add more landing zones** in `terraform/terraform.tfvars`
3. **Configure budgets and alerts** for landing zones
4. **Document your landing zone standards** in your organization
5. **Train your teams** to use the `/alz-vending-machine` prompt

For detailed information on Terraform configuration, see [terraform/variables.tf](../terraform/variables.tf). For agent customization, see [.github/agents/alz-vending.agent.md](../.github/agents/alz-vending.agent.md).
