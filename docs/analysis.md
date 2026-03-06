# Repository Analysis

> **Migrating to `insight-agentic-platform-project`?** All references to `nathlan` in this repository must be updated. See the [Migration Checklist](#org-specific-strings-requiring-migration) section below for a complete list.

## Repository Structure

```
alz-subscriptions/
├── .devcontainer/
│   └── devcontainer.json              # Development container with Terraform, Azure CLI, Copilot
├── .github/
│   ├── agents/                        # Custom Copilot coding agents
│   │   ├── alz-vending.agent.md                    # ALZ vending orchestrator (local + cloud)
│   │   ├── documentation-conductor.agent.md        # Documentation generator orchestrator
│   │   └── se-technical-writer.agent.md            # Technical writing specialist
│   ├── instructions/                  # Best practices and style guides
│   │   ├── github-actions-ci-cd-best-practices.instructions.md
│   │   ├── markdown.instructions.md
│   │   └── terraform.instructions.md
│   ├── prompts/                       # Interactive VS Code Copilot prompts
│   │   ├── alz-vending.prompt.md                   # Prompt: /landing-zone-vending
│   │   ├── architecture-blueprint-generator.prompt.md
│   │   ├── documentation-writer.prompt.md
│   │   ├── generate-documentation.prompt.md         # Prompt: /generate-documentation
│   │   └── readme-blueprint-generator.prompt.md
│   ├── workflows/                     # CI/CD automation
│   │   ├── alz-vending-dispatcher.md               # Agentic Workflow definition (source of truth)
│   │   ├── alz-vending-dispatcher.lock.yml         # Compiled Agentic Workflow (auto-generated)
│   │   ├── copilot-setup-steps.yml                 # GitHub Actions setup workflow
│   │   └── terraform-deploy.yml                    # Terraform plan/apply workflow (calls reusable)
│   ├── CODEOWNERS
│   └── aw/                            # Agentic Workflows runtime configuration
│       └── actions-lock.json
├── terraform/
│   ├── main.tf                        # Landing zone vending module call
│   ├── variables.tf                   # Input variable definitions (167 lines)
│   ├── terraform.tfvars               # Configuration map with example landing zones (238 lines)
│   ├── outputs.tf                     # Module outputs (59 lines)
│   ├── backend.tf                     # Azure Storage backend configuration
│   ├── versions.tf                    # Provider versions
│   └── checkov.yml                    # Security scanning configuration
├── docs/
│   ├── analysis.md                    # This file (Step 1 artifact)
│   ├── prerequisites.md               # Prerequisites checklist (Step 2 artifact)
│   ├── SETUP.md                       # Setup guide (Step 3 artifact)
│   ├── ARCHITECTURE.md                # Architecture overview (Step 4 artifact)
│   └── .artifact-state.json           # Generation metadata tracking
├── README.md                          # Repository entry point (Step 5 artifact)
└── .pre-commit-config.yaml            # Pre-commit hooks configuration
```

## Terraform Stack

| Component | Detail |
|-----------|--------|
| **Terraform Version** | ~> 1.10 |
| **Providers** | azapi (~> 2.5), modtm (~> 0.3), random (>= 3.3.2), time (>= 0.9, < 1.0) |
| **Backend Type** | Azure Storage (azurerm) |
| **Backend Location** | Resource Group: `rg-terraform-state`, Storage Account: `stterraformstate` |
| **State Container** | `alz-subscriptions` |
| **State Key** | `landing-zones/main.tfstate` |
| **Backend Auth** | OIDC enabled (`use_oidc = true`) |
| **Module Source** | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` |
| **Module Purpose** | Provisions Azure Landing Zone subscriptions with VNet peering, UMI, OIDC credentials, and budgets |

## Variables Inventory

| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `subscription_billing_scope` | string | N/A | **Yes** | Billing scope for subscription aliases (EA or MCA scope ID) |
| `subscription_management_group_id` | string | N/A | **Yes** | Management group ID for landing zone association |
| `hub_network_resource_id` | string | null | No | Hub VNet resource ID for peering (skip VNet peering if null) |
| `github_organization` | string | null | No | GitHub org name for federated credentials |
| `azure_address_space` | string | N/A | **Yes** | Base CIDR for automatic address space allocation (e.g., `10.100.0.0/16`) |
| `tags` | map(string) | `{}` | No | Common tags applied to all resources |
| `landing_zones` | map(object) | N/A | **Yes** | Map of landing zone configurations (5 examples in tfvars) |

### Landing Zone Object Structure

Each landing zone requires:
- **`workload`** — Workload identifier
- **`env`** — Environment: `dev`, `test`, or `prod`
- **`team`** — Team name
- **`location`** — Azure region (e.g., `australiaeast`)

Optional:
- **`subscription_devtest_enabled`** — Create as DevTest subscription (default: false)
- **`subscription_tags`** — Landing zone-specific tags
- **`dns_servers`** — Custom DNS servers for VNet
- **`spoke_vnet`** — VNet configuration with address spaces and subnets
- **`budget`** — Monthly budget with alert thresholds and email alerts
- **`federated_credentials_github`** — GitHub OIDC repository name

## Current Configuration (terraform.tfvars)

| Setting | Value | Status |
|---------|-------|--------|
| `subscription_billing_scope` | `PLACEHOLDER_BILLING_SCOPE` | **Placeholder** — Requires update |
| `subscription_management_group_id` | `Corp` | Real value |
| `hub_network_resource_id` | `PLACEHOLDER_HUB_VNET_ID` | **Placeholder** — Requires update |
| `github_organization` | `nathlan` | **Requires migration** to target org |
| `azure_address_space` | `10.100.0.0/16` | Real value |
| **Landing zones** | 5 example zones configured: `example-api-prod`, `graphql-dev`, `vending-demo-test`, `one-made-earlier-test`, `alz-vartika-test-test` | Real examples |

## GitHub Workflows

### 1. `terraform-deploy.yml` (Main Deployment Pipeline)

| Aspect | Detail |
|--------|--------|
| **Triggers** | Push to `main` (merge), PR to `main`, manual dispatch |
| **Type** | Child workflow (calls reusable parent) |
| **Parent Workflow** | `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main` |
| **Paths Watched** | `terraform/**`, `.github/workflows/terraform-deploy.yml` |
| **Permissions** | `contents: read`, `pull-requests: write`, `id-token: write`, `issues: write`, `security-events: write` |
| **Environment** | `production` (default) or manual input |
| **Secrets** | `AZURE_CLIENT_ID_PLAN`, `AZURE_CLIENT_ID_APPLY`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` |
| **Parameters** | `working-directory: terraform`, `azure-region: uksouth` |

### 2. `copilot-setup-steps.yml`

Setup steps workflow (implementation details in repository).

### 3. `alz-vending-dispatcher` (Agent Orchestration)

| Aspect | Detail |
|--------|--------|
| **Type** | GitHub Copilot Agent workflow (YAML + markdown) |
| **Triggers** | GitHub issues (opened, closed) |
| **Purpose** | Dispatches ALZ vending agent on issue creation and orchestrates cross-repo handoff |
| **Agent Assigned** | Custom `alz-vending` agent |
| **Permissions** | `actions: read`, `contents: read`, `issues: read` |
| **Safe Outputs** | GitHub token injection, `assign_to_agent`, `add_comment`, `create_issue` |
| **Linked Repo** | Creates issues in `nathlan/github-config` (for automation tracking) |

## External Dependencies

| Dependency | Source | Purpose | Migration Action |
|-----------|--------|---------|---|
| **Terraform Module** | `github.com/nathlan/terraform-azurerm-landing-zone-vending` (v1.0.6) | Private module providing landing zone provisioning logic | **Fork or mirror** into `<YOUR_GITHUB_ORG>` and update `main.tf` module source |
| **Reusable Workflow** | `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml` | Parent CI/CD workflow for Terraform plan/apply | **Create** `.github-workflows` repo in `<YOUR_GITHUB_ORG>` or **copy/mirror** the parent workflow into this repo's workflows directory |
| **Custom Coding Agent** | `alz-vending` (local file: `.github/agents/alz-vending.agent.md`) | Self-service landing zone provisioning orchestrator | **Local agent**, no immediate migration needed; update org refs in agent instructions |
| **Copilot Dispatcher** | `alz-vending-dispatcher` (local file: `.github/workflows/alz-vending-dispatcher.md`) | Automated agent assignment for landing zone issues | **Requires** GitHub Copilot organization subscription and agent registration |
| **Azure Providers** | Terraform Registry | Infrastructure provisioning | No action — public providers |

## GitHub Configuration Requirements

| Item | Detail |
|------|--------|
| **Repository Permissions** | `id-token: write` (for OIDC token exchange with Azure) |
| **Environment** | `production` (recommended with required reviewers for apply step) |
| **Secrets Required** | `AZURE_CLIENT_ID_PLAN`, `AZURE_CLIENT_ID_APPLY`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` |
| **Branch Protection** | Recommended on `main` (enforcement via workflow + environment rules) |
| **Copilot Access** | Requires GitHub Copilot organization subscription to use agents |

## Developer Experience

### Devcontainer Features

Pre-installed tools and extensions:
- **Terraform** (latest)
- **Docker** (built-in for local container testing)
- **Python 3.11**
- **Node.js** (LTS)
- **GitHub CLI** (`gh`)
- **Git** (latest from source)

VS Code Extensions:
- HashiCorp Terraform
- Python, Pylance
- GitHub Copilot, Copilot Chat
- GitHub Pull Request Manager

Configuration:
- Terraform auto-formatting on save
- Python linting enabled (pylint)
- GitHub Copilot integration enabled

### Interactive Prompts

Self-service prompts for repository setup and management:
- `/alz-vending` — Create landing zone request with validation
- `/generate-documentation` — Trigger documentation generation workflow
- Architecture and README blueprint generators

### Agent Ecosystem

Three custom agents for workflow automation:
- **`alz-vending`** — Self-service landing zone provisioning
- **`documentation-conductor`** — Repository documentation generation
- **`se-technical-writer`** — Technical documentation authoring

---

## Org-Specific Strings Requiring Migration

> ⚠️ **Critical for target org migration:** Replace all instances of `nathlan` with `<YOUR_GITHUB_ORG>` (`insight-agentic-platform-project` in your case).

| Location | Current Value | Replace With | Impact |
|----------|---------------|------|--------|
| `terraform/main.tf` (line 20) | `source = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6"` | `source = "github.com/<YOUR_GITHUB_ORG>/terraform-azurerm-landing-zone-vending?ref=v1.0.6"` | **High** — Module load will fail if not updated; requires forking module into target org |
| `terraform/terraform.tfvars` (line 13) | `github_organization = "nathlan"` | `github_organization = "<YOUR_GITHUB_ORG>"` | **High** — OIDC federated credentials will use wrong org; GitHub OIDC authentication will fail |
| `.github/workflows/terraform-deploy.yml` (line 53) | `uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main` | `uses: <YOUR_GITHUB_ORG>/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main` | **High** — Child workflow will fail to call parent; requires `.github-workflows` repo to exist in target org |
| `.github/workflows/alz-vending-dispatcher.md` (line 39) | `target-repo: "nathlan/github-config"` | `target-repo: "<YOUR_GITHUB_ORG>/github-config"` | **Medium** — Automation issues will be created in source org instead of target; optional, can be updated later |
| `.github/agents/alz-vending.agent.md` (line 83, 94) | `owner: nathlan`, `repo: alz-subscriptions` | `owner: <YOUR_GITHUB_ORG>`, `repo: <YOUR_REPO_NAME>` | **Medium** — Local agent will read/write from source org; required for full functionality |

---

## Summary

This repository is a **Terraform-based landing zone vending machine** designed for self-service Azure subscription provisioning. It uses:

1. **Map-based configuration** — Single `terraform.tfvars` file defines all landing zones
2. **Private module** — Depends on `nathlan/terraform-azurerm-landing-zone-vending` (must be forked)
3. **Reusable workflow** — Parent CI/CD in `nathlan/.github-workflows` (must be mirrored or copied)
4. **Copilot agents** — Custom agents for self-service provisioning and documentation
5. **OIDC authentication** — Dual identities for plan (Reader) and apply (Owner) phases
6. **Devcontainer** — Full Terraform + Python + Node.js development environment

**Before deployment:** Update all org references (`nathlan` → `insight-agentic-platform-project`) and provision the private module, reusable workflow, and Azure infrastructure.
| `umi_client_ids` | Landing zone key to UMI client ID map | Yes |
| `umi_principal_ids` | Landing zone key to UMI principal ID map | No |
| `umi_resource_ids` | Landing zone key to UMI resource ID map | No |
| `budget_resource_ids` | Landing zone key to budget resource ID map | No |
| `calculated_address_prefixes` | Auto-calculated prefix allocations from base CIDR | No |

## GitHub Workflows

| Workflow | Triggers | Secrets Used | Permissions |
|----------|----------|--------------|-------------|
| `.github/workflows/terraform-deploy.yml` | `push` to `main` (path-filtered), `pull_request` to `main` (path-filtered), `workflow_dispatch` | `AZURE_CLIENT_ID_PLAN`, `AZURE_CLIENT_ID_APPLY`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` | `contents: read`, `pull-requests: write`, `id-token: write`, `issues: write`, `security-events: write` |
| `.github/workflows/copilot-setup-steps.yml` | Push on workflow path, manual dispatch | None | Job-level `contents: read` |
| `.github/workflows/alz-vending-dispatcher.lock.yml` | Issue `opened` and `closed` events | `GH_AW_AGENT_TOKEN`, `COPILOT_GITHUB_TOKEN`, `GH_AW_GITHUB_TOKEN`, `GH_AW_GITHUB_MCP_SERVER_TOKEN`, `GITHUB_TOKEN` | Workflow-level `{}` plus job-level scoped permissions (includes `contents`, `issues`, `pull-requests`, `actions`, `discussions`) |

## Automation Assets

| Asset Type | Files | Notes |
|------------|-------|-------|
| Agents | `.github/agents/alz-vending.agent.md`, `.github/agents/documentation-conductor.agent.md`, `.github/agents/se-technical-writer.agent.md` | Defines vending orchestration, documentation orchestration, and writing specialist behavior |
| Prompts | `.github/prompts/alz-vending.prompt.md`, `.github/prompts/architecture-blueprint-generator.prompt.md`, `.github/prompts/documentation-writer.prompt.md`, `.github/prompts/readme-blueprint-generator.prompt.md` | Prompt templates for vending flow and documentation generation |

## External Dependencies

| Dependency | Source | Purpose |
|------------|--------|---------|
| Terraform landing-zone module | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | Provisions subscriptions, networking, budgeting, and identity |
| Reusable Terraform workflow | `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main` | Centralized plan/apply CI/CD pipeline |
| GitHub MCP server | `https://api.githubcopilot.com/mcp` | GitHub automation tool access for agents |
| gh-aw runtime | `github/gh-aw/actions/setup@v0.45.7` and generated lock workflow runtime | Agent dispatcher execution engine |
| Terraform providers | `Azure/azapi`, `Azure/modtm`, `hashicorp/random`, `hashicorp/time` | Core provider dependencies |
| Devcontainer feature images | `ghcr.io/devcontainers/features/*` | Local environment tooling (Terraform, Docker, Python, Node, Git, GH CLI) |
| terraform-docs binary | `https://github.com/terraform-docs/terraform-docs/releases/...` | Installed by `.devcontainer/setup.sh` for Terraform docs generation |

## Portability Findings

- The repository cannot deploy as-is until placeholders are replaced: `subscription_billing_scope` and `hub_network_resource_id`.
- The deployment workflow depends on external access to `nathlan/.github-workflows` and configured OIDC-based Azure identities.
- The dispatcher lock workflow is generated and should be changed through `.github/workflows/alz-vending-dispatcher.md` then recompiled.
