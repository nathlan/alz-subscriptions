## Architecture Purpose

This repository implements a centralized Azure Landing Zone subscription vending model
using Terraform and GitHub Actions. The design favors consistency over per-workload
customization by placing shared controls, identity, networking intent, and lifecycle
automation behind one root module and one deployment pipeline.

## Architecture at a Glance

The core pattern is map-based: many landing zones are declared as entries in one
`landing_zones` map, then provisioned through a single module invocation.

```text
Request Source
   │
   ├─ Standard flow: Git change (PR to main)
   └─ Optional flow: Issue with "alz-vending" label (agent-assisted)
                         │
                         ▼
                terraform.tfvars (landing_zones map)
                         │
                         ▼
                 Root Terraform module
                         │
                         ▼
    terraform-azurerm-landing-zone-vending (external module)
                         │
                         ▼
   Azure resources + remote state + Terraform outputs
                         │
                         ▼
                CI/CD status + surfaced outputs
```

## Map-Based Architecture Pattern

The repository uses one shared configuration surface for all landing zones:

- Common settings are global (billing scope, management group, hub network ID,
  GitHub organization, base address space, common tags).
- Each landing zone is a keyed object in `landing_zones`.
- Required per-zone identity fields are `workload`, `env`, `team`, and `location`.
- Optional per-zone blocks include:
  - network (`dns_servers`, `spoke_vnet`)
  - budget
  - GitHub federated credential config

This pattern keeps topology declarative: adding or changing a landing zone is a data
change in the map, not a new Terraform stack.

## Landing Zone Lifecycle Model

The operational lifecycle follows this chain:

**request → PR → merge → deploy → outputs**

How this maps in the repo:

- **Request**: a landing zone change is proposed as Terraform configuration change
  (or optionally created via the issue-driven agent flow).
- **PR**: pull requests to `main` trigger plan validation through the deployment
  workflow.
- **Merge**: merge to `main` re-triggers the same deployment workflow.
- **Deploy**: the child workflow delegates execution to a reusable parent workflow.
- **Outputs**: module outputs expose IDs, names, network address spaces, identities,
  budget IDs, and calculated prefixes.

This lifecycle makes Git the control plane and Terraform outputs the post-deploy
contract.

## Module Design and Provisioning Scope

The root module is intentionally thin: it passes global inputs and the landing zone map
to one external module pinned at `v1.0.6`. The scope described in repository comments
and docs includes:

- subscription creation and management group association
- virtual network and hub peering intent
- user-managed identity and federated credential inputs
- role-assignment-related identity outputs
- optional budget resources
- auto-generated naming handled by the module

Design implication: the repository is an orchestration boundary, while most resource
construction logic lives in the versioned module dependency.

## State Management (Single State)

State is centralized in one Azure Storage backend configuration:

- backend type: `azurerm`
- OIDC enabled (`use_oidc = true`)
- one container/key path (`landing-zones/main.tfstate`) for all landing zones

This is a **single-state model**: every landing zone map entry contributes to the same
state file lineage. It simplifies unified planning and output visibility, while also
making state integrity and review discipline critical.

## OIDC Trust and Identity Model (Dual Plan/Apply Identities)

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
  `nathlan/.github-workflows`.
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
