# Setup Guide: Azure Landing Zone Vending Machine

Deploy the Azure Landing Zone Vending Machine in your environment using this step-by-step guide.

---

## ⚠️ BEFORE YOU BEGIN — Migrate Org References

The source repository references `nathlan`. You **must** update these references to your target organization before any deployment:

| File | Lines/Values | Current | New Value | Status |
|------|--------------|---------|-----------|--------|
| `terraform/main.tf` | Module source | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | `github.com/<YOUR_GITHUB_ORG>/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | ⚠️ Required |
| `terraform/terraform.tfvars` | Line 14 | `github_organization = "nathlan"` | `github_organization = "<YOUR_GITHUB_ORG>"` | ⚠️ Required |
| `.github/workflows/alz-vending-dispatcher.md` | Agent config | All references to `nathlan` | `<YOUR_GITHUB_ORG>` | ⚠️ Required |

**Target org values:**
- `<YOUR_GITHUB_ORG>` = `insight-agentic-platform-project` (or your organization)
- `<TARGET_REPO>` = `azure-landing-zone-vending-machine`

**Do this first:**
```bash
# Fork the private Terraform module into your organization
# See Step 1 below for details

# Then proceed with the following steps
```

---

## Step 1: Fork the Terraform Module Repository

Before any other setup, fork the private terraform module into your GitHub organization.

**Action:**
1. In GitHub, navigate to the source module: `github.com/nathlan/terraform-azurerm-landing-zone-vending`
2. Click **Fork** → select `<YOUR_GITHUB_ORG>` as the destination
3. Verify the fork is complete

**Verification — You should see:**
- New repository at `github.com/<YOUR_GITHUB_ORG>/terraform-azurerm-landing-zone-vending`
- "Forked from nathlan/..." indicator on the fork page
- A read-only message confirming the fork inherits from the source

---

## Step 2: Verify Azure Prerequisites

Ensure all Azure prerequisites are available before proceeding.

| Prerequisite | How to Obtain | Value Type | Action |
|--------------|---------------|-----------|--------|
| **Billing Scope** | Azure Portal → Subscriptions → Billing scope | Resource ID | Copy value |
| **Management Group ID** | Azure Portal → Management Groups | UUID or name | Copy value |
| **Hub VNet Resource ID** (optional) | Azure Portal → Virtual Networks | Full resource ID | Copy value or note as unused |
| **Network CIDR** | Your network team | CIDR block (e.g., `10.100.0.0/16`) | Copy value |

**Verification — Run:**
```bash
az account list-locations --query '[0]' -o json
```
You should see: Azure CLI is authenticated and can list Azure resources.

---

## Step 3: Create Terraform State Storage (Azure)

Set up Azure Storage for Terraform state files.

**Action:**
```bash
# Set variables
RG_NAME="rg-terraform-state"
STORAGE_ACCT="stterraformstate"  # Must be globally unique
LOCATION="australiaeast"           # Your preferred region
CONTAINER_NAME="alz-subscriptions"

# Create resource group
az group create --name $RG_NAME --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCT \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

# Create container
az storage container create \
  --account-name $STORAGE_ACCT \
  --name $CONTAINER_NAME
```

**Verification — You should see:**
```bash
az storage account show --name $STORAGE_ACCT --resource-group $RG_NAME
```
Output confirms storage account exists with no public access enabled.

---

## Step 4: Create Azure OIDC Identities for GitHub

Create two managed identities for GitHub Actions OIDC.

**Action:**
```bash
# Set variables
PLAN_ID="id-alz-subscriptions-plan"
APPLY_ID="id-alz-subscriptions-apply"
BILLING_SCOPE="<YOUR_BILLING_SCOPE_ID>"
MGMT_GROUP="<YOUR_MANAGEMENT_GROUP_ID>"

# Create identities
az identity create --name $PLAN_ID --resource-group $RG_NAME
az identity create --name $APPLY_ID --resource-group $RG_NAME

# Get client IDs
PLAN_CLIENT=$(az identity show --name $PLAN_ID --resource-group $RG_NAME --query clientId -o tsv)
APPLY_CLIENT=$(az identity show --name $APPLY_ID --resource-group $RG_NAME --query clientId -o tsv)

# Assign roles (Plan = Reader, Apply = Contributor)
az role assignment create --assignee $PLAN_CLIENT --role Reader --scope $BILLING_SCOPE
az role assignment create --assignee $APPLY_CLIENT --role "Billing Account Contributor" --scope $BILLING_SCOPE
az role assignment create --assignee $APPLY_CLIENT --role Owner --scope "/providers/Microsoft.Management/managementGroups/$MGMT_GROUP"

# Add OIDC federated credentials
GITHUB_ORG="<YOUR_GITHUB_ORG>"
REPO="<TARGET_REPO>"

az identity federated-credential create \
  --name "github-main" \
  --identity-name $PLAN_ID \
  --resource-group $RG_NAME \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$REPO:ref:refs/heads/main"

az identity federated-credential create \
  --name "github-main" \
  --identity-name $APPLY_ID \
  --resource-group $RG_NAME \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$REPO:ref:refs/heads/main"
```

**Verification — Run:**
```bash
az identity federated-credential list --identity-name $PLAN_ID --resource-group $RG_NAME -o json
```
You should see one credential with issuer `https://token.actions.githubusercontent.com`.

---

## Step 5: Update terraform.tfvars with Your Values

Replace all placeholders in `terraform/terraform.tfvars`:

**Action:**
```bash
# Backup original
cp terraform/terraform.tfvars terraform/terraform.tfvars.backup

# Edit and replace:
# - PLACEHOLDER_BILLING_SCOPE → your actual billing scope
# - PLACEHOLDER_MANAGEMENT_GROUP_ID → your management group ID
# - PLACEHOLDER_HUB_VNET_ID → your hub VNet ID (or remove if not using)
# - nathlan → <YOUR_GITHUB_ORG>
# - example zone details with your landing zones
```

**Example updated values:**
```hcl
subscription_billing_scope       = "/providers/Microsoft.Billing/billingAccounts/12345678/agreementType/EnterpriseAgreement"
subscription_management_group_id = "Corp"
hub_network_resource_id          = "/subscriptions/abc123/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
github_organization              = "insight-agentic-platform-project"
azure_address_space              = "10.100.0.0/16"
```

**Verification — You should see:**
No validation errors when running `terraform validate` (next step).

---

## Step 6: Initialize Terraform with State Backend

Configure Terraform state backend for your Azure storage.

**Action:**
```bash
cd terraform

terraform init \
  -backend-config="resource_group_name=$RG_NAME" \
  -backend-config="storage_account_name=$STORAGE_ACCT" \
  -backend-config="container_name=$CONTAINER_NAME" \
  -backend-config="key=terraform.tfstate"
```

**Verification — You should see:**
- "Terraform has been successfully configured!"
- `.terraform/` directory created
- No errors about missing state files

---

## Step 7: Validate Terraform Configuration

Ensure all Terraform files are syntactically correct.

**Action:**
```bash
terraform validate
terraform fmt --check
```

**Verification — You should see:**
- "Success! The configuration is valid."
- No format warnings

---

## Step 8: Create GitHub Repository Secrets

Add Azure credentials as GitHub secrets for workflow authentication.

**Action — In GitHub repository settings:**
1. Navigate to **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `AZURE_PLAN_CLIENT_ID` | Output from `$PLAN_CLIENT` above |
| `AZURE_APPLY_CLIENT_ID` | Output from `$APPLY_CLIENT` above |
| `AZURE_TENANT_ID` | Your Azure tenant ID (`az account show --query tenantId -o tsv`) |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID (`az account show --query id -o tsv`) |

**Verification — You should see:**
Secrets listed in **Settings** → **Secrets and variables** → **Actions** (values hidden).

---

## Step 9: Commit Migration Changes

Commit the updated Terraform files to your repository.

**Action:**
```bash
git add terraform/terraform.tfvars terraform/main.tf .github/workflows/
git commit -m "chore: migrate org references from nathlan to <YOUR_GITHUB_ORG>"
git push origin main
```

**Verification — You should see:**
- Successful push to GitHub
- Updated files visible on GitHub repository main branch

---

## Step 10: Plan and Deploy First Landing Zone

Execute the Terraform configuration to plan and deploy.

**Action:**
```bash
cd terraform

# Generate plan
terraform plan -out=tfplan

# Review plan output for landing zones being created

# Apply configuration
terraform apply tfplan
```

**Verification — You should see:**
- Subscription IDs created
- Virtual networks provisioned
- Management identities created
- Budget alerts configured
- No errors in apply phase

**Expected outputs:**
```
subscription_ids = {
  "example-api-prod" = "sub-12345678-..."
  "graphql-dev" = "sub-87654321-..."
}
```

---

## Step 11: Verify Deployed Resources in Azure Portal

Confirm all landing zones are properly deployed.

**Action:**
1. Navigate to **Azure Portal** → **Subscriptions**
2. Look for your new landing zone subscriptions (e.g., `example-api-prod`, `graphql-dev`)
3. Verify each has:
   - Correct management group assignment
   - Virtual network created (if configured)
   - User-managed identity present
   - Budget alerts configured

**Verification commands:**
```bash
# List created subscriptions
terraform output subscription_ids

# Check virtual networks
terraform output virtual_network_resource_ids

# Verify identities
terraform output umi_client_ids
```

You should see: All outputs match your terraform.tfvars configuration.

---

## Troubleshooting

| Issue | Cause | Resolution |
|-------|-------|-----------|
| **"Unauthorized" error during terraform apply** | OIDC credentials not configured correctly | Re-verify Step 4 federated credentials with correct repo path |
| **"Module not found" error** | Terraform module fork not created | Ensure you forked `terraform-azurerm-landing-zone-vending` to your org (Step 1) |
| **"Invalid CIDR" error** | azure_address_space format incorrect | Ensure format is valid CIDR (e.g., `10.100.0.0/16`) |
| **"Billing scope not found"** | Incorrect billing scope ID | Copy exact ID from Azure Portal → Cost Management → Billing scopes |
| **"Management group not found"** | Wrong management group reference | Verify ID with `az account management-group list` |
| **Terraform state locked** | Previous apply interrupted | Run `terraform unlock` or check Azure storage container for `.terraform.lock.hcl` |

---

## Next Steps

After successful deployment:
1. Configure DNS servers for virtual networks (if needed)
2. Set up VNet peering to hub network (if hub_network_resource_id not set)
3. Add cost alerts by updating budget settings in terraform.tfvars
4. Deploy GitHub Actions workflows for automated provisioning
5. Configure team access controls in Azure via RBAC
