# Azure Landing Zone Vending Machine

> **Migrating from `nathlan` to `insight-agentic-platform-project`?**
> All organization references must be updated before deployment. See [Migration Checklist in prerequisites.md](docs/prerequisites.md#migration-checklist-for-org-change).

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.10-623ce4)](https://www.terraform.io/downloads.html)
[![azapi Provider](https://img.shields.io/badge/azapi-%3E%3D2.5-FF0000)](https://registry.terraform.io/providers/azure/azapi/latest)
[![modtm](https://img.shields.io/badge/modtm-%3E%3D0.3-4B9E45)](https://registry.terraform.io/providers/cloudposse/modtm)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Self-service Azure subscription provisioning.** Define landing zones in a single `terraform.tfvars` map. Terraform handles subscriptions, virtual networks, managed identities, OIDC credentials, and budgets. Optional GitHub Copilot agents automate zone requests and deployments.

## Quick Start

1. **[docs/SETUP.md](docs/SETUP.md)** — Configure Azure backend, OIDC identities, GitHub secrets, run first deployment
2. **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Learn the map-based pattern, module chain, CI/CD flow
3. **[docs/prerequisites.md](docs/prerequisites.md)** — Complete requirements checklist and migration guidance

## What You'll Need

- [ ] Azure subscription with **EA or MCA** billing enrollment
- [ ] GitHub organization: `insight-agentic-platform-project`
- [ ] Two OIDC identities configured (plan + apply)
- [ ] Azure Storage Backend for Terraform state
- [ ] (Optional) Hub Virtual Network for spoke peering

## Agent Workflows: Copilot-Powered Provisioning

Three interconnected agent components orchestrate self-service landing zone provisioning:

### [Local agent] Landing Zone Vending
**Files:** [`.github/prompts/alz-vending.prompt.md`](.github/prompts/alz-vending.prompt.md), [`.github/agents/alz-vending.agent.md`](.github/agents/alz-vending.agent.md)  
**Command:** `/landing-zone-vending` in VS Code Copilot  
**Role:** Collects zone inputs (workload, env, location, team, address space), validates for conflicts, creates GitHub issue with structured payload.

### [Agentic Workflow] ALZ Vending Dispatcher
**Files:** [`.github/workflows/alz-vending-dispatcher.md`](.github/workflows/alz-vending-dispatcher.md) (definition), [`.github/workflows/alz-vending-dispatcher.lock.yml`](.github/workflows/alz-vending-dispatcher.lock.yml) (compiled)  
**Trigger:** GitHub issue events (opened/closed)  
**Role:** Detects `alz-vending` labeled issues, assigns cloud coding agent, orchestrates PR creation and cross-repo handoff.

### [Cloud coding agent] ALZ Subscription Vending
**File:** [`.github/agents/alz-vending.agent.md`](.github/agents/alz-vending.agent.md)  
**Context:** Cloud (GitHub Actions)  
**Role:** Creates PR with updated `terraform.tfvars`, manages merge/apply workflow, posts progress updates.

**One-click workflow:** User runs `/landing-zone-vending` → creates issue → dispatcher assigns agent → agent creates PR → merge triggers apply → subscription deployed.

## Developer Experience

**DevContainer included:** VS Code devcontainer provides instant setup with Terraform, Azure CLI, GitHub CLI, Python 3, Node.js, Copilot extensions, and auto-formatting on save.

```bash
# Open in devcontainer (VS Code)
# Command Palette → "Dev Containers: Reopen in Container"
```

## How It Works

**Map-based configuration:** All zones defined in `terraform.tfvars` as an HCL map. Single module call with `.for_each` iterates over zones, creating each subscription independently.

**Shared state:** One `main.tfstate` in Azure Storage with OIDC authentication — no static secrets, full audit trail.

**Dual-identity CI/CD:** Plan operations use Reader identity, apply operations use Contributor identity — separation of concerns with governance.

## Configuration

Update `terraform/terraform.tfvars` before deployment:

| Setting | Required | Example |
|---------|----------|---------|
| `subscription_billing_scope` | Yes | `/providers/Microsoft.Billing/billingAccounts/...` |
| `subscription_management_group_id` | Yes | `/providers/Microsoft.Management/managementGroups/Corp` |
| `hub_network_resource_id` | No | `/subscriptions/.../virtualNetworks/vnet-hub` or `null` |
| `github_organization` | Yes | `insight-agentic-platform-project` |
| `azure_address_space` | Yes | `10.100.0.0/16` |

## Architecture Highlights

- **Module chain:** This repo → private wrapper module → public Azure Verified Modules (AVM)
- **OIDC only:** Federated credential from GitHub OIDC; Azure login without secrets
- **State management:** Centralized backend; atomic zone deployments
- **Outputs:** Subscription IDs, VNet IDs, managed identity details, calculated CIDRs

For full architecture details, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Repository Structure

```
alz-subscriptions/
├── terraform/                 # Terraform configuration
│   ├── main.tf               # Landing zone vending module call
│   ├── variables.tf          # Input variable definitions
│   ├── terraform.tfvars      # Landing zone map (customize)
│   ├── backend.tf            # Azure Storage backend
│   ├── outputs.tf            # Zone outputs
│   └── versions.tf           # Provider versions
├── .github/
│   ├── workflows/
│   │   ├── terraform-deploy.yml          # CI/CD pipeline
│   │   ├── alz-vending-dispatcher.md     # Agentic Workflow definition
│   │   └── alz-vending-dispatcher.lock.yml # Agentic Workflow compiled (auto-generated)
│   ├── agents/               # Copilot coding agents
│   ├── prompts/              # Interactive Copilot prompts
│   └── instructions/         # Best practices guides
├── docs/                     # Full documentation
│   ├── analysis.md          # Detailed codebase analysis
│   ├── prerequisites.md     # Requirements & secrets checklist
│   ├── SETUP.md             # Step-by-step setup guide
│   └── ARCHITECTURE.md      # Design explanation
└── README.md                # This file
```

## Documentation

- **[docs/analysis.md](docs/analysis.md)** — Comprehensive inventory of repository structure, dependencies, and org-specific references
- **[docs/prerequisites.md](docs/prerequisites.md)** — Azure requirements, GitHub secrets, OIDC setup, migration checklist
- **[docs/SETUP.md](docs/SETUP.md)** — Walkthrough: create backend, configure OIDC, set secrets, deploy first zone
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Design patterns, module chain, state management, agent workflows

## License

MIT