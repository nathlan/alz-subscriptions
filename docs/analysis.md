## Repository Analysis

## Repository Structure

```text
.
├── .devcontainer/
│   ├── devcontainer.json
│   └── setup.sh
├── .github/
│   ├── agents/
│   │   ├── alz-vending.agent.md
│   │   ├── documentation-conductor.agent.md
│   │   └── se-technical-writer.agent.md
│   ├── aw/
│   │   ├── actions-lock.json
│   │   └── logs/
│   │       └── .gitignore
│   ├── instructions/
│   │   ├── github-actions-ci-cd-best-practices.instructions.md
│   │   ├── markdown.instructions.md
│   │   └── terraform.instructions.md
│   ├── prompts/
│   │   ├── alz-vending.prompt.md
│   │   ├── architecture-blueprint-generator.prompt.md
│   │   ├── documentation-writer.prompt.md
│   │   └── readme-blueprint-generator.prompt.md
│   └── workflows/
│       ├── alz-vending-dispatcher.lock.yml
│       ├── alz-vending-dispatcher.md
│       ├── copilot-setup-steps.yml
│       └── terraform-deploy.yml
├── docs/
│   └── analysis.md
├── terraform/
│   ├── .tflint.hcl
│   ├── backend.tf
│   ├── checkov.yml
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   └── versions.tf
├── .gitattributes
├── .gitignore
├── .pre-commit-config.yaml
└── README.md
```

## Terraform Stack

| Component | Detail |
|-----------|--------|
| Terraform Version | `~> 1.10` |
| Providers | `Azure/azapi ~> 2.5`, `Azure/modtm ~> 0.3`, `hashicorp/random >= 3.3.2`, `hashicorp/time >= 0.9, < 1.0` |
| Backend | `azurerm` with OIDC enabled (`use_oidc = true`) |
| Backend Resource Group | `rg-terraform-state` |
| Backend Storage Account | `stterraformstate` |
| Backend Container | `alz-subscriptions` |
| Backend Key | `landing-zones/main.tfstate` |
| Module Source | `github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6` |
| State File | `landing-zones/main.tfstate` |
| Checkov Config | Terraform-only scan, no external module download, skip `CKV_TF_1`, SARIF + CLI output, `soft-fail: false` |

## Variables Inventory

| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `subscription_billing_scope` | `string` | None | Yes | Billing scope for subscription alias creation |
| `subscription_management_group_id` | `string` | None | Yes | Management group ID for all subscriptions |
| `hub_network_resource_id` | `string` | `null` | No | Hub VNet resource ID for spoke peering |
| `github_organization` | `string` | `null` | No | GitHub organization name used for federation settings |
| `azure_address_space` | `string` | None | Yes | Base CIDR used for automatic address allocation |
| `tags` | `map(string)` | `{}` | No | Common tags applied across resources |
| `landing_zones` | `map(object(...))` | None | Yes | Landing zone map with required identity fields and optional network, budget, and OIDC blocks |

## Current Configuration (terraform.tfvars)

| Setting | Value | Status |
|---------|-------|--------|
| `subscription_billing_scope` | `PLACEHOLDER_BILLING_SCOPE` | Placeholder |
| `subscription_management_group_id` | `Corp` | Real |
| `hub_network_resource_id` | `PLACEHOLDER_HUB_VNET_ID` | Placeholder |
| `github_organization` | `nathlan` | Real |
| `azure_address_space` | `10.100.0.0/16` | Real |
| `tags.managed_by` | `terraform` | Real |
| `tags.environment_type` | `production` | Real |
| Landing zone keys | `example-api-prod`, `graphql-dev`, `vending-demo-test`, `one-made-earlier-test`, `alz-vartika-test-test` | Real |
| Budget shape | `monthly_amount=500`, `alert_threshold_percentage=80` across entries | Real |

## Outputs Inventory

| Output | Description | Sensitive |
|--------|-------------|-----------|
| `subscription_ids` | Landing zone key to subscription ID map | No |
| `subscription_resource_ids` | Landing zone key to subscription resource ID map | No |
| `landing_zone_names` | Landing zone key to generated subscription name map | No |
| `virtual_network_resource_ids` | Landing zone key to VNet resource ID map | No |
| `virtual_network_address_spaces` | Landing zone key to VNet CIDR map | No |
| `resource_group_resource_ids` | Landing zone key to resource group ID map | No |
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
