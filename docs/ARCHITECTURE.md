# Architecture Overview

This document explains the design of the Azure Landing Zone Vending Machine — a self-service platform for provisioning complete Azure Landing Zones through a unified Terraform configuration, GitHub Agentic Workflows, and optional VS Code agents.

## Core Design: Map-Based Architecture

Rather than using per-zone branches, conditional logic, or separate workflows, this system employs a **single configuration file** (`terraform.tfvars`) containing a map of landing zones. One module call processes all zones simultaneously, scaling from one to hundreds of landing zones without code duplication or per-zone infrastructure.

```terraform
landing_zones = {
  example-api-prod = { workload = "example-api-prod", env = "prod", ... },
  graphql-dev      = { workload = "graphql-dev",      env = "dev",  ... },
  # Add more zones as needed — no code changes required
}
```

**Why this approach?**
- **Simplicity**: One module invocation, one state file, one Terraform plan/apply
- **Scalability**: Add 100 zones by adding 100 map entries (no workflow duplication)
- **Maintainability**: No branching logic per zone; all changes happen in `terraform.tfvars`
- **Consistency**: All zones use the same validated module, ensuring uniform governance

## Landing Zone Lifecycle

The journey from request to deployed infrastructure follows five stages:

1. **Request** → Developer submits a landing zone request via [Local agent] `alz-vending` VS Code prompt (`/landing-zone-vending`)
2. **Issue Creation** → Local agent validates inputs, retrieves requester identity, creates GitHub issue with `alz-vending` label
3. **Dispatcher & Assignment** → [Agentic Workflow] `ALZ Vending Dispatcher` detects issue open event, assigns [Cloud coding agent] `alz-vending` to the issue
4. **PR & Merge** → Cloud agent reads issue details, adds landing zone entry to `terraform.tfvars`, creates pull request, awaits review/merge
5. **Deployment** → GitHub push event triggers `terraform-deploy.yml` workflow, which calls reusable parent workflow for `terraform plan` and `terraform apply`
6. **Outputs** → Terraform outputs (subscription IDs, UMI client IDs, VNet resource IDs) are written to issue for handoff to workload repository creation

## Terraform Module Stack

This repository does **not** directly provision Azure resources. Instead, it acts as the **orchestration layer** calling a private wrapper module, which internally uses Azure Verified Modules (AVM) for infrastructure:

```
alz-subscriptions (this repo)
  ├─ main.tf calls:
  │    module "landing_zones" sourced from:
  │    github.com/nathlan/terraform-azurerm-landing-zone-vending
  │
  └─ terraform-azurerm-landing-zone-vending (private module)
      ├─ Creates subscriptions via Azure REST API (azurerm_subscription)
      ├─ Creates VNets and subnets
      ├─ Creates user-managed identities with OIDC federated credentials
      ├─ Creates role assignments (via azurerm_role_assignment, using AVM patterns)
      ├─ Creates budgets with cost alerts
      └─ Uses Azure Verified Modules (AVM) internally for consistency
```

**Critical Migration Note**: The module source `github.com/nathlan/terraform-azurerm-landing-zone-vending` is **private** and must be **forked** into your organization. Update the module source in [terraform/main.tf](terraform/main.tf) to reflect your organization:

```terraform
# Before (source organization):
source = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6"

# After (your organization):
source = "github.com/YOUR-ORG/terraform-azurerm-landing-zone-vending?ref=v1.0.6"
```

## State Management

A **single Terraform state file** (not committed to this repository) manages all landing zones across all environments. This state file must be stored in a remote backend — typically Azure Storage.

**Backend Configuration** (not shown in code, applied at runtime):

```bash
terraform init \
  -backend-config="resource_group_name=alz-state-rg" \
  -backend-config="storage_account_name=alzstatesa" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=alz-subscriptions.tfstate"
```

**Single state file benefits:**
- Transactional consistency across all zones
- Cross-zone references in outputs (e.g., aggregate VNet peering)
- One drift detection scan covers all landing zones

## OIDC Authentication & Dual Identity

GitHub Actions workflows authenticate to Azure using **OpenID Connect (OIDC)** federation, eliminating the need for long-lived secrets. Two distinct identities handle different operations:

1. **Plan Identity** (read-only): Views current state, reads subscriptions, validates configuration
2. **Apply Identity** (write): Creates subscriptions, VNets, identities, budgets, role assignments

Both identities are **user-managed identities (UMI)** created in a central management subscription with OIDC federated credentials configured for GitHub repository:

```
GitHub Actions workflow_dispatch event
  ↓
  Uses: OIDC token issued by GitHub OIDC provider
  ↓
  Azure AD: Validates token against federated credential
             `github.com/YOUR-ORG/alz-subscriptions` → UMI client ID
  ↓
  UMI: Authenticated; role assignments grant subscription creation permissions
```

Each landing zone's provisioned infrastructure includes its own **separate UMI** for workload OIDC (e.g., deploying to the landing zone's subscription).

## Address Space Auto-Calculation

A key operational simplification is **automatic address space derivation**. Given:
- **Base CIDR**: `10.100.0.0/16` (1024 possible /24s)
- **Zone index**: Derived from the alphabetical position in the `landing_zones` map (e.g., `example-api-prod` = index 0, `graphql-dev` = index 1)

The module calculates each zone's VNet address space as:

```
zone_address_space = base_cidr ⊕ (zone_index × /24_prefix)
                   = 10.100.{index}.0/24
```

Example:
- `example-api-prod` (index 0) → `10.100.0.0/24`
- `graphql-dev` (index 1) → `10.100.1.0/24`

Subnets within each zone further subdivide their /24 (e.g., two /26s per zone). This design scales to 256 zones from a single /16 without manual CIDR planning.

## CI/CD Pipeline

The deployment pipeline follows a standard GitHub Actions pattern:

1. **Trigger**: `push` event to `main` branch (terraform/** path), manual `workflow_dispatch`, or pull request event
2. **Workflow**: `.github/workflows/terraform-deploy.yml` 
3. **Execution**: Calls a **reusable parent workflow** from a separate **`.github-workflows`** repository (for DRY principle; must exist and be accessible)
4. **Steps**:
   - Authenticate via OIDC (plan identity)
   - Run `terraform init` with backend config
   - Run `terraform plan`
   - On merge to main: Authenticate via OIDC (apply identity) and run `terraform apply`

**Reusable Workflow Note**: The parent workflow is sourced from `github.com/insight-agentic-platform-project/.github-workflows` (update organization name as applicable). This separation allows multiple repositories to reuse the same Terraform deploy logic.

## Agent-Assisted Workflow

The provisioning flow integrates **three types of AI agents** for different stages:

### [Local agent] `alz-vending` (VS Code)
Runs interactively in the developer's editor via the `/landing-zone-vending` prompt.
- **Tools**: VS Code prompts (`vscode/askQuestions`), read-only file access, GitHub MCP
- **Scope**: Collect and validate user inputs (Phase 0 only)
- **Output**: Create a GitHub issue with validated configuration
- **Responsibility**: Ends after issue creation; does NOT execute infrastructure changes

### [Agentic Workflow] `ALZ Vending Dispatcher` (GitHub Event-Triggered)
Runs automatically on issue `opened` and `closed` events via `.github/workflows/alz-vending-dispatcher.md`.
- **Engine**: Copilot (agentic workflow engine)
- **Scope**: Route `alz-vending` label issues to the cloud agent; notify requester and hand off to workload repo creation on close
- **Responsibility**: Agent orchestration and cross-repo coordination

### [Cloud coding agent] `alz-vending` (GitHub Copilot)
Executes in the cloud after dispatcher assignment.
- **Context**: Reads issue description and Terraform configuration
- **Scope**: Phase 1 (create PR with tfvars updates) and Phase 2 (provide progress updates)
- **Tools**: Full GitHub repository access, Terraform read access
- **Output**: Pull request with landing zone entry added to `terraform.tfvars`

Together, these agents enable a seamless user experience: request → validation → PR → deploy.

## Developer Experience

The workspace includes a **DevContainer** pre-configured with all necessary tooling:

- **Terraform 1.10+** (with azapi, modtm, random, time providers)
- **GitHub CLI** (`gh`) for workload repository operations
- **Docker** for containerized workflows
- **Python 3 & pip** for custom scripting (optional)
- **Pre-commit hooks** for linting and validation (Terraform, Markdown, YAML)

Developers open this workspace in VS Code with the Dev Containers extension, which automatically installs all tools. No manual setup required.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                      │
│               alz-subscriptions (this repo)                  │
└─────────────────────────────────────────────────────────────┘
        │
        ├─► .github/prompts/alz-vending.prompt.md
        │   └─► [Local agent] alz-vending (VS Code)
        │       └─► Creates issue with alz-vending label
        │
        ├─► .github/workflows/alz-vending-dispatcher.md
        │   └─► [Agentic Workflow] triggered on issue open/close
        │       └─► Assigns [Cloud coding agent] alz-vending
        │
        ├─► terraform/
        │   ├─ main.tf         (calls terraform-azurerm-landing-zone-vending)
        │   ├─ variables.tf    (inputs: billing_scope, addresses, landing_zones map)
        │   ├─ outputs.tf      (subscription IDs, UMI IDs, VNet IDs)
        │   └─ terraform.tfvars (all landing zones in single map)
        │
        └─► .github/workflows/terraform-deploy.yml
            └─► Calls reusable parent from .github-workflows repo
                └─► Authenticates via OIDC
                ├─ terraform plan
                └─ terraform apply
                    ├─► azure-provider
                    │   └─► Creates subscriptions, VNets, UMIs, budgets
                    │
                    ├─► terraform-azurerm-landing-zone-vending (private module)
                    │   └─► Orchestrates AVM calls for consistent provisioning
                    │
                    └─► Azure Verified Modules (AVM)
                        └─► Best-practice patterns for Azure infrastructure

┌─────────────────────────────────────────────────────────────┐
│                    Remote State Backend                      │
│               Azure Storage (alz-subscriptions.tfstate)      │
│            (Shared across all GitHub Copilot agents)        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Azure Landing Zones (n)                     │
│     Each with subscription, VNet, UMI, OIDC, budget         │
└─────────────────────────────────────────────────────────────┘
```

## Migration Checklist

When adopting this architecture in your organization:

- ⚠️ **Fork Module**: Fork `terraform-azurerm-landing-zone-vending` into your GitHub organization and update `source` in [terraform/main.tf](terraform/main.tf)
- ⚠️ **Update Organization References**: Replace `nathlan` with your organization across all files (workflows, agent definitions, tfvars)
- ⚠️ **Create `.github-workflows` Repository**: The reusable parent workflow must exist in your organization
- ⚠️ **Configure OIDC**: Set up Azure OIDC federation for both plan and apply identities
- ⚠️ **Remote Backend**: Initialize Terraform with a remote backend (Azure Storage)
- ⚠️ **Agent Configuration**: Update agent definitions with your repository URLs and organization details
