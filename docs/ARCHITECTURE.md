# Architecture Overview

## Overview

The **alz-vending-machine** repository provides self-service Azure Landing Zone provisioning via GitHub Agentic Workflows. This is not a full Azure Landing Zones (ALZ) implementation—it's a subscription vending machine that enables teams to request and provision complete landing zones on-demand through a conversational VS Code interface.

**Problem solved:** Organizations need a scalable, self-service way to provision production-ready Azure subscriptions with networking, identity, and budgeting configured automatically. Instead of manual tickets and delayed provisioning, teams can request landing zones via a simple GitHub-native workflow that provisions infrastructure in minutes.

---

## Core Architecture Pattern

### Map-Based Landing Zone Architecture

This repository uses a **map-based architecture** where all landing zones are configured through a single `terraform/terraform.tfvars` map, fed into a single Terraform module call. Instead of creating separate files or modules for each landing zone, everything is defined declaratively in one configuration object.

**Why this pattern?**
- **Scalability:** Add landing zones by extending the map; no file duplication
- **Consistency:** All zones conform to the same naming, addressing, and tagging schemas automatically
- **Maintainability:** Single module call is easier to audit and update than multiplied infrastructure-as-code
- **Reproducibility:** Each map entry describes the complete, idempotent landing zone specification

**Data flow diagram:**

```
┌──────────────────────────────────────────────────────────────────┐
│ terraform/terraform.tfvars                                       │
│ (Map-based landing zone configuration)                           │
│                                                                  │
│ landing_zones = {                                               │
│   example-api-prod = { ... }                                    │
│   graphql-dev = { ... }                                         │
│   ... (N landing zones)                                         │
│ }                                                                │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│ terraform/main.tf                                               │
│ module "landing_zones" (single call)                            │
│ source = terraform-azure-landing-zone-vending                   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│ Azure Resources (for each landing zone)                          │
│ • Subscriptions + Management groups                             │
│ • Virtual Networks with hub peering                             │
│ • User-Managed Identities with OIDC                             │
│ • Budgets with alert thresholds                                 │
│ • Automatic naming conventions & addressing                     │
└──────────────────────────────────────────────────────────────────┘
```

Each landing zone in the map is identified by a key (e.g., `example-api-prod`) that flows through all Terraform outputs, making it easy to reference provisioned resources downstream.

---

## Terraform Stack Design

### The Landing Zone Vending Module

The core of this repository is a single, private Terraform module:

- **Module name:** `terraform-azure-landing-zone-vending`
- **Source repository:** GitHub-hosted (currently `nathlan` organization) ⚠️
- **Action on migration:** Must be forked or mirrored to the target organization and the source URL updated

**Module responsibilities:**
- Provisions subscriptions using Azure subscription aliases and assigns them to management groups
- Creates virtual networks with configurable subnets and optional hub peering
- Deploys User-Managed Identities (UMI) with federated OIDC credentials for GitHub Actions authentication
- Creates budgets with configurable monthly amounts and alert thresholds
- Auto-generates resource names following Azure naming conventions
- Calculates VNet address spaces from a base CIDR block, distributing prefixes across landing zones

**Providers used:**

| Provider | Version | Purpose |
|----------|---------|---------|
| `azapi` | ~> 2.5 | Azure API resource management |
| `modtm` | ~> 0.3 | Module telemetry |
| `random` | >= 3.3.2 | Resource ID generation |
| `time` | >= 0.9, < 1.0 | Time-based lifecycle operations |

These providers are declared in the landing zone vending module, not in this repository.

### Input Variables

The module accepts a landing zone map alongside shared configuration:

**Required inputs:**
- `subscription_billing_scope`: ARM ID of the billing scope (required for subscription alias creation)
- `subscription_management_group_id`: Target management group for all subscriptions
- `azure_address_space`: Base CIDR (e.g., `10.100.0.0/16`) for automatic address space calculation

**Optional inputs:**
- `hub_network_resource_id`: Hub VNet resource ID for peering (null disables peering)
- `github_organization`: Organization slug for GitHub OIDC federated credentials
- `subscription_devtest_supported`: Boolean to enable DevTest subscription types for dev/test environments
- `tags`: Common tags applied to all resources

For the complete landing zone object schema and examples, see [terraform/variables.tf](../terraform/variables.tf).

---

## Self-Service Workflow (End-to-End)

The user journey from request to provisioned landing zone spans seven steps involving local and cloud agents:

```
┌────────────────────────────────────────────────────────┐
│ Step 1: Local Agent (VS Code)                          │
│ User runs /alz-vending-machine prompt → Agent collects │
│           → Validates → Creates GitHub issue            │
└────────────────┬─────────────────────────────────────┘
                 │ Issue created with alz-vending label
                 ▼
┌────────────────────────────────────────────────────────┐
│ Step 2: Dispatcher Workflow (GitHub)                   │
│ on: issues[opened] → Assigns cloud agent to issue      │
└────────────────┬─────────────────────────────────────┘
                 │ Cloud agent assigned
                 ▼
┌────────────────────────────────────────────────────────┐
│ Step 3: Cloud Agent (GitHub Copilot)                   │
│ Reads issue → Phase 1: Modifies terraform.tfvars → PR  │
└────────────────┬─────────────────────────────────────┘
                 │ PR created with configuration changes
                 ▼
┌────────────────────────────────────────────────────────┐
│ Step 4: User Reviews PR                                │
│ Platform Engineering team reviews terraform changes    │
└────────────────┬─────────────────────────────────────┘
                 │ PR merged to main
                 ▼
┌────────────────────────────────────────────────────────┐
│ Step 5: CI/CD Workflow Triggered                       │
│ on: push[main] → terraform plan/apply via workflow    │
│              → OIDC authentication to Azure            │
│              → Landing zone resources provisioned      │
└────────────────┬─────────────────────────────────────┘
                 │ Terraform apply completes
                 ▼
┌────────────────────────────────────────────────────────┐
│ Step 6: Cloud Agent Updates Tracking Issue             │
│ Phase 2: Posts deployment outputs and resource IDs     │
└────────────────┬─────────────────────────────────────┘
                 │ Issue closed
                 ▼
┌────────────────────────────────────────────────────────┐
│ Step 7: Dispatcher Handoff (github-config)             │
│ on: issues[closed] → Creates issue in github-config    │
│                 → Workload repo provisioning triggered │
└────────────────────────────────────────────────────────┘
```

Total time from request to deployed landing zone: typically 5–10 minutes after PR merge.

---

## Agent-Driven Automation (Three-Tier Model)

This repository uses **three distinct agents** operating across two execution environments (VS Code and GitHub):

### Tier 1: [Local agent] VS Code Prompt — ALZ Subscription Vending

**File:** [.github/agents/alz-vending.agent.md](.github/agents/alz-vending.agent.md)  
**Invoked via:** `/alz-vending-machine` prompt in VS Code  
**Model:** Claude Haiku 4.5 (Copilot)  
**Execution:** Synchronous, user-attended

**Phase 0 responsibilities:**
- Collect and validate user inputs (workload name, environment, region, team, device count, budget, OIDC repository)
- Read existing configuration from this repository to check for conflicts (duplicate keys, address space overlaps)
- Present confirmation summary with computed values (VNet prefix, subnet layout, cost implications)
- Create a GitHub issue with the `alz-vending` label and all validated inputs in the issue body

**Tools available:** VS Code question prompts, GitHub MCP read-only tools (search, get_file_contents)

**Out of scope:** Does NOT assign itself to the issue, does NOT create branches/PRs, does NOT interact with Azure.

### Tier 2: [Agentic Workflow] ALZ Vending Dispatcher

**File:** [.github/workflows/alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md) (+ compiled `alz-vending-dispatcher.lock.yml`)  
**Triggers:** GitHub issue events (opened, closed)  
**Engine:** GitHub Agentic Workflows (Copilot)  
**Execution:** Asynchronous, automated

**Responsibilities:**
- **Issue opened:** Read the issue labels; if `alz-vending` is present, assign the cloud agent via `assign-to-agent` safe-output
- **Issue closed:** Post a completion comment via `add-comment`, then create an issue in the `github-config` repository via `create-issue` to trigger workload repository provisioning

**Tools available:** GitHub MCP server (`issues` and `repos` toolsets), safe-output tools (assign-to-agent, add-comment, create-issue)

**Key design principle:** Uses safe-output tooling to isolate write operations, ensuring auditability and preventing unintended modifications.

### Tier 3: [Cloud coding agent] GitHub Copilot — Phase 1 & 2

**File:** [.github/agents/alz-vending.agent.md](.github/agents/alz-vending.agent.md) (same file as Tier 1, different runtime context)  
**Assigned by:** Dispatcher workflow via `assign-to-agent` safe-output  
**Model:** Claude Haiku 4.5 (Copilot)  
**Execution:** Asynchronous, runs in GitHub Actions environment

**Phase 1 responsibilities:**
- Parse the issue body to extract validated inputs
- Check for existing open PR tied to the same landing zone key
- Modify `terraform/terraform.tfvars` to add the new landing zone entry
- Create a pull request (or update existing PR) with the configuration changes

**Phase 2 responsibilities:**
- Update the triggering issue with progress status during `terraform apply`
- Post deployment outputs: subscription IDs, resource IDs, UMI client IDs, VNet details
- Close the issue once deployment completes

**Tools available:** GitHub MCP (repos, contents, pull requests), file edit and search tools

**Handoff chain:** Local agent (creates issue) → Dispatcher (assigns cloud agent) → Cloud agent (Phase 1: modifies tfvars, creates PR) → User merges PR → CI/CD runs terraform → Cloud agent (Phase 2: updates issue with outputs)

---

## Authentication & Identity Model

### OIDC-Based Zero-Trust Architecture

Authentication follows the principle of **federated identity** — GitHub Actions proves its identity to Azure via OpenID Connect (OIDC), exchanging a GitHub-issued token for a short-lived Azure access token.

**Why OIDC over static credentials?**
- No long-lived secrets stored in GitHub (eliminates credential rotation burden)
- Tokens are scoped to specific repository, environment, and workflow context
- Enables fine-grained RBAC: separate identities for read (plan) vs. write (apply) operations

### Separate Identities for Plan vs. Apply

The architecture uses **three separate Azure App Registrations:**

1. **Plan Identity** (Reader role on target subscription)
   - Used by `terraform plan` step
   - Federated credential: GitHub Actions in environment `prod`, workflow `Azure Terraform CI/CD`
   - Client ID stored in repo variable: `AZURE_CLIENT_ID_PLAN`

2. **Apply Identity** (Owner role on target subscription)
   - Used by `terraform apply` step
   - Federated credential: Same GitHub Actions context as Plan identity
   - Client ID stored in repo variable: `AZURE_CLIENT_ID_APPLY`

3. **State Storage Identity** (Storage Account permissions)
   - Used to access the Terraform state backend (Azure Storage blob)
   - Client ID stored in org-level variable: `AZURE_CLIENT_ID_TFSTATE`
   - Scoped to the state storage account only

**Why separate identities?** Principle of least privilege. If the plan identity were compromised, it cannot modify resources (Reader-only). If the state storage identity were compromised, it cannot modify the landing zones themselves.

### Federated Credential Configuration

Each identity requires a federated credential linking the GitHub repository and workflow to Azure. The subject pattern is:

```
repo:<owner>/<repo>:environment:<environment>
```

For this repository migrating to `insight-agentic-platform-project`, the pattern becomes:

```
repo:insight-agentic-platform-project/alz-vending-machine:environment:prod
```

See [docs/SETUP.md](./SETUP.md) for detailed Azure configuration steps.

---

## Data Flow & Configuration

### Landing Zone Configuration Structure

Each entry in the `terraform/terraform.tfvars` map describes a complete landing zone:

```hcl
landing_zones = {
  "example-api-prod" = {
    workload = "example-api"
    env      = "prod"
    team     = "platform-engineering"
    location = "australiaeast"
    
    subscription_tags = { cost_center = "CC-01" }
    
    spoke_vnet = {
      ipv4_address_spaces = {
        default_address_space = {
          vnet_address_space_prefix = "/23"
          subnets = {
            workload = { subnet_prefixes = ["/27", "/26"] }
          }
        }
      }
    }
    
    budget = {
      monthly_amount             = 500
      alert_threshold_percentage = 80
      alert_contact_emails       = ["team@example.com"]
    }
    
    federated_credentials_github = { repository = "example-api-prod" }
  }
}
```

### Automatic Configuration Features

**Naming Convention:** The module auto-generates resource names using the landing zone key and a naming prefix. All subscriptions, VNets, and managed identities follow Azure naming conventions (lowercase, hyphens, region abbreviations).

**Address Space Calculation:** Given a base CIDR (e.g., `10.100.0.0/16`), the module automatically distributes address spaces to each landing zone, calculating VNet prefixes and subnet ranges based on the specified device counts. This eliminates manual CIDR planning and prevents address space collisions.

**Output Structure:** All Terraform outputs are keyed by landing zone identifier:
- `subscription_ids["example-api-prod"]` → The provisioned subscription ID
- `virtual_network_resource_ids["example-api-prod"]` → The VNet ARM resource ID
- `umi_client_ids["example-api-prod"]` → The UMI client ID for OIDC (marked sensitive)
- `budget_resource_ids["example-api-prod"]` → The budget ARM resource ID

This keyed structure makes it trivial to cross-reference resources and feed them into downstream provisioning workflows.

---

## DevContainer & Developer Experience

The [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json) provides a pre-configured development environment with all necessary tools:

**Pre-installed tools:**
- Docker CLI (Docker-out-of-Docker, for testing and local container runs)
- Terraform CLI (with `terraform fmt` on save)
- Python 3.11 (for scripts and custom logic)
- Node.js LTS (for GitHub CLI extensions and automation)
- Git (latest version)
- GitHub CLI `gh` (for local issue/PR creation and authentication)

**VS Code extensions:**
- HashiCorp Terraform (syntax highlighting, validation, formatting)
- Python + Pylance (type checking and linting)
- GitHub Copilot + Copilot Chat (agentic coding, chat interface)
- GitHub Pull Requests (inline PR review)

**Customizations:**
- Terraform formatting on save (via `editor.formatOnSave`)
- Copilot coding agent UI integration enabled
- Python linting configured

**Developer workflow:** A developer can clone this repository, open it in VS Code, and immediately run `/alz-vending-machine` to request a landing zone. No manual tool installation, credential setup, or environment configuration required.

---

## External Dependencies

### Private Terraform Module

The `terraform-azure-landing-zone-vending` module is a private GitHub-hosted module. It must exist in the target organization before this repository can be deployed.

**Migration action:** Fork or mirror the module repository to the target org and update [terraform/main.tf](../terraform/main.tf) with the new module source URL.

### Reusable Workflows Repository

**Repository:** `shared-assets` (contains the parent `azure-terraform-cicd-reusable.yml`)  
**Referenced in:** [.github/workflows/azure-terraform-cicd-caller.yml](.github/workflows/azure-terraform-cicd-caller.yml)  
**Purpose:** Encapsulates the common Terraform plan/apply logic (linting, formatting, security scanning, Azure authentication, state management)

**Migration action:** Fork or mirror the `shared-assets` repository and update the `uses` reference in the caller workflow.

### Configuration Repository (github-config)

**Repository:** `github-config`  
**Referenced in:** [.github/workflows/alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md) (frontmatter: `create-issue` safe-output target)  
**Purpose:** Receives workload repository provisioning requests when landing zones are successfully deployed

**Migration action:** Fork or mirror to target org; dispatcher workflow will create issues there.

### Repository Template (alz-workload-template)

**Type:** GitHub repository template  
**Purpose:** Used as the template when provisioning workload-specific repositories for teams that request landing zones  
**Migration action:** Create or designate a template repository in the target organization

---

## Org-Specific References (Migration Callouts)

The following values reference the source organization (`nathlan`) and **must** be updated when migrating to the target organization (`insight-agentic-platform-project`):

⚠️ **Module source** ([terraform/main.tf](../terraform/main.tf)):
```
Current:  github.com/nathlan/terraform-azure-landing-zone-vending?ref=v1.0.0
Update:   github.com/insight-agentic-platform-project/terraform-azure-landing-zone-vending?ref=v1.0.0
```

⚠️ **Reusable workflow reference** ([.github/workflows/azure-terraform-cicd-caller.yml](.github/workflows/azure-terraform-cicd-caller.yml)):
```
Current:  nathlan/shared-assets/.github/workflows/azure-terraform-cicd-reusable.yml@main
Update:   insight-agentic-platform-project/shared-assets/.github/workflows/azure-terraform-cicd-reusable.yml@main
```

⚠️ **Dispatcher cross-repo target** ([.github/workflows/alz-vending-dispatcher.md](.github/workflows/alz-vending-dispatcher.md) frontmatter):
```
Current:  create-issue target-repo: "nathlan/github-config"
Update:   create-issue target-repo: "insight-agentic-platform-project/github-config"
```

⚠️ **Agent repository references** ([.github/agents/alz-vending.agent.md](.github/agents/alz-vending.agent.md)):
```
Current:  nathlan/alz-subscriptions
Update:   insight-agentic-platform-project/alz-vending-machine

Current:  nathlan/github-config
Update:   insight-agentic-platform-project/github-config

Current:  nathlan/alz-workload-template
Update:   insight-agentic-platform-project/alz-workload-template
```

⚠️ **Prompt repository reference** ([.github/prompts/alz-vending.prompt.md](.github/prompts/alz-vending.prompt.md)):
```
Current:  nathlan/alz-subscriptions
Update:   insight-agentic-platform-project/alz-vending-machine
```

⚠️ **Terraform configuration** ([terraform/terraform.tfvars](../terraform/terraform.tfvars)):
```
Current:  github_organization = "nathlan"
Update:   github_organization = "insight-agentic-platform-project"
```

These updates ensure federated OIDC credentials and cross-repo automation point to the correct organization and repositories in the target environment.

---

## Next Steps

For complete setup and deployment instructions, see [docs/SETUP.md](./SETUP.md). For the current configuration status and what still needs to be completed, see [docs/prerequisites.md](./prerequisites.md).
