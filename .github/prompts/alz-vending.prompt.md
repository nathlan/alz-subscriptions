---
name: landing-zone-vending
description: Provision a new Azure Landing Zone — collects inputs, validates, then delegates to cloud coding agent
agent: ALZ Subscription Vending
---

# Provision Azure Landing Zone

Validate the following landing zone request using **Phase 0** from your instructions. Use read-only tools to check for conflicts against the existing `terraform/terraform.tfvars` in `nathlan/alz-subscriptions`.

## Required Inputs

| Field | Value |
|-------|-------|
| **Workload Name** | ${input:workload_name:kebab-case, e.g. payments-api} |
| **Environment** | ${input:environment:Production, Development, or Test} |
| **Location** | ${input:location:Azure region, e.g. uksouth} |
| **Team Name** | ${input:team_name:GitHub team slug, e.g. payments-team} |
| **Address Space** | ${input:address_space:Prefix size only, e.g. /24} |
| **Cost Center** | ${input:cost_center:e.g. CC-4521} |
| **Team Email** | ${input:team_email:e.g. team@example.com} |
| **Repository Name** | ${input:repo_name:For OIDC federation (optional if not needed)} |

## Optional Inputs

| Field | Value |
|-------|-------|
| **Enable DevTest** | ${input:subscription_devtest_enabled:Optional, true/false (default false)} |
| **Extra Subscription Tags** | ${input:subscription_tags:Optional map, e.g. criticality=high;compliance=sox} |
| **Spoke VNet Prefix Size** | ${input:spoke_address_space_cidr:Optional, e.g. /24} |
| **Subnets Map** | ${input:spoke_subnets:Optional map, e.g. default=/26;app=/26} |
| **Budget Amount (USD)** | ${input:budget_amount:Optional, e.g. 500} |
| **Budget Threshold (%)** | ${input:budget_threshold:Optional, e.g. 80} |
| **Budget Emails** | ${input:budget_emails:Optional list, e.g. team@example.com} |

## Instructions

1. Validate each input against the rules in Phase 0
2. Read `terraform/terraform.tfvars` from `nathlan/alz-subscriptions` to check for duplicate keys and address space overlaps
3. Present a confirmation summary with all validated inputs and computed values (landing zone key, env abbreviation, prefix size)
4. Include any optional inputs that were provided; omit sections for optional inputs that were not supplied
5. After confirmation, invoke `github/create_pull_request_with_copilot` to hand off to the same `alz-vending` agent, running in the GitHub cloud coding agent context (Phase 1)
