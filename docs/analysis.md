# Repository Analysis

## Executive Summary

This repository implements an **Azure Landing Zone Vending Machine** — a self-service platform for provisioning complete Azure Landing Zones (subscriptions with virtual networks, managed identities, budgets, and OIDC federation).

The codebase uses:
- **Terraform** for Azure infrastructure as code
- **GitHub Agentic Workflows** for automation and CI/CD
- **VS Code agents** for interactive provisioning requests
- **GitHub Copilot** for cloud-based execution

---

## Repository Structure

```
alz-subscriptions/
├── .devcontainer/                    # Dev container configuration
│   ├── devcontainer.json
│   └── setup.sh
├── .github/
│   ├── agents/                       # Copilot agent definitions
│   │   ├── alz-vending.agent.md      # Core landing zone vending agent
│   │   ├── documentation-conductor.agent.md # Doc generation orchestrator
│   │   └── se-technical-writer.agent.md  # Tech writer specialist
│   ├── instructions/                 # Codebase conventions
│   │   ├── github-actions-ci-cd-best-practices.instructions.md
│   │   ├── markdown.instructions.md
│   │   └── terraform.instructions.md
│   ├── prompts/                      # VS Code prompt files
│   │   ├── alz-vending.prompt.md     # User-facing landing zone request prompt
│   │   ├── generate-documentation.prompt.md
│   │   └── [4 other prompts]
│   ├── workflows/                    # GitHub Actions & Agentic Workflows
│   │   ├── alz-vending-dispatcher.md          # Agentic Workflow definition [source of truth]
│   │   ├── alz-vending-dispatcher.lock.yml    # Compiled GitHub Actions YAML [auto-generated]
│   │   ├── terraform-deploy.yml               # Child workflow calling reusable parent
│   │   └── copilot-setup-steps.yml            # Setup utility
│   └── aw/                           # Agentic workflow configuration
├── terraform/                        # Infrastructure as code
│   ├── main.tf                       # Module call (single landing-zone-vending module)
│   ├── variables.tf                  # Input variable definitions
│   ├── outputs.tf                    # Output exports
│   ├── versions.tf                   # Terraform version & provider constraints
│   ├── terraform.tfvars              # Configuration (with example landing zones)
│   ├── checkov.yml                   # Security scanning config
│   └── .tflint.hcl                   # Linter configuration
├── README.md                         # [NOT YET CREATED]
├── .gitignore
├── .gitattributes
├── .pre-commit-config.yaml
└── .terraform.d/
```

---

## Terraform Stack

| Component | Detail |
|-----------|--------|
| **Terraform Version** | `~> 1.10` (min 1.10, max <2.0) |
| **Required Providers** | azapi (~2.5), modtm (~0.3), random (≥3.3.2), time (≥0.9, <1.0) |
| **Module Source** | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` |
| **Module Type** | Private GitHub-hosted module (⚠️ **REQUIRES MIGRATION**) |
| **Backend** | Implicit (not configured in code — must be set via `terraform init -backend-config=...`) |
| **State File** | Not committed to repo (expected in remote Azure storage) |

### Module Responsibilities

The `terraform-azurerm-landing-zone-vending` private module provisions:
- Subscription creation and management group association
- Virtual network with optional hub peering and subnets
- User-managed identity (UMI) with OIDC federated credentials for GitHub Actions
- Role assignments for workload identity
- Budget with cost alerts and notification thresholds
- Auto-generated resource names following Azure naming conventions

---

## Input Variables

| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `subscription_billing_scope` | string | — | **YES** | Azure billing scope (EA or MCA) for subscription aliases |
| `subscription_management_group_id` | string | — | **YES** | Management group ID for subscription association |
| `hub_network_resource_id` | string | `null` | No | Azure resource ID of hub VNet for peering |
| `github_organization` | string | `null` | No | GitHub org name for OIDC federated credentials (e.g., `nathlan`) |
| `azure_address_space` | string | — | **YES** | Base CIDR for address space auto-calculation (e.g., `10.100.0.0/16`) — must pass validation regex |
| `tags` | map(string) | `{}` | No | Common tags applied to all resources |
| `landing_zones` | map(object) | — | **YES** | Map of landing zone configurations (see landing_zones schema below) |

### landing_zones Map Schema

Each key in `landing_zones` becomes a unique landing zone subscription. Each value is an object with:

**Required fields:**
- `workload` (string): Workload identifier (e.g., `example-api-prod`)
- `env` (string): Environment (`dev`, `test`, or `prod`)
- `team` (string): Owning team name (e.g., `platform-engineering`)
- `location` (string): Azure region (e.g., `australiaeast`, `uksouth`)

**Optional fields:**
- `subscription_devtest_enabled` (bool, default `false`): Create as DevTest subscription
- `subscription_tags` (map(string), default `{}`): Additional subscription tags
- `dns_servers` (list(string), default `[]`): Custom DNS servers for VNet
- `spoke_vnet` (object): Spoke VNet configuration with address spaces and subnets (omit to skip VNet creation)
- `budget` (object): Monthly budget amount, alert threshold %, alert emails
- `federated_credentials_github` (object): GitHub repository for OIDC (e.g., `{ repository = "example-api-repo" }`)

---

## Configuration (terraform.tfvars)

Current example values in `terraform.tfvars`:

| Setting | Current Value | Status | Notes |
|---------|---------------|--------|-------|
| `subscription_billing_scope` | `PLACEHOLDER_BILLING_SCOPE` | **Placeholder** | Must be replaced with actual billing scope ID |
| `subscription_management_group_id` | `PLACEHOLDER_MANAGEMENT_GROUP_ID` | **Placeholder** | Must be replaced with actual management group ID |
| `hub_network_resource_id` | `PLACEHOLDER_HUB_VNET_ID` | **Placeholder** | Must be replaced or omitted (optional) |
| `github_organization` | `nathlan` | **Real (Source Org)** | ⚠️ **REQUIRES MIGRATION** to `insight-agentic-platform-project` |
| `azure_address_space` | `10.100.0.0/16` | **Real** | Valid CIDR notation; adjust to match your network allocation |
| `landing_zones` | 2 example zones | **Examples** | Real configuration structure; shows `example-api-prod` and `graphql-dev` |

---

## Outputs

| Output | Type | Sensitivity | Purpose |
|--------|------|-------------|---------|
| `subscription_ids` | map(string) | — | Landing zone subscription IDs |
| `subscription_resource_ids` | map(string) | — | Full Azure resource IDs for subscriptions |
| `landing_zone_names` | map(string) | — | Auto-generated subscription names |
| `virtual_network_resource_ids` | map(string) | — | VNet resource IDs (when created) |
| `virtual_network_address_spaces` | map(string) | — | Calculated address spaces per zone |
| `resource_group_resource_ids` | map(string) | — | Resource group IDs |
| `umi_client_ids` | map(string) | **SENSITIVE** | User-managed identity client IDs (for OIDC) |
| `umi_principal_ids` | map(string) | — | UMI principal IDs (for role assignments) |
| `umi_resource_ids` | map(string) | — | UMI resource IDs |
| `budget_resource_ids` | map(string) | — | Budget resource IDs |
| `calculated_address_prefixes` | object | — | Auto-calculated VNet address prefixes |

---

## GitHub Workflows

### Standard GitHub Actions Workflow

| Workflow | File | Triggers | Purpose | Permissions |
|----------|------|----------|---------|-------------|
| **Terraform Deploy** | `.github/workflows/terraform-deploy.yml` | `push` to `main` (terraform/** path), `pull_request` to `main`, `workflow_dispatch` | Calls reusable parent workflow from `.github-workflows` repo for Terraform plan/apply | `contents:read`, `pull-requests:write`, `id-token:write`, `issues:write`, `security-events:write` |
| **Copilot Setup** | `.github/workflows/copilot-setup-steps.yml` | `push` to this file, `workflow_dispatch` | Installs gh-aw extension | `contents:read` |

### GitHub Agentic Workflows

| Workflow | Definition File | Compiled File | Engine | Triggers | Safe Outputs | Assigned Agent |
|----------|-----------------|---------------|--------|----------|--------------|----------------|
| **ALZ Vending Dispatcher** | `.github/workflows/alz-vending-dispatcher.md` [definition] | `.github/workflows/alz-vending-dispatcher.lock.yml` [compiled] | copilot | `issues.opened`, `issues.closed` | `assign-to-agent: alz-vending` (on open), `create-issue: nathlan/github-config` (on close) | `alz-vending` custom agent |

**Important:** The `.md` file is the source of truth containing YAML frontmatter and agent instructions. The `.lock.yml` is auto-generated by `gh aw compile` (DO NOT EDIT manually).

---

## GitHub Agents (Copilot Coding Agents)

| Agent | File | Context | Purpose | Tools | MCP Servers |
|-------|------|---------|---------|-------|-------------|
| **alz-vending** | `.github/agents/alz-vending.agent.md` | Local (VS Code) + Cloud (GitHub) | Orchestrates landing zone provisioning by collecting user inputs locally, validating, creating issues, and executing Terraform changes in cloud | `vscode/askQuestions`, `execute`, `read`, `agent`, `edit`, `search`, `github/*` | github-mcp-server (all toolsets) |
| **SE: Technical Writer** | `.github/agents/se-technical-writer.agent.md` | Cloud (GitHub) | Generates documentation (setup guides, architecture docs, README) via agent handoff from Documentation Conductor | `codebase`, `edit/editFiles`, `search`, `web/fetch` | — |
| **Documentation Conductor** | `.github/agents/documentation-conductor.agent.md` | Local (VS Code) | Master orchestrator for end-to-end documentation generation; validates artifact freshness, regenerates stale docs, auto-handoffs to Tech Writer | `vscode/askQuestions`, `read/*`, `agent`, `edit/createFile`, `search`, `web`, `todo`, `github/*` | — |

---

## VS Code Prompts

| Prompt | File | Command | Agent | Purpose |
|--------|------|---------|-------|---------|
| **Provision Azure Landing Zone** | `.github/prompts/alz-vending.prompt.md` | `/landing-zone-vending` | alz-vending | User-facing interactive prompt for collecting landing zone request inputs |
| **Generate Documentation** | `.github/prompts/generate-documentation.prompt.md` | `/generate-documentation` | documentation-conductor | Orchestrates end-to-end documentation generation |
| **Documentation Writer** | `.github/prompts/documentation-writer.prompt.md` | TBD | TBD | [Purpose TBD] |
| **Architecture Blueprint Generator** | `.github/prompts/architecture-blueprint-generator.prompt.md` | TBD | TBD | [Purpose TBD] |
| **README Blueprint Generator** | `.github/prompts/readme-blueprint-generator.prompt.md` | TBD | TBD | [Purpose TBD] |

**Note:** Read prompt `.md` file frontmatter to extract the `name:` field — this is the actual VS Code `/` command, not the filename.

---

## External Dependencies & Migration Requirements

### Private Terraform Module (⚠️ CRITICAL)

| Dependency | Current Source | Type | Status | Migration Action |
|------------|-----------------|------|--------|------------------|
| **terraform-azurerm-landing-zone-vending** | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | Private GitHub module | **Must be forked** | 1. Fork repo into `insight-agentic-platform-project` org. 2. Update module source in `terraform/main.tf` to `github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6` |

### Reusable Workflow Repository (⚠️ REQUIRED TO EXIST)

| Dependency | Current Source | Type | Status | Migration Action |
|------------|-----------------|------|--------|------------------|
| **.github-workflows** | `nathlan/.github-workflows` | Reusable workflows | **Must exist in target org** | 1. Create `.github-workflows` repo in `insight-agentic-platform-project`. 2. Include the `alpine-terraform-deploy.yml` reusable workflow (or equivalent). OR: Copy from source org if shared workflows are provided. |

### Cross-Repo Issue Handoff

| Dependency | Current Source | Type | Status | Migration Action |
|------------|-----------------|------|--------|------------------|
| **github-config** | `nathlan/github-config` | Automation target | **Must exist in target org** | Create or ensure `insight-agentic-platform-project/github-config` repo exists. This is the destination for auto-created issues by the dispatcher workflow when landing zones close. |

---

## Org-Specific Strings Requiring Migration

Every occurrence of `nathlan` (the source organization) must be replaced with your target organization slug.

### Terraform Files

| File | Line(s) | Current Value | Must Replace With | Type |
|------|---------|---------------|-------------------|------|
| `terraform/main.tf` | 18 | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | `github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6` | Module source |
| `terraform/terraform.tfvars` | 14 | `github_organization = "nathlan"` | `github_organization = "insight-agentic-platform-project"` | Variable value |

### GitHub Workflow Files

| File | Type | Current Value | Must Replace With | Details |
|------|------|---------------|--------------------|---------|
| `.github/workflows/terraform-deploy.yml` | workflow_call `uses:` | `nathlan/.github-workflows/.github/workflows/...` | `insight-agentic-platform-project/.github-workflows/.github/workflows/...` | Reusable workflow reference |
| `.github/workflows/alz-vending-dispatcher.md` | Agentic Workflow safe-outputs | `target-repo: "nathlan/github-config"` | `target-repo: "insight-agentic-platform-project/github-config"` | Issue creation target |
| `.github/workflows/alz-vending-dispatcher.md` | Agentic Workflow agent link | `https://github.com/nathlan/alz-subscriptions/blob/main/.github/agents/alz-vending.agent.md` | `https://github.com/insight-agentic-platform-project/azure-landing-zone-vending-machine/blob/main/.github/agents/alz-vending.agent.md` | Hardcoded link |
| `.github/workflows/alz-vending-dispatcher.md` | Agent instructions | References to `nathlan/github-config` (3+ times) | `insight-agentic-platform-project/github-config` | Cross-repo handoff targets |

### Agent Files

| File | Location | Current Value | Must Replace With | Type |
|------|----------|---------------|--------------------|------|
| `.github/agents/alz-vending.agent.md` | Line 17 | `**Repository:** nathlan/alz-subscriptions` | `**Repository:** insight-agentic-platform-project/azure-landing-zone-vending-machine` | Repo reference |
| `.github/agents/alz-vending.agent.md` | Line 31 | `from nathlan/alz-subscriptions via GitHub MCP` | `from insight-agentic-platform-project/azure-landing-zone-vending-machine via GitHub MCP` | Repo reference |
| `.github/agents/alz-vending.agent.md` | Line 50 | `owner: nathlan` | `owner: insight-agentic-platform-project` | Issue creation owner |
| `.github/agents/alz-vending.agent.md` | Line 206 | `github_organization = "nathlan"` | `github_organization = "insight-agentic-platform-project"` | Example config |
| `.github/agents/alz-vending.agent.md` | Line 516, 521 | `nathlan/alz-workload-template`, `Organization: nathlan` | `insight-agentic-platform-project/alz-workload-template`, `Organization: insight-agentic-platform-project` | Template & org references |
| `.github/agents/alz-vending.agent.md` | Line 555, 560 | `nathlan/github-config` | `insight-agentic-platform-project/github-config` | Cross-repo handoff |
| `.github/agents/alz-vending.agent.md` | Line 578 | `"nathlan"` in `github_organization` example | `"insight-agentic-platform-project"` | Example value |
| `.github/agents/alz-vending.agent.md` | Line 687 | `nathlan organization` example error | `insight-agentic-platform-project organization` | Example error message |

### Prompt Files

| File | Location | Current Value | Must Replace With | Type |
|------|----------|---------------|--------------------|------|
| `.github/prompts/alz-vending.prompt.md` | Line 47 | `from nathlan/alz-subscriptions` | `from insight-agentic-platform-project/azure-landing-zone-vending-machine` | Repo reference |
| `.github/prompts/alz-vending.prompt.md` | Line 80 | `owner: nathlan` | `owner: insight-agentic-platform-project` | Issue creation owner |

### Agentic Workflow Definition

| File | Location | Current Value | Must Replace With | Type |
|------|----------|---------------|--------------------|------|
| `.github/workflows/alz-vending-dispatcher.md` | Line 32 | `target-repo: "nathlan/github-config"` | `target-repo: "insight-agentic-platform-project/github-config"` | Safe-output config |
| `.github/workflows/alz-vending-dispatcher.md` | Line 102 | `https://github.com/nathlan/alz-subscriptions/blob/main/...` | `https://github.com/insight-agentic-platform-project/azure-landing-zone-vending-machine/blob/main/...` | Agent link |
| `.github/workflows/alz-vending-dispatcher.md` | Multiple | `nathlan/github-config` | `insight-agentic-platform-project/github-config` | Cross-repo targets |

---

## Development Environment (DevContainer)

The repository includes a dev container (`.devcontainer/devcontainer.json` + `setup.sh`) that provides:

- **Git** (latest from source)
- **Docker CLI** (for container management)
- **Node.js, npm, ESLint** (for lint/build tasks)
- **Python 3, pip3** (for scripting)
- **Terraform CLI** (with optional TFLint & Terragrunt)
- **GitHub CLI (`gh`)** with support for extensions like `gh-aw`
- **Common utilities:** `apt`, `curl`, `wget`, `ssh`, `gpg`, `zip`, `tar`, `git`, etc.
- **Ubuntu 24.04.3 LTS** base OS

---

## Key Architectural Patterns

### 1. Map-Based Landing Zone Configuration

- **Single Terraform call** to one module with a map of landing zones
- **terraform.tfvars** defines all zones in one place
- **No branches or multiple state files** — all zones in one `terraform.tfvars` and one state file
- Auto-calculated address spaces prevent overlaps

### 2. Agent-Assisted Self-Service Workflow

**Agent Component Types:**

- **`[Local agent]` alz-vending** ([.github/prompts/alz-vending.prompt.md](../../.github/prompts/alz-vending.prompt.md), [.github/agents/alz-vending.agent.md](../../.github/agents/alz-vending.agent.md))
  - Runs interactively in VS Code (invoked via `/landing-zone-vending` prompt)
  - Collects user inputs (Phase 0 of agent instructions)
  - Validates against existing configuration
  - Creates GitHub issue with `alz-vending` label
  - Hands off to cloud agent for execution

- **`[Agentic Workflow]` ALZ Vending Dispatcher** ([.github/workflows/alz-vending-dispatcher.md](../../.github/workflows/alz-vending-dispatcher.md), compiled to [.github/workflows/alz-vending-dispatcher.lock.yml](../../.github/workflows/alz-vending-dispatcher.lock.yml))
  - Triggered on issue open/close events
  - Reads dispatcher instructions from `.md` definition file (not `.lock.yml`)
  - On issue open: Assigns `alz-vending` custom agent to the issue
  - On issue close: Posts completion comment, extracts config, creates cross-repo issue in `github-config`

- **`[Cloud coding agent]` alz-vending** ([.github/agents/alz-vending.agent.md](../../.github/agents/alz-vending.agent.md))
  - Runs in GitHub cloud context (assigned by dispatcher workflow)
  - Executes Phase 1 (create PR) and Phase 2 (apply and update issue)
  - Modifies `terraform/terraform.tfvars`, creates PR, merges on approval
  - Same agent definition as local context, different runtime environment

### 3. CI/CD with OIDC & Reusable Workflows

- **Reusable workflow pattern:** `terraform-deploy.yml` (child) calls parent from `.github-workflows` repo
- **Dual OIDC identities:** Separate Azure credentials for plan (Reader) vs. apply (Owner)
- **No secrets in code** — credentials via GitHub secrets and OIDC federation
- **Path-based triggers** — Only run on changes to `terraform/` directory

---

## Security & Compliance

- **Secret scanning:** `checkov.yml` configured for `terraform` framework; soft-fail set to `false` (fail on error)
- **TFLint:** Linter config in `.tflint.hcl`
- **Pre-commit hooks:** Configured in `.pre-commit-config.yaml` (likely includes TFLint, Checkov, formatters)
- **Least-privilege OIDC:** Separate identities for plan vs. apply phases

---

## Missing Artifacts

The following document artifacts do not yet exist and will be created by the Documentation Conductor:

- `docs/analysis.md` — This file (Step 1)
- `docs/prerequisites.md` — Azure prerequisites, GitHub configuration, OIDC setup
- `docs/SETUP.md` — Step-by-step deployment guide
- `docs/ARCHITECTURE.md` — Detailed architecture overview
- `README.md` — Repository entry point

---

## Summary of Analysis

| Aspect | Status | Notes |
|--------|--------|-------|
| **Terraform Structure** | ✅ Complete | Single module call, map-based config |
| **GitHub Workflows** | ✅ Complete | 1 standard workflow + 1 Agentic Workflow |
| **Agents** | ✅ Complete | 3 agents (vending, conductor, tech writer) |
| **Prompts** | ✅ Complete | 5 prompts defined |
| **Documentation** | ⚠️ Incomplete | README and `docs/` folder don't exist |
| **Org Migration** | ⚠️ Required | 20+ occurrences of `nathlan` must be updated to `insight-agentic-platform-project` |
| **External Dependencies** | ⚠️ Required | 3 repos must exist/be forked in target org |

---

**Generated:** 2026-03-06  
**Source Organization:** nathlan  
**Target Organization:** insight-agentic-platform-project  
**Target Repository:** azure-landing-zone-vending-machine
