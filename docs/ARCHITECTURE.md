## Architecture: Azure Landing Zone Vending Machine

This document explains the design philosophy, module structure, and operational patterns that enable self-service Azure subscription provisioning at scale.

---

## 1. Map-Based Pattern: Single Config, Multiple Landing Zones

Rather than managing separate Terraform modules for each landing zone, this solution uses a **single map structure** in `terraform.tfvars` to define all landing zones.

```hcl
landing_zones = {
  api-prod = { ... }
  api-dev  = { ... }
  web-test = { ... }
}
```

One module call iterates over the map:

```hcl
module "landing_zones" {
  source = "github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
  landing_zones = var.landing_zones
}
```

**Benefits:**
- Centralized configuration — all landing zones defined in one file
- Consistent state — single `.tfstate` file tracks all resources
- Easy scaling — add new zones by adding map entries
- Conflict detection — simple to verify no duplicate keys or overlapping CIDR ranges
- Audit trail — Git history shows all zone changes clearly

---

## 2. Landing Zone Lifecycle

A landing zone progresses from request to deployed subscription in four phases:

```
PHASE 0: User Input              PHASE 1: PR Creation
┌─────────────────────┐         ┌──────────────────┐
│ /alz-vending Prompt │         │ Copilot Agent    │
│ (Local IDE Mode)    │────────▶│ Creates PR       │
│ Collects inputs     │         │ Adds tfvars      │
│ Creates issue       │         │ Opens PR on main │
└─────────────────────┘         └──────────────────┘
                                         │
                                 PHASE 2: Review & Merge
                                 ┌──────────────────┐
                                 │ PR Approval      │
                                 │ Branch protect   │
                                 │ Merge to main    │
                                 └──────────────────┘
                                         │
                                 PHASE 3: Deploy
                                 ┌──────────────────┐
                                 │ terraform apply  │
                                 │ GitHub Actions   │
                                 │ Creates sub, vnet│
                                 │ Outputs ready    │
                                 └──────────────────┘
```

**Phase 0 (Local IDE):** User runs `/alz-vending` prompt in Copilot within VS Code. Prompt collects workload name, environment, location, team, and optional settings. Validation confirms no conflicts with existing zones.

**Phase 1 (Cloud Agent):** Cloud dispatcher assigns Copilot agent to the GitHub issue. Agent reads current `terraform.tfvars`, computes landing zone map entry, creates PR with changes.

**Phase 2 (Human Review):** PR requires approval per branch protection rules. Terraform plan is posted as comment for visibility.

**Phase 3 (Automated Deploy):** On merge to `main`, workflow triggers `terraform apply`. New subscriptions are created and outputs are available for downstream automation.

---

## 3. Module Chain: Abstraction Layers

This repository participates in a three-layer module hierarchy:

```
┌─────────────────────────────────────────────┐
│ This Repository:                            │
│ alz-subscriptions (GitHub)                  │
│ ├─ Calls terraform-azurerm-landing-zone-   │
│ │  vending (Private Module)                 │
│ └─ Coordinates: OIDC, state, vars          │
└──────────────┬──────────────────────────────┘
               │ (calls private module)
               ▼
┌─────────────────────────────────────────────┐
│ ⚠️  insight-agentic-platform-project Org    │
│ terraform-azurerm-landing-zone-vending      │
│ ├─ Provisions subscriptions                 │
│ ├─ Creates VNets & subnets                  │
│ ├─ Manages OIDC & identities                │
│ └─ Orchestrates Azure Verified Modules      │
└──────────────┬──────────────────────────────┘
               │ (uses public modules)
               ▼
┌─────────────────────────────────────────────┐
│ Azure Verified Modules (Public, Microsoft)  │
│ ├─ avm/res/network/virtual-network          │
│ ├─ avm/res/authorization/role-assignment    │
│ ├─ avm/res/authorization/user-assigned-id   │
│ └─ avm/res/compute/virtual-machine          │
│    (and others as needed)                   │
└─────────────────────────────────────────────┘
```

| Layer | Repo | Purpose | Inputs | Outputs |
|-------|------|---------|--------|----------|
| Vending Machine | alz-subscriptions | Coordination, tfvars, CI/CD | Landing zone map, Azure config | Subscription IDs, VNet IDs |
| Landing Zone Module (⚠️) | terraform-azurerm-landing-zone-vending | Orchestration, OIDC, naming | Zone name, location, team | Subscription, UMI, federated creds |
| Azure Verified (Public) | azure/terraform-azurerm-avm-* | Resource provisioning | Standard AVM interfaces | Azure resources (VNet, subnet, role) |

**Why layered?**
- **Separation of concerns:** Vending logic isolated from AVM complexity
- **Reusability:** Multiple vending machines can use the same landing zone module
- **vendor compatibility:** AVM modules are Microsoft-maintained; easy to update
- **Testing:** Each layer can be tested independently

---

## 4. State Management

Terraform state management is handled by the **reusable pipeline** called from `.github/workflows/terraform-deploy.yml`. This repository does not contain a `backend.tf` — the reusable workflow configures the backend at runtime.

All landing zones share a single state file, providing:
- **Atomic operations:** All zones updated together; no partial deployments
- **Single source of truth:** One state file, one history, one lock mechanism
- **No static credentials:** Authentication is handled via OIDC in the pipeline

---

## 5. OIDC Dual-Identity Model

Two separate Azure identities provide least-privilege access:

### Plan Identity (Reading)

- **Role:** Reader on management group
- **Scope:** Browse subscriptions, inspect existing resources
- **Used by:** `terraform plan` during PR validation
- **Federated to:** GitHub Actions on any PR/push to `main`

### Apply Identity (Provisioning)

- **Role:** Contributor on management group + Billing Account Contributor
- **Scope:** Create subscriptions, modify resources, write state
- **Used by:** `terraform apply` on merge to `main`
- **Federated to:** GitHub Actions on `main` branch only

**OIDC flow:**
1. GitHub Actions job starts
2. GitHub OIDC provider issues a short-lived token
3. Azure login uses token to acquire access token without secret
4. Terraform executes as the assigned identity

**Why dual identity?**
- **Security:** Compromised plan operation cannot modify resources
- **Audit:** Two separate identity traces for compliance
- **Safety:** Developers can run plans in PRs; only merge can apply

---

## 6. CI/CD Pipeline: GitHub Actions Orchestration

The deployment pipeline is defined in `.github/workflows/terraform-deploy.yml` and calls a reusable parent workflow from `.github-workflows` repository (⚠️ in `insight-agentic-platform-project` org):

```yaml
uses: insight-agentic-platform-project/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
```

**Pipeline stages:**

| Trigger | Stage | Action | Identity |
|---------|-------|--------|----------|
| Pull Request to `main` | **Plan** | `terraform plan` + post as PR comment | Plan Identity (Reader) |
| Merge to `main` | **Validate** | `terraform validate`, Checkov scanning | Plan Identity (Reader) |
| After Merge | **Apply** | `terraform apply` → creates subscriptions | Apply Identity (Contributor) |
| Manual | **Dispatch** | Optional: run plan/apply manually | Apply Identity (Contributor) |

**Verification:**
- All Terraform plan output visible in PR comments
- Security scan (Checkov) results posted before apply
- Apply logs available in GitHub Actions UI

---

## 7. Agent Workflows: Local + Cloud Modes

### Mode 1: Local IDE (Phase 0)

User runs `/alz-vending` prompt inside VS Code with Copilot extension.

**Flow:**
1. Prompt collects zone name, env, location, team interactively
2. Prompt validates locally (no duplicate keys, address space conflicts)
3. User confirms configuration
4. Prompt creates GitHub issue with all inputs

**Tools used:**
- VS Code Copilot extension
- GitHub CLI (gh) for issue creation
- Read-only access to terraform.tfvars

**When to use:** Developers designing zones in IDE; quick validation before cloud submission.

### Mode 2: Cloud Dispatcher (Phase 1-3)

GitHub dispatcher workflow receives Phase 0 issue and assigns Copilot agent.

**Flow:**
1. Issue is created in repository
2. `alz-vending-dispatcher.lock.yml` detects new issue
3. Dispatcher assigns Copilot coding agent to issue
4. Agent reads current tfvars, computes zone entry, creates PR
5. PR undergoes review and merge
6. Workflow applies Terraform

**Tools used:**
- Copilot agent (GitHub-native coding assistant)
- GitHub API for PR/issue operations
- Terraform workflows in `.github/workflows`

**When to use:** Automation teams extending zones; agent handles PR creation autonomously.

**Key difference:** Local mode is synchronous (user waits); cloud mode is async (agent works in background, posts updates to issue).

---

## 8. Developer Experience

### DevContainer Setup

The repository includes a **`.devcontainer/devcontainer.json`** that provides a pre-configured environment:

- **Terraform CLI** (~> 1.10) with providers pre-installed
- **Azure CLI** (az) for interactive commands
- **GitHub CLI** (gh) for repository operations
- **Python 3** + pip for scripting
- **Node.js** + npm for helper tools
- **Git** with pre-commit hooks configured

**Benefits:**
- Consistent environment across team members
- No local installation required (Docker handles setup)
- Auto-formatting on save (Terraform fmt, Prettier)
- Copilot extensions bundled

### Pre-commit Hooks

Configured in `.pre-commit-config.yaml`:
- **Terraform validate** on every commit
- **TFSec** for security scanning
- **Trailing whitespace** cleanup
- **YAML/JSON** validation

```bash
# Run manually
pre-commit run --all-files

# Auto-installs hooks on git init
```

### Extension Support

- **Terraform Extension:** Syntax highlighting, auto-complete, validation
- **Copilot** & **Copilot Chat:** AI-assisted code generation and documentation
- **Azure Tools:** Integrated Azure resource browsing
- **GitLens:** Blame, history, commit details

---

## Summary: Design Principles

This architecture embodies five key principles:

1. **Single Source of Truth:** All zones defined in one map; one state file
2. **Least Privilege:** Two identities for plan/apply; OIDC for authentication
3. **Developer Self-Service:** Local `/alz-vending` prompt + cloud agent automation
4. **Audit & Governance:** Branch protection, OIDC traces, state locking
5. **Reusability:** Layered modules enable sharing across use cases

For step-by-step setup, see [docs/SETUP.md](SETUP.md).

The deployment workflow defines a two-identity model:

- `AZURE_CLIENT_ID_PLAN` for plan stage access
- `AZURE_CLIENT_ID_APPLY` for apply stage access
- shared tenant/subscription context via `AZURE_TENANT_ID` and
  `AZURE_SUBSCRIPTION_ID`
- workflow permission `id-token: write` enables GitHub OIDC token exchange

This separates read/preview concerns from write/provision concerns in CI/CD identity
use, while avoiding static cloud credentials in workflow logic.

## Address Space Auto-Calculation Model

Networking intent is split into two layers:

- global base pool: `azure_address_space` (for example, `10.100.0.0/16`)
- per-landing-zone request: prefix sizes (for example, `/24`, `/26`) in spoke VNet
  structures

Validation enforces CIDR/prefix format, and the module returns
`calculated_address_prefixes` as an output. This indicates the concrete address
allocation is computed from the base pool plus requested prefix sizes rather than
manually hard-coded per zone.

## CI/CD Reusable Workflow Flow

Deployment is a child-to-parent reusable workflow model:

- Child workflow triggers on:
  - PRs to `main` (plan path)
  - pushes to `main` (apply path)
  - manual dispatch (environment input)
- Child workflow calls a centralized reusable workflow in
  `insight-agentic-platform-project/.github-workflows`.
- The child passes working directory and environment context; credentials are injected
  via secrets.

Architecturally, this keeps repository-specific intent local while centralizing
execution behavior, policy controls, and operational updates in one reusable pipeline.

## Optional Agent-Assisted Flow

The repository also contains an issue-driven optional flow:

- A dispatcher workflow reacts to issue open/close events.
- It only acts on issues labeled `alz-vending`.
- On open, it assigns the `alz-vending` custom agent.
- The agent instructions describe:
  - collecting and validating request data
  - generating structured issue content
  - driving Terraform map updates through PR-based automation
  - updating issue progress and coordinating follow-on handoff

This path is optional because the same infrastructure lifecycle still resolves through
the PR/merge/deploy pipeline.

## Outputs as the Architecture Contract

Outputs form the handoff interface from provisioning to consumers. The repository
publishes maps for:

- subscription IDs and subscription resource IDs
- landing zone names
- virtual network IDs and address spaces
- resource group IDs
- managed identity client/principal/resource IDs
- budget resource IDs
- calculated address prefixes

In this architecture, outputs are not incidental—they are the stable evidence that
turns a requested landing zone into a consumable platform artifact.
