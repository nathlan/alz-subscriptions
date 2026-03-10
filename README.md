# ALZ Vending Machine

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.10-blue)](https://www.terraform.io)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Self-service Azure Landing Zone provisioning via GitHub Agentic Workflows**

---

## Overview

ALZ Vending Machine solves a critical infrastructure challenge: how do organizations enable teams to provision production-ready Azure landing zones without manual tickets, approval delays, or deployment errors? This repository combines Terraform, GitHub Agentic Workflows, and Copilot agents to create a fully automated, self-service landing zone request system. Teams submit landing zone requests via a conversational VS Code interface, and complete Azure subscriptions—with networking, identity, and budgeting—are provisioned automatically within minutes.

---

## Quick Start

```bash
# 1. Clone and open in devcontainer (all tools pre-installed)
git clone https://github.com/insight-agentic-platform-project/alz-vending-machine.git
cd alz-vending-machine
code .

# 2. Open command palette (Ctrl+Shift+P / Cmd+Shift+P) and type:
/alz-vending-machine

# 3. Follow SETUP phases (see docs/SETUP.md)
```

**First time?** Start with [docs/SETUP.md](docs/SETUP.md) for step-by-step deployment.

---

## What You'll Need

- [x] Terraform >= 1.10
- [x] Azure subscription with permissions for role assignments
- [x] Azure App Registrations for OIDC (plan, apply, state storage identities)
- [x] Azure Storage account for Terraform state
- [x] GitHub Actions secrets + org/repo-level variables

See [docs/prerequisites.md](docs/prerequisites.md) for the complete checklist.

---

## How It Works

1. **User requests a landing zone** via `/alz-vending-machine` prompt in VS Code
2. **Local agent collects inputs**, validates, and creates a GitHub issue
3. **Dispatcher workflow assigns a cloud agent** to the issue
4. **Cloud agent creates a PR** with terraform.tfvars updated
5. **PR is reviewed and merged** → Terraform workflow triggers
6. **Cloud agent posts deployment outputs** (subscription ID, resource IDs, etc.)

**Total time:** ~5 minutes after PR merge (Terraform plan + apply)

---

## Agent Workflows

This repository uses **three agent component types** orchestrating the landing zone provisioning:

| Component | Type | File | Description |
|-----------|------|------|-------------|
| ALZ Subscription Vending | `[Local agent]` | `.github/agents/alz-vending.agent.md`, invoked via `/alz-vending-machine` prompt | Runs in VS Code; collects inputs, validates, creates issue |
| ALZ Vending Dispatcher | `[Agentic Workflow]` | `.github/workflows/alz-vending-dispatcher.md` (definition + `.lock.yml` compiled) | Triggered by issue events; assigns cloud agent on open, handles handoff on close |
| ALZ Subscription Vending | `[Cloud coding agent]` | `.github/agents/alz-vending.agent.md` (same file, cloud context) | Assigned by dispatcher; Phase 1: modifies tfvars & creates PR; Phase 2: updates issue with outputs |

---

## Repository Structure

```
alz-vending-machine/
├── README.md                          ← You are here
├── docs/
│   ├── analysis.md                    (Codebase analysis)
│   ├── prerequisites.md               (Setup checklist & migration guide)
│   ├── SETUP.md                       (Step-by-step deployment)
│   └── ARCHITECTURE.md                (Design explanation)
├── terraform/
│   ├── main.tf                        (Single module call: landing_zones)
│   ├── variables.tf                   (Landing zone schema)
│   ├── outputs.tf                     (Outputs keyed by landing zone)
│   ├── versions.tf                    (Terraform version, providers)
│   ├── terraform.tfvars               (Map-based config)
│   └── checkov.yml                    (Security scanning)
├── .github/
│   ├── workflows/
│   │   ├── alz-vending-dispatcher.md              (Agentic Workflow [definition])
│   │   ├── alz-vending-dispatcher.lock.yml        (Agentic Workflow [compiled])
│   │   ├── azure-terraform-cicd-caller.yml        (Calls parent reusable workflow)
│   │   └── copilot-setup-steps.yml
│   ├── agents/
│   │   └── alz-vending.agent.md                   (Local + cloud agent)
│   └── prompts/
│       └── alz-vending.prompt.md                  (VS Code command: /alz-vending-machine)
├── .devcontainer/
│   ├── devcontainer.json              (Dev environment config)
│   └── setup.sh
└── sync/
    └── .github/                       (Synced GitHub config)
```

Key files annotated with their role in the agent workflow.

---

## Developer Experience

**Devcontainer includes:** Docker CLI • Terraform • Python 3.11 • Node.js LTS • Git • GitHub CLI

**VS Code extensions:** Terraform • Python + Pylance • GitHub Copilot + Copilot Chat • GitHub PRs

**Auto-configured:** Terraform formatting on save, Copilot UI integration, Python linting

Open this repository in VS Code and the devcontainer launches automatically. No manual tool installation required.

---

## Installation & Configuration

### Before You Begin: Migration Required

⚠️ **CRITICAL:** This repository references the source organization `nathlan`. Before any deployment:

1. **Update all org references** from `nathlan` to `<YOUR_GITHUB_ORG>`
2. **Fork/mirror external repositories** to your organization (module, shared-assets, github-config, template)
3. **See [docs/prerequisites.md#migration-checklist](docs/prerequisites.md#migration-checklist)** for complete migration steps

### 3-Step Setup

```
Phase 1: Repository Setup
  → Fork external repos
  → Update all org references
  → Verify syntax

Phase 2: Azure Identity & OIDC
  → Create App Registrations (plan, apply, state)
  → Create storage account for state
  → Configure OIDC federated credentials
  → Assign Azure roles

Phase 3: GitHub Configuration
  → Create GitHub Actions secrets (GH_AW_GITHUB_TOKEN, GH_AW_AGENT_TOKEN)
  → Set org-level variables (AZURE_CLIENT_ID_TFSTATE, etc.)
  → Set repo-level variables (AZURE_CLIENT_ID_PLAN, AZURE_CLIENT_ID_APPLY, AZURE_SUBSCRIPTION_ID)
  → Verify Terraform validates successfully

Phase 4+: First Deployment
  → Test local agent: /alz-vending-machine in VS Code
  → Monitor agent assignment & workflow execution
  → Deploy first landing zone
```

**Complete guide:** See [docs/SETUP.md](docs/SETUP.md)

---

## Documentation

- **📖 [Setup Guide](docs/SETUP.md)** — Step-by-step deployment (6 phases)
- **🏗️ [Architecture Overview](docs/ARCHITECTURE.md)** — Design, workflows, authentication
- **✅ [Prerequisites Reference](docs/prerequisites.md)** — Checklist, secrets, variables, migration
- **📋 [Codebase Analysis](docs/analysis.md)** — Detailed inventory of repository components

---

## How to Contribute

Found a bug or have a suggestion? Open an issue in this repository. For enhancements to the landing zone vending module itself, see the upstream module repository:
- **terraform-azure-landing-zone-vending** (fork it to your organization)

---

## License

MIT (see LICENSE file)

---

## Migration Note

This repository originated in the `nathlan` GitHub organization. Before using in `<YOUR_GITHUB_ORG>`, you must:

1. Replace all `nathlan/` references with your organization (see Migration Checklist in [docs/prerequisites.md](docs/prerequisites.md))
2. Fork or mirror the private Terraform module and reusable workflows repository to your organization
3. Create placeholder repositories (github-config, alz-workload-template)

**See [docs/prerequisites.md#migration-checklist](docs/prerequisites.md#migration-checklist) — this is your starting point.**

## Quick Start

**Clone and run this repository in VS Code with the devcontainer:**

```bash
git clone https://github.com/insight-agentic-platform-project/alz-vending-machine.git
cd alz-vending-machine
```

Open in VS Code devcontainer—all tools come pre-installed: Terraform, Python, Node, GitHub CLI, and Docker. For step-by-step deployment instructions, see [docs/SETUP.md](docs/SETUP.md).

## What You'll Need

- Terraform >= 1.10
- Azure subscription with Owner permissions
- Azure management group and billing scope identities
- GitHub Actions secrets (`GH_AW_GITHUB_TOKEN`, `GH_AW_AGENT_TOKEN`)
- GitHub Copilot Chat enabled

See [docs/prerequisites.md](docs/prerequisites.md) for complete setup requirements.

## How It Works

User submits landing zone request via `/alz-vending-machine` prompt → `[Local agent]` creates issue with specifications → `[Agentic Workflow]` dispatcher assigns `[Cloud coding agent]` → Agent generates Terraform changes in pull request → Team reviews and merges → CI/CD applies infrastructure to Azure → Agent updates issue with resource IDs and endpoints.

For detailed workflow explanation, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Agent Workflows

| Component | Type | File | Purpose |
|-----------|------|------|---------|
| ALZ Vending | `[Local agent]` | [.github/prompts/alz-vending-machine.prompt.md](.github/prompts/alz-vending-machine.prompt.md) | Captures landing zone requirements in VS Code |
| ALZ Dispatcher | `[Agentic Workflow]` | [.github/workflows/alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md) | Routes issue to cloud agent for provisioning |
| ALZ Vending | `[Cloud coding agent]` | [.github/agents/alz-vending.agent.md](.github/agents/alz-vending.agent.md) | Creates infrastructure PRs and orchestrates deployments |

## Repository Structure

```
alz-vending-machine/
├── .devcontainer/              # Docker environment + tooling
├── .github/
│   ├── agents/
│   │   └── alz-vending.agent.md            [Cloud coding agent]
│   ├── prompts/
│   │   └── alz-vending-machine.prompt.md   [Local prompt]
│   ├── workflows/
│   │   ├── alz-vending-dispatcher.md       [Agentic Workflow definition]
│   │   ├── alz-vending-dispatcher.lock.yml [Compiled workflow]
│   │   └── azure-terraform-cicd-caller.yml [CI/CD dispatcher]
│   └── instructions/           # Development guidelines
├── terraform/
│   ├── main.tf                 (Single module call)
│   ├── variables.tf            (Landing zone schemas)
│   ├── terraform.tfvars        (Map-based configuration)
│   └── checkov.yml             (Security scanning)
├── docs/
│   ├── SETUP.md                (Deployment phases)
│   ├── ARCHITECTURE.md         (Workflow & design)
│   ├── prerequisites.md        (Requirements checklist)
│   └── analysis.md             (Full system analysis)
└── README.md
```

## Developer Experience

The devcontainer includes Docker, Terraform, Python, Node, GitHub CLI, and Git—everything you need to contribute or deploy. VS Code automatically activates the container. Recommended extensions: Terraform, Python, GitHub Copilot, GitHub Pull Requests.

## Installation & Configuration

1. **Clone** this repository to `insight-agentic-platform-project` organization (or your target org)
2. **Complete the Migration Checklist** in [docs/prerequisites.md](docs/prerequisites.md#migration-checklist)—all `nathlan/` references must be updated to your organization
3. **Follow deployment phases** in [docs/SETUP.md](docs/SETUP.md)

## ⚠️ Migration Notice

This repository originates from the `nathlan` organization. **Before using in `insight-agentic-platform-project`, you must:**
- Fork/mirror these dependencies to your organization:
  - `terraform-azure-landing-zone-vending` (Terraform module)
  - `shared-assets` (reusable CI/CD workflows)
  - `github-config` (automation target repository)
  - `alz-workload-template` (template repository)
- Update all `nathlan/` references to `insight-agentic-platform-project/` across configuration files

See [docs/prerequisites.md#migration-checklist](docs/prerequisites.md#migration-checklist) for detailed migration steps.

## Documentation

- **[SETUP.md](docs/SETUP.md)** — Deployment in phases (repository setup, Azure identities, CI/CD configuration)
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** — System design, workflow patterns, and Terraform stack explanation
- **[prerequisites.md](docs/prerequisites.md)** — Complete requirements checklist and migration guide
- **[analysis.md](docs/analysis.md)** — Full system analysis, variable inventory, and configuration reference

## Support

For issues, questions, or contributions, open an issue in this repository or contact the platform engineering team.
