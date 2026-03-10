# Repository Analysis

## Overview

**alz-vending-machine** — A GitHub Agentic Workflow for self-service Azure Landing Zone provisioning. Teams submit landing zone requests via a local VS Code prompt (`/alz-vending-machine`), which creates a GitHub issue. A dispatcher workflow assigns a custom Copilot coding agent to the issue, which executes `terraform apply` and updates both the triggering issue and a cross-repo configuration repository.

---

## Repository Structure

```
alz-subscriptions/
├── .devcontainer/
│   ├── devcontainer.json          (Docker + Terraform + Python + Node + GitHub CLI)
│   └── setup.sh
├── .github/
│   ├── agents/
│   │   ├── alz-vending.agent.md                  (Operates in local and cloud contexts)
│   │   ├── documentation-conductor.agent.md      (DOCUMENTATION TOOLING - EXCLUDED)
│   │   └── se-technical-writer.agent.md          (DOCUMENTATION TOOLING - EXCLUDED)
│   ├── prompts/
│   │   ├── alz-vending-machine.prompt.md         (Local VS Code prompt for landing zone vending)
│   │   ├── generate-documentation.prompt.md      (DOCUMENTATION TOOLING - EXCLUDED)
│   │   ├── architecture-blueprint-generator.prompt.md  (DOCUMENTATION TOOLING - EXCLUDED)
│   │   ├── documentation-writer.prompt.md        (DOCUMENTATION TOOLING - EXCLUDED)
│   │   └── readme-blueprint-generator.prompt.md (DOCUMENTATION TOOLING - EXCLUDED)
│   ├── workflows/
│   │   ├── alz-vending-dispatcher.md             (GitHub Agentic Workflow [definition])
│   │   ├── alz-vending-dispatcher.lock.yml       (GitHub Agentic Workflow [compiled])
│   │   ├── azure-terraform-cicd-caller.yml       (Calls reusable Terraform CI/CD workflow)
│   │   └── copilot-setup-steps.yml               (Installs gh-aw CLI extension)
│   └── instructions/
│       ├── github-actions-ci-cd-best-practices.instructions.md
│       ├── markdown.instructions.md
│       └── terraform.instructions.md
├── terraform/
│   ├── main.tf                    (Single module: terraform-azure-landing-zone-vending)
│   ├── variables.tf               (Input variables for landing zones)
│   ├── outputs.tf                 (Terraform module outputs)
│   ├── versions.tf                (Provider versions)
│   ├── terraform.tfvars           (Map-based configuration for all landing zones)
│   ├── checkov.yml                (Security scanning config)
│   └── .tflint.hcl                (Terraform linting config)
├── sync/
│   └── .github/                   (Synced GitHub configuration)
├── README.md                       (Currently empty)
└── .gitignore, .gitattributes, etc.
```

---

## Terraform Stack

| Component | Value |
|-----------|-------|
| **Terraform Version** | `~> 1.10` |
| **State Backend** | Configured via reusable workflow + org/repo-level GitHub Actions variables (no local backend.tf) |
| **Module Source** | `github.com/nathlan/terraform-azure-landing-zone-vending?ref=v1.0.0` |
| **Module Type** | PRIVATE GitHub-hosted module (must be forked to target org) |

### Providers

| Provider | Source | Version | Purpose |
|----------|--------|---------|---------|
| azapi | Azure/azapi | ~> 2.5 | Azure API resource provisioning |
| modtm | Azure/modtm | ~> 0.3 | Module telemetry |
| random | hashicorp/random | >= 3.3.2 | Random ID generation |
| time | hashicorp/time | >= 0.9, < 1.0 | Time-based resource configuration |

---

## Variables Inventory

### Required Variables (No Defaults)

| Variable | Type | Description |
|----------|------|-------------|
| `subscription_billing_scope` | string | Billing scope ARM ID for subscription aliases (required to create new subscriptions) |
| `subscription_management_group_id` | string | Management group ID to associate all subscriptions with |
| `azure_address_space` | string | Base CIDR for automatic address space calculation (e.g., `10.100.0.0/16`) with validation |

### Optional Variables (With Defaults)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `hub_network_resource_id` | string | null | Azure resource ID of hub VNet for peering |
| `github_organization` | string | null | GitHub org name for federated OIDC credentials |
| `subscription_devtest_supported` | bool | false | If true, subscriptions with env=dev/test use DevTest workload type |
| `tags` | map(string) | {} | Common tags applied to all resources |

### Landing Zones Configuration

| Variable | Type | Description |
|----------|------|-------------|
| `landing_zones` | map(object) | Map of landing zones; each is a complete subscription with networking, identity, and optional budgets. See terraform/variables.tf for full schema. |

**Landing Zone Object Schema:**
```hcl
{
  workload                  = string           # Workload identifier (e.g., "payments-api")
  env                       = string           # Environment (dev, test, prod)
  team                      = string           # Owning team slug
  location                  = string           # Azure region
  
  subscription_tags         = optional(map(string))  # Extra subscription tags
  dns_servers               = optional(list(string)) # Custom DNS for VNet
  spoke_vnet                = optional(object)       # VNet config with subnets
  budget                    = optional(object)       # Budget with alert thresholds
  federated_credentials_github = optional(object)   # GitHub OIDC config
}
```

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `subscription_ids` | map(string) | Landing zone key → subscription ID |
| `subscription_resource_ids` | map(string) | Landing zone key → subscription ARM resource ID |
| `landing_zone_names` | map(string) | Landing zone key → auto-generated subscription name |
| `virtual_network_resource_ids` | map(string) | Landing zone key → VNet ARM resource ID |
| `resource_group_resource_ids` | map(string) | Landing zone key → resource group ARM resource ID |
| `umi_client_ids` | map(string) | Landing zone key → UMI client ID (SENSITIVE) |
| `umi_principal_ids` | map(string) | Landing zone key → UMI principal ID |
| `umi_resource_ids` | map(string) | Landing zone key → UMI ARM resource ID |
| `budget_resource_ids` | map(string) | Landing zone key → budget ARM resource ID |
| `tfplan_client_ids` | map(string) | Landing zone key → Terraform plan UMI client ID (SENSITIVE) |
| `tfapply_client_ids` | map(string) | Landing zone key → Terraform apply UMI client ID (SENSITIVE) |
| `calculated_address_prefixes` | map | Automatically calculated VNet address spaces |

---

## Current Configuration (terraform.tfvars)

### Status: INCOMPLETE — Placeholders Present

| Variable | Current Value | Placeholder? |
|----------|---|---|
| `subscription_billing_scope` | `PLACEHOLDER_BILLING_SCOPE` | ✅ YES |
| `subscription_management_group_id` | `PLACEHOLDER_MANAGEMENT_GROUP_ID` | ✅ YES |
| `hub_network_resource_id` | `PLACEHOLDER_HUB_VNET_ID` | ✅ YES |
| `github_organization` | `nathlan` | ⚠️ ORG-SPECIFIC (source org) — must update to `insight-agentic-platform-project` |
| `azure_address_space` | `10.100.0.0/16` | ❌ NO — real value |

### Landing Zones Configured

Six landing zones are defined in terraform.tfvars:
1. `example-api-prod` — Production API workload
2. `graphql-dev` — Development GraphQL workload
3. `vending-demo-test` — Test vending demo
4. `one-made-earlier-test` — Test workload
5. `alz-vartika-test-test` — Test workload
6. `nathans-test` — Test workload

---

## GitHub Workflows & Agentic Workflows

### Agentic Workflows

#### [Agentic Workflow] ALZ Vending Dispatcher (`.github/workflows/alz-vending-dispatcher.md`)

**Definition File:** [alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md)  
**Compiled File:** `alz-vending-dispatcher.lock.yml` (auto-generated; do not edit)  
**Engine:** Copilot  
**Invoked via:** GitHub issue events (opened, closed)

**Frontmatter Configuration:**
```yaml
triggers:    issues (types: opened, closed)
permissions: actions: read, contents: read, issues: read
tools:
  - github-token: ${{ secrets.GH_AW_GITHUB_TOKEN }}
  - toolsets: [issues, repos]
safe-outputs:
  - github-token: ${{ secrets.GH_AW_AGENT_TOKEN }}
  - assign-to-agent: alz-vending custom agent
  - add-comment: triggering issue
  - create-issue: target-repo "nathlan/github-config" (ORG-SPECIFIC)
```

**Behavior:**
- **Issue opened:** Assigns the `alz-vending` Copilot coding agent to the issue (no comment or cross-repo write)
- **Issue closed:** Posts completion comment to requester, then creates an issue in `nathlan/github-config` for workload repository provisioning

**Secrets Required:**
1. `GH_AW_GITHUB_TOKEN` — GitHub MCP read access (issues, repos toolsets)
   - Required permissions: **Contents: Read**, **Issues: Read**
2. `GH_AW_AGENT_TOKEN` — Safe-output write operations (assign-to-agent, add-comment, create-issue)
   - Required permissions: **Issues: Read and write** (at minimum; Copilot agent may need more for auto-PR creation)

---

### Standard Workflows

#### Copilot Setup Steps (`copilot-setup-steps.yml`)

**Purpose:** Installs the gh-aw (GitHub Agentic Workflows) CLI extension  
**Triggers:** Push to this workflow file, manual dispatch  
**Action:** `github/gh-aw/actions/setup-cli@v0.45.7`

---

#### Azure Terraform CI/CD (`azure-terraform-cicd-caller.yml`)

**Purpose:** Reusable workflow caller for Terraform plan/apply  
**Triggers:**
- Push to `main` (after PR merge)
- Pull request to `main`
- Manual dispatch

**Calls:** `nathlan/shared-assets/.github/workflows/azure-terraform-cicd-reusable.yml@main`  
**Reusable Workflow Repository:** [MUST EXIST] `nathlan/shared-assets` (ORG-SPECIFIC — must be forked to `insight-agentic-platform-project/shared-assets`)

**Permissions:**
```yaml
contents: read
pull-requests: write
id-token: write           # Required for Azure OIDC
issues: write
security-events: write
```

**GitHub Actions Variables** (parsed by reusable workflow, not passed as inputs):

| Variable | Scope | Purpose | Status |
|----------|-------|---------|--------|
| `AZURE_CLIENT_ID_TFSTATE` | Org-level | App Registration client ID for Terraform state access | NOT SET |
| `AZURE_TENANT_ID` | Org-level | Azure AD tenant ID | NOT SET |
| `BACKEND_STORAGE_ACCOUNT` | Org-level | Storage account name for Terraform state | NOT SET |
| `BACKEND_CONTAINER` | Org-level | Blob container for Terraform state | NOT SET |
| `AZURE_CLIENT_ID_PLAN` | Repo-level | Managed Identity client ID for `terraform plan` (Reader role) | NOT SET |
| `AZURE_CLIENT_ID_APPLY` | Repo-level | Managed Identity client ID for `terraform apply` (Owner role) | NOT SET |
| `AZURE_SUBSCRIPTION_ID` | Repo-level | Target Azure subscription ID for Terraform | NOT SET |

---

## GitHub Agents

### Agent Component Types

| Type | Context | File Path | Execution |
|------|---------|-----------|-----------|
| [Local agent] | VS Code IDE | `.github/agents/alz-vending.agent.md` | Runs in VS Code Copilot when `/alz-vending-machine` prompt is invoked |
| [Cloud coding agent] | GitHub Actions | `.github/agents/alz-vending.agent.md` (same file, different runtime) | Assigned by Dispatcher workflow to issues; runs in GitHub cloud |

### [Local + Cloud agent] ALZ Subscription Vending (`.github/agents/alz-vending.agent.md`)

**MCP Servers:** GitHub (all toolsets)  
**Model:** Claude Haiku 4.5  
**Tools:** vscode/askQuestions, execute, read, agent, edit, search, github/*

**Local Context (VS Code):**
1. Collects and validates user inputs via `ask_questions`
2. Reads existing landing zone config from `nathlan/alz-subscriptions` to check for conflicts
3. Creates a GitHub issue with `alz-vending` label once user confirms
4. Issue body contains validated inputs in structured table format

**Cloud Context (GitHub Copilot):**
1. Reads issue body to extract validated inputs
2. Phase 1: Determines PR context, modifies `terraform/terraform.tfvars`, creates or updates PR
3. Phase 2: Updates issue with PR link and deployment progress

**References to Org-Specific Values:**
- Repository: `nathlan/alz-subscriptions` (ORG-SPECIFIC)
- Config repository: `nathlan/github-config` (ORG-SPECIFIC)
- Workload template repository: `nathlan/alz-workload-template` (ORG-SPECIFIC)

---

## GitHub Prompts

### [Local agent] ALZ Vending Machine (`alz-vending-machine`)

**File Path:** [.github/prompts/alz-vending.prompt.md](.github/prompts/alz-vending.prompt.md)  
**Prompt Name (frontmatter):** `alz-vending-machine`  
**VS Code Command:** `/alz-vending-machine`  
**Agent:** ALZ Subscription Vending  
**Model:** Claude Haiku 4.5  

**Workflow:**
1. Gathers required inputs (workload name, env, region, team, device count, cost center, budget email)
2. Walks through optional settings (budget, repository name, subnet layout, extra tags)
3. Validates inputs and checks for conflicts
4. Presents confirmation summary
5. Creates GitHub issue with `alz-vending` label once confirmed

**Integration with Agentic Workflow:**
- Creates issue → Dispatcher workflow assigns `alz-vending` Copilot agent → Cloud agent executes

---

## External Dependencies

### Private Terraform Modules

| Module | Source | Status | Migration Action |
|--------|--------|--------|------------------|
| terraform-azure-landing-zone-vending | `github.com/nathlan/terraform-azure-landing-zone-vending?ref=v1.0.0` | Private GitHub repo | **REQUIRED:** Fork or mirror to `insight-agentic-platform-project/terraform-azure-landing-zone-vending` and update module source |

### External Repositories (Must Exist in Target Org)

| Repository | Purpose | Location | Migration Action |
|------------|---------|----------|------------------|
| shared-assets | Reusable GitHub Actions workflows | `nathlan/shared-assets` | **REQUIRED:** Fork or mirror to `insight-agentic-platform-project/shared-assets`; contains the parent `azure-terraform-cicd-reusable.yml` |
| github-config | Workload repository configuration | `nathlan/github-config` | **REQUIRED:** Fork or mirror to `insight-agentic-platform-project/github-config`; Dispatcher creates issues here for workload repo provisioning |
| alz-workload-template | Repository template for created workload repos | `nathlan/alz-workload-template` | **REQUIRED:** Available as a template repository in `insight-agentic-platform-project` org; used when provisioning workload repositories |

---

## Provider Authentication

### Azure Provider

**Authentication Method:** OIDC (OpenID Connect) via Azure App Registrations  
**Server:** No direct Azure provider block in this repo — authentication is managed by the reusable workflow

**Identity Strategy:**
- **Terraform Plan:** Separate Managed Identity with **Reader** role
  - Client ID from repo variable: `AZURE_CLIENT_ID_PLAN`
- **Terraform Apply:** Separate Managed Identity with **Owner** role
  - Client ID from repo variable: `AZURE_CLIENT_ID_APPLY`

**Federated Credential Configuration (Required):**
- Each identity requires a federated credential linking to GitHub Actions
- Environment: `prod` (or other GitHub environment)
- Repository: `insight-agentic-platform-project/alz-vending-machine` (or target repo name)
- Workflow: `Azure Terraform CI/CD`
- Subject pattern: `repo:<owner>/<repo>:environment:<environment>`

**Terraform State Backend:**
- **Type:** Azure Storage (blob)
- **Backend Variables (org-level):**
  - `AZURE_CLIENT_ID_TFSTATE` — App Registration for state storage access
  - `AZURE_TENANT_ID` — Directory ID
  - `BACKEND_STORAGE_ACCOUNT` — Storage account name
  - `BACKEND_CONTAINER` — Blob container name

---

## Org-Specific Strings Requiring Migration

All references to `nathlan` (source org) must be updated to `insight-agentic-platform-project` (target org):

| File | Location | Current Value | Replace With |
|------|----------|---|---|
| terraform/main.tf | Module source | `github.com/nathlan/terraform-azure-landing-zone-vending?ref=v1.0.0` | `github.com/insight-agentic-platform-project/terraform-azure-landing-zone-vending?ref=v1.0.0` |
| terraform/terraform.tfvars | github_organization | `nathlan` | `insight-agentic-platform-project` |
| .github/workflows/alz-vending-dispatcher.md (frontmatter) | safe-outputs create-issue target-repo | `nathlan/github-config` | `insight-agentic-platform-project/github-config` |
| .github/workflows/azure-terraform-cicd-caller.yml | reusable workflow uses | `nathlan/shared-assets/.github/workflows/azure-terraform-cicd-reusable.yml@main` | `insight-agentic-platform-project/shared-assets/.github/workflows/azure-terraform-cicd-reusable.yml@main` |
| .github/agents/alz-vending.agent.md | Multiple references | `nathlan/alz-subscriptions`, `nathlan/github-config`, `nathlan/alz-workload-template` | `insight-agentic-platform-project/alz-vending-machine`, `insight-agentic-platform-project/github-config`, `insight-agentic-platform-project/alz-workload-template` |
| .github/prompts/alz-vending.prompt.md | Repository reference | `nathlan/alz-subscriptions` | `insight-agentic-platform-project/alz-vending-machine` |

---

## Development Experience

### Devcontainer Configuration

**Base Image:** Ubuntu 24.04.3 LTS (via `mcr.microsoft.com/devcontainers/base:ubuntu`)

**Pre-installed Features:**
| Feature | Version |
|---------|---------|
| Docker CLI | latest (Docker-outside-of-Docker) |
| Terraform | latest |
| Python | 3.11 |
| Node.js | LTS |
| Git | latest |
| GitHub CLI | latest |

**VS Code Extensions:**
- HashiCorp Terraform (syntax, validation, formatting)
- Python + Pylance (type checking)
- GitHub Copilot + Copilot Chat
- GitHub Pull Requests

**Customizations:**
- Terraform formatting on save enabled
- Copilot coding agent UI integration enabled
- Python linting (pylint) enabled

**Post-Create Setup:** Runs `.devcontainer/setup.sh` to initialize the environment

---

## Security & Compliance

### Checkov Configuration

**Framework:** Terraform  
**Download External Modules:** Disabled (uses `terraform init` instead)  
**Skipped Checks:** CKV_TF_1 (allows version constraints instead of commit hashes)  
**Output:** CLI + SARIF  
**Soft Fail:** No (deployment fails on findings)

### TFLint Configuration

**File:** `terraform/.tflint.hcl` (present; specific rules not examined in this analysis)

---

## Architecture Pattern

### Map-Based Landing Zone Architecture

This repository follows a **map-based architecture** for scalability and maintainability:

- **Single Terraform Module Call:** `module "landing_zones"` in `main.tf` calls the Azure Landing Zone Vending module
- **Single Configuration File:** All landing zones defined in `terraform/terraform.tfvars` as a map
- **Dynamic Provisioning:** Each map entry describes one complete landing zone (subscription + networking + identity + optional budget)
- **Advantages:**
  - No per-landing-zone file duplication
  - Easy to add/remove landing zones (single map entry)
  - Consistent naming and resource tagging across all zones
  - Module handles all complexity (naming, address space calculation, OIDC setup)

### Self-Service Workflow

1. **User invokes `/alz-vending-machine` prompt** in VS Code
2. **Local agent collects and validates inputs** (workload name, env, region, team, device count, etc.)
3. **Local agent creates GitHub issue** with `alz-vending` label and structured input table
4. **Dispatcher workflow detects issue opened** → assigns `alz-vending` Copilot agent
5. **Cloud agent reads issue**, checks for conflicts, modifies `terraform/terraform.tfvars`, creates/updates PR
6. **User (or automation) merges PR** → `azure-terraform-cicd-caller.yml` triggers
7. **Reusable workflow runs `terraform apply`** with OIDC authentication
8. **Landing zone provisioned** → Cloud agent updates issue with completion status
9. **Dispatcher handles issue closed** → Posts completion comment, creates workload repo request in `github-config`

---

## Next Steps (Migration Readiness)

To adopt this repository to the `insight-agentic-platform-project` organization:

- [ ] Fork or mirror `github.com/nathlan/terraform-azure-landing-zone-vending` as a private repository in the target org
- [ ] Fork or mirror the reusable workflows repository (assumed to be at `nathlan/shared-assets`)
- [ ] Fork or mirror the `nathlan/github-config` repository
- [ ] Create or designate a repository template named `alz-workload-template` in the target org
- [ ] Update all org references in this repository (see Org-Specific Strings table above)
- [ ] Create Azure App Registrations and federated credentials for OIDC
- [ ] Set GitHub Actions variables (org-level and repo-level) as described in the Variables section
- [ ] Create GitHub Actions secrets for `GH_AW_GITHUB_TOKEN` and `GH_AW_AGENT_TOKEN`

**See `docs/prerequisites.md` for the complete prerequisites checklist.**
