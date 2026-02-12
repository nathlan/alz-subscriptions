---
name: alz-vending
description: Provision a new Azure Landing Zone — collects inputs, validates, then delegates to cloud coding agent
agent: ALZ Subscription Vending
tools: ['read', 'search', 'github/*']
---

# Provision Azure Landing Zone

Validate the following landing zone request using **Phase 0** from your instructions. Use read-only tools to check for conflicts against the existing `terraform/terraform.tfvars` in `nathlan/alz-subscriptions`.

## Inputs

| Field | Value |
|-------|-------|
| **Workload Name** | ${input:workload_name:kebab-case, e.g. payments-api} |
| **Environment** | ${input:environment:Production, Development, or Test} |
| **Location** | ${input:location:Azure region, e.g. uksouth} |
| **Team Name** | ${input:team_name:GitHub team slug, e.g. payments-team} |
| **Address Space** | ${input:address_space:CIDR notation, e.g. /24} |
| **Cost Center** | ${input:cost_center:e.g. CC-4521} |
| **Team Email** | ${input:team_email:e.g. team@example.com} |
| **Repository Name** | ${input:repo_name:For OIDC federation} |

## Instructions

1. Validate each input against the rules in Phase 0
2. Read `terraform/terraform.tfvars` from `nathlan/alz-subscriptions` to check for duplicate keys and address space overlaps
3. Present a confirmation summary with all validated inputs and computed values (landing zone key, env abbreviation, prefix size)
4. **"Delegate to coding agent"** to proceed with provisioning ALZ subscription (Phase 1)
  