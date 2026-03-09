## Azure Landing Zone Vending Machine

![Terraform](https://img.shields.io/badge/terraform-~%3E%201.10-623ce4?logo=terraform)
![Provider: azapi](https://img.shields.io/badge/provider-azapi%20~%3E%202.5-0078d4)
![Provider: modtm](https://img.shields.io/badge/provider-modtm%20~%3E%200.3-0078d4)

The **Azure Landing Zone Vending Machine** is a self-service platform for provisioning complete Azure Landing Zones through a map-based Terraform configuration, GitHub Agentic Workflows, and optional VS Code agents. Submit a landing zone request; the system automates subscription creation, virtual network provisioning, managed identity setup with OIDC federation, budget alerts, and role assignments—scaling from single zones to hundreds without code duplication.

### Quick Start

**New to this repository?** Start with [SETUP.md](docs/SETUP.md) for step-by-step deployment instructions.

### What You'll Need

- **Azure prerequisites:** Billing scope, management group hierarchy, optional hub virtual network
- **GitHub:** Organization with Copilot, Azure Credentials (OIDC-federated user-managed identities)
- **Terraform state:** Azure Storage Account for remote state (configured at `terraform init` time)
- **Module fork:** Private `terraform-azurerm-landing-zone-vending` module (fork from source into your org)

Learn more: [Prerequisites](docs/prerequisites.md) | [Architecture](docs/ARCHITECTURE.md)

### Agent Workflows

This repository orchestrates landing zone provisioning through three agent component types:

#### [Local agent] alz-vending
VS Code-based interactive prompt (`/alz-vending`) for collecting landing zone requests. Validates inputs, retrieves GitHub user context, and creates issues with `alz-vending` label for dispatcher assignment.

#### [Agentic Workflow] ALZ Vending Dispatcher
Listens for issue open events, detects `alz-vending` label, and assigns the cloud coding agent. On closure, orchestrates cross-repository handoff of outputs (subscription IDs, UMI credentials, VNet IDs) to workload repositories.

#### [Cloud coding agent] alz-vending
Reads issue details, updates `terraform.tfvars` with new landing zone map entries, creates pull request, and awaits review/merge. Uses Terraform validation for configuration schema enforcement.

### Developer Experience

This repository includes a **DevContainer** (`/.devcontainer/devcontainer.json`) preconfigured with:

- **Terraform:** Latest CLI with language server support
- **Providers:** Azure API, modtm, random, time
- **Tools:** Docker, GitHub CLI, Node.js, Python 3.11
- **VS Code extensions:** Terraform, Copilot Chat, GitHub PR management

Start coding immediately with `devcontainer open` — no local Terraform installation required.

### Repository Structure

```
alz-subscriptions/
├── terraform/              # Infrastructure as code
│   ├── main.tf             # Module invocation (landing-zone-vending)
│   ├── variables.tf        # Input schemas
│   ├── outputs.tf          # Outputs (subscription IDs, VNet info)
│   ├── versions.tf         # Provider constraints
│   ├── terraform.tfvars    # Landing zone map configuration
│   ├── checkov.yml         # Security scanning
│   └── .tflint.hcl         # Linting rules
├── .github/
│   ├── agents/             # Custom Copilot agent definitions
│   │   └── alz-vending.agent.md
│   ├── workflows/          # [Agentic Workflows marked below]
│   │   ├── alz-vending-dispatcher.md        # ⚡ Agentic Workflow
│   │   ├── alz-vending-dispatcher.lock.yml  # Compiled GitHub Actions (auto-gen)
│   │   ├── terraform-deploy.yml             # Infrastructure deployment
│   │   └── copilot-setup-steps.yml          # Setup utility
│   ├── prompts/            # VS Code prompt templates
│   ├── instructions/       # Codebase conventions (Terraform, Markdown, CI/CD)
│   └── aw/                 # Agentic workflow configuration
├── docs/
│   ├── SETUP.md            # Deployment guide (start here)
│   ├── ARCHITECTURE.md     # Design deep-dive
│   ├── prerequisites.md    # Required Azure/GitHub resources
│   └── analysis.md         # Repository structure analysis
├── .devcontainer/          # Development environment
│   ├── devcontainer.json
│   └── setup.sh
└── README.md               # This file
```

### Configuration: Landing Zone Map

All landing zones are defined in a single map in `terraform/terraform.tfvars`. The Terraform module processes all entries in one invocation:

| Field | Type | Example | Description |
|-------|------|---------|-------------|
| `subscription_billing_scope` | string | `/providers/Microsoft.Billing/billingAccounts/{id}/agreementType/EnterpriseAgreement` | Azure billing scope for subscription alias creation |
| `subscription_management_group_id` | string | `Corp` or UUID | Management group for landing zone association |
| `hub_network_resource_id` | string | `/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{name}` | Hub virtual network for spoke peering (optional) |
| `github_organization` | string | `insight-agentic-platform-project` | GitHub org for OIDC federated credentials |
| `landing_zones[*].workload` | string | `example-api-prod` | Workload identifier |
| `landing_zones[*].env` | string | `dev` / `test` / `prod` | Environment designation |
| `landing_zones[*].team` | string | `platform-engineering` | Owning team name |

### Migration Notice

This repository references a **private Terraform module** (`terraform-azurerm-landing-zone-vending`) originally in `nathlan` organization. Before deployment, fork the module into `insight-agentic-platform-project` and update all module source references. See [SETUP.md](docs/SETUP.md) for migration checklist.

### Related Documentation

- **[SETUP.md](docs/SETUP.md)** — Complete deployment walkthrough
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** — System design and lifecycle
- **[Prerequisites](docs/prerequisites.md)** — Azure & GitHub resource requirements
- **[Analysis](docs/analysis.md)** — Repository structure deep-dive
