# Azure Landing Zone Vending Machine

> **Migrating from `nathlan` to `insight-agentic-platform-project`?**  
> All organization references must be updated before deployment. See [Migration Checklist in prerequisites.md](docs/prerequisites.md#migration-checklist-for-org-change).

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.10-623ce4)](https://www.terraform.io/downloads.html)
[![azapi Provider](https://img.shields.io/badge/azapi-%3E%3D2.5-FF0000)](https://registry.terraform.io/providers/azure/azapi/latest)
[![modtm](https://img.shields.io/badge/modtm-%3E%3D0.3-4B9E45)](https://registry.terraform.io/providers/cloudposse/modtm)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Self-service Azure subscription provisioning via Terraform. Vend landing zones on-demand with a single map-based configuration, OIDC authentication, and GitHub Actions automation.

## Quick Start

1. **Setup:** Follow [docs/SETUP.md](docs/SETUP.md) to configure Azure infrastructure, OIDC identities, and GitHub secrets.
2. **Understand:** Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to learn how the vending machine works.
3. **Reference:** Check [docs/prerequisites.md](docs/prerequisites.md) for complete requirements and migration guidance.

## What You'll Need

- [ ] Azure subscription with **EA or MCA** billing enrollment
- [ ] GitHub organization: `insight-agentic-platform-project`
- [ ] Two OIDC identities (one for plan, one for apply)
- [ ] Azure Storage Backend (resource group + storage account)
- [ ] (Optional) Hub Virtual Network for spoke peering

## Agent Workflows: Copilot-Powered Provisioning

This repository includes two agent modes for requesting landing zones:

### [Local agent] ALZ Vending (`.github/prompts/alz-vending.prompt.md`, `.github/agents/alz-vending.agent.md`)
Run the `/landing-zone-vending` prompt in VS Code to invoke the **local** `ALZ Vending` agent. It collects zone requirements interactively, validates against existing zones, and creates a GitHub issue for the `ALZ Vending` **cloud coding agent**.

### [Agentic Workflow] ALZ Vending Dispatcher (`.github/workflows/alz-vending-dispatcher.prompt.md`)

### [Cloud coding agent] ALZ Vending (`.github/agents/alz-vending.agent.md`)

The custom agent updates `terraform.tfvars`, creates a PR, and coordinates the deployment. No manual intervention required after issue is created.

**Key advantage:** Unlike static IaC repositories, this vending machine automates the entire zone provisioning workflow from request to deployed subscription.

## Developer Experience

The repository includes a **DevContainer** with:
- Terraform CLI (~> 1.10) with all required providers pre-installed
- Azure CLI, GitHub CLI, Python 3, Node.js for scripting
- Auto-formatting on save (Terraform fmt)
- Copilot extensions and pre-commit hooks

Open the workspace in VS Code devcontainer for instant setup—no local installation required.

```bash
# Open in devcontainer (VS Code)
# Command Palette → "Dev Containers: Reopen in Container"
```

## How It Works

**Single configuration file** (`terraform.tfvars`) defines all landing zones as an HCL map. One module call processes the entire map, creating subscriptions, VNets, and OIDC credentials for each zone.

**Shared Terraform state** lives in Azure Storage Backend with OIDC authentication—no static secrets stored anywhere.

**Two-identity pattern** (plan + apply) enables developer self-service on PRs while restricting apply to merge-to-main, maintaining governance.

For architectural deep dive, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Configuration

Update these values in `terraform/terraform.tfvars` before deployment:

| Setting | Required | Example | Notes |
|---------|----------|---------|-------|
| `subscription_billing_scope` | Yes | `/providers/Microsoft.Billing/billingAccounts/...` | EA or MCA scope from Azure Portal |
| `subscription_management_group_id` | Yes | `/providers/Microsoft.Management/managementGroups/...` | Management group name where zones will be created |
| `hub_network_resource_id` | No | `/subscriptions/.../virtualNetworks/vnet-hub` | Hub VNet for spoke peering (skip if null) |
| `github_organization` | Yes | `insight-agentic-platform-project` | Your target GitHub organization |
| `azure_address_space` | Yes | `10.100.0.0/16` | CIDR allocation pool for landing zone VNets |

### Module Source & Workflow References

⚠️ **Update these for migration from `nathlan` to `insight-agentic-platform-project`:**

- **`terraform/main.tf` line 20:**  
  `source = "github.com/insight-agentic-platform-project/terraform-azurerm-landing-zone-vending?ref=v1.0.6"`

- **`.github/workflows/terraform-deploy.yml` line 50:**  
  `uses: insight-agentic-platform-project/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main`

## Repository Structure

```
alz-subscriptions/
├── terraform/                  # Terraform configuration
│   ├── main.tf                # Module call to landing zone vending
│   ├── variables.tf           # Input variable definitions
│   ├── terraform.tfvars       # Landing zone map (customize this)
│   ├── backend.tf             # Azure Storage backend config
│   ├── outputs.tf             # Subscription outputs
│   └── versions.tf            # Provider versions
├── .github/
│   ├── workflows/
│   │   ├── terraform-deploy.yml             # CI/CD pipeline (calls reusable pipeline)
│   │   └── alz-vending-dispatcher.lock.yml  # Cloud coding agent dispatcher (GitHub Agentic Workflow [compiled])
│   │   └── alz-vending-dispatcher.md		     # Cloud coding agent dispatcher (GitHub Agentic Workflow [definition])
│   ├── prompts/
│   │   └── alz-vending.prompt.md         # Interactive zone provisioning
│   └── instructions/          # Best practices & conventions
├── docs/
│   ├── SETUP.md              # Step-by-step setup guide
│   └── ARCHITECTURE.md       # Design explanation
└── README.md                # This file
```

## Links

- **[SETUP.md](docs/SETUP.md)** — Detailed setup: Azure infrastructure, OIDC, GitHub config, first deployment
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Design overview: map-based pattern, module chain, agent modes, OIDC model
- **[prerequisites.md](docs/prerequisites.md)** — Requirements checklist, secrets reference, networking setup, migration guidance

## License

MIT

- Analysis: [docs/analysis.md](docs/analysis.md)
- Prerequisites: [docs/prerequisites.md](docs/prerequisites.md)
- Setup guide: [docs/SETUP.md](docs/SETUP.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)