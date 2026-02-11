# Agent Instructions Assessment Report

**Date:** 2026-02-11  
**Repository:** nathlan/alz-subscriptions  
**Agent:** alz-vending orchestrator

## Executive Summary

After analyzing the repository structure and comparing it with the agent instructions, **critical misalignments were identified** that would prevent the agent from successfully orchestrating landing zone vending. This document outlines the gaps and provides corrected guidance.

## Critical Misalignments

### 1. File-Based vs Map-Based Architecture ⚠️ BLOCKING

**Agent Instructions Assume:**
- Individual `.tfvars` files per landing zone
- Path: `landing-zones/{workload_name}.tfvars`
- Each PR adds a new file

**Repository Reality:**
- Single monolithic `terraform/terraform.tfvars` file
- Landing zones defined in a `landing_zones` map variable
- Each PR **edits** the existing file to add a new map entry

**Impact:** Agent would create files in wrong location with wrong structure.

**Corrected Approach:**
```hcl
# Instead of creating: landing-zones/{workload_name}.tfvars
# Agent should edit: terraform/terraform.tfvars

# Adding this map entry:
landing_zones = {
  # Existing entries preserved...
  
  payments-api-prod = {  # New entry
    workload = "payments-api"
    env      = "prod"
    team     = "payments-team"
    location = "uksouth"
    
    subscription_tags = {
      cost_center = "CC-4521"
      owner       = "payments-team"
    }
    
    spoke_vnet = {
      ipv4_address_spaces = {
        default_address_space = {
          address_space_cidr = "/24"
          subnets = {
            default = {
              subnet_prefixes = ["/26"]
            }
            app = {
              subnet_prefixes = ["/26"]
            }
          }
        }
      }
    }
    
    budget = {
      monthly_amount             = 500
      alert_threshold_percentage = 80
      alert_contact_emails       = ["payments-team@example.com"]
    }
    
    federated_credentials_github = {
      repository = "payments-api"
    }
  }
}
```

### 2. Module Version & Capabilities Out of Date

**Agent Instructions State:**
- Module v1.0.3 is current
- v1.0.4 is pending PR merge
- v3.0.0 will introduce `landing_zones` map (planned/breaking change)

**Repository Reality:**
- Module **v1.0.4** is already deployed (`terraform/main.tf:41`)
- The `landing_zones` map interface **already exists**
- Auto-generated naming is already operational
- Automatic address space calculation is already available

**Impact:** Agent recommendations would reference outdated interfaces.

**Correction:** Update module version references to v1.0.4 and document actual capabilities.

### 3. Address Space Format Mismatch

**Agent Instructions Generate:**
```hcl
address_space = ["10.100.0.0/24"]  # Full CIDR
```

**Repository Expects:**
```hcl
address_space_cidr = "/24"  # Prefix size only
```

**Why:** The module uses automatic address space calculation. It takes a base `azure_address_space` (e.g., `10.100.0.0/16`) and automatically carves out subnets using the prefix sizes provided.

**Impact:** Agent-generated configuration would fail validation.

### 4. Workflow Generation Not Required

**Agent Instructions:**
- Phase 2: Handoff to `github-config` agent for repo Terraform
- Phase 3: Handoff to `cicd-workflow` agent for workflow generation

**Repository Reality:**
- This repo already has `terraform-deploy.yml` workflow
- It's a **child workflow** calling `nathlan/.github-workflows`
- No per-LZ workflow generation needed
- Workload repos are created separately (not part of LZ vending here)

**Impact:** Agent would unnecessarily delegate to other agents.

**Correction:** 
- Remove Phase 2 & 3 for this repo
- Optionally: After LZ is provisioned, offer to create a workload repo (separate process)

### 5. Resource Naming Auto-Generation

**Agent Instructions:**
- Agent computes resource names
- Names like `sub-{workload}-{env}`, `vnet-{workload}-{location}`

**Repository Reality:**
- Module **automatically generates** all resource names
- Uses internal Azure naming module
- Agent should NOT specify names
- Agent only provides: `workload`, `env`, `team`, `location`

**Impact:** Agent would generate redundant/conflicting naming instructions.

### 6. State File Location

**Agent Instructions:**
```
state_container: "alz-subscriptions"
```

**Repository Reality:**
```hcl
# backend.tf
container_name = "alz-subscriptions"
key            = "landing-zones/main.tfstate"  # Single state file for all LZs
```

All landing zones share **one state file**, not individual state files per LZ.

## Corrected Orchestration Flow

### Phase 0: Validate Inputs ✅ (No changes needed)

Validation logic remains correct. Continue to validate:
- workload_name (kebab-case, 3-30 chars)
- environment (Production/DevTest → env: dev/test/prod)
- location (valid Azure region)
- address_space → **convert to prefix size** (e.g., `10.100.0.0/24` → `/24`)
- team_name (GitHub team exists)
- cost_center, team_email
- CIDR overlap detection (read existing map entries)

### Phase 1: Azure Subscription PR ✅ (Modified)

**Changes Required:**

1. **Read** existing `terraform/terraform.tfvars` to get current `landing_zones` map
2. **Parse** the HCL to extract existing entries
3. **Add** new map entry with correct structure (see example above)
4. **Write** updated `terraform/terraform.tfvars` with new entry appended
5. **Create PR** with:
   - Branch: `lz/{workload_name}`
   - Title: `feat(lz): Add landing zone — {workload_name}`
   - Path: `terraform/terraform.tfvars` (NOT `landing-zones/{workload_name}.tfvars`)

### Phase 2 & 3: REMOVED ❌

These phases are not applicable to this repository:
- This repo provisions Azure infrastructure only
- GitHub repo creation is a separate process
- Workflow already exists and doesn't need per-LZ modification

### Phase 4: Track & Report ✅ (Minor changes)

Tracking issue and status checking remain valid, with adjustments:
- Remove Phase 2 & 3 references
- Simplify completion notification (no GitHub repo created here)

## Configuration Values

### Values That Need Updating

```yaml
# PLACEHOLDERS TO UPDATE:
tenant_id: "PLACEHOLDER"                     # Azure tenant ID
billing_scope: "PLACEHOLDER"                 # EA/MCA billing scope
hub_network_resource_id: "PLACEHOLDER"       # Hub VNet resource ID

# VALUES TO EXTRACT FROM REPO:
state_resource_group: "rg-terraform-state"   # From backend.tf
state_storage_account: "stterraformstate"    # From backend.tf
state_container: "alz-subscriptions"         # From backend.tf

# CORRECT VALUES:
lz_module_version: "v1.0.4"                  # Current deployed version
github_org: "nathlan"                        # Confirmed
alz_infra_repo: "alz-subscriptions"          # Confirmed
```

## Example End-to-End Flow

**User Request:**
```
@alz-vending workload_name: payments-api, environment: Production, 
location: uksouth, team_name: payments-team, address_space: 10.100.5.0/24, 
cost_center: CC-4521, team_email: payments-team@example.com
```

**Agent Actions:**

1. Validate all inputs and check for duplicates/overlaps
2. Read existing `terraform/terraform.tfvars` 
3. Generate new map entry for `payments-api-prod`
4. Edit `terraform/terraform.tfvars` to insert new entry
5. Create PR with proper title and body
6. Create tracking issue
7. Report PR and issue links to user

## Recommendations

### Immediate Actions

1. **Update agent instructions** to reflect map-based architecture
2. **Correct module version** references (v1.0.4 is current)
3. **Remove workflow generation phases** (not applicable)
4. **Update address space handling** (prefix size only)
5. **Document configuration values** needed from repository

### Future Enhancements

1. **HCL parsing:** Implement robust HCL parsing to read/modify `terraform.tfvars`
2. **CIDR calculator:** Validate overlaps and suggest available ranges
3. **Workload repo creation:** Optionally offer to create workload repo post-provisioning
4. **Status polling:** Monitor Terraform apply outputs for subscription ID/UMI client ID
5. **Integration with github-config:** After LZ ready, trigger github-config agent for workload repo

## Conclusion

The agent instructions contain **fundamental architectural mismatches** that would prevent successful operation. The repository uses a **modern map-based configuration** with automatic naming and address calculation, while the agent instructions assume a **legacy file-per-LZ approach** with manual name generation.

**Before deployment, the agent instructions MUST be updated** to align with the repository's actual architecture.

---

**Verified by:** GitHub Copilot Coding Agent  
**Date:** 2026-02-11  
**Status:** ⚠️ MISALIGNED - Updates Required
