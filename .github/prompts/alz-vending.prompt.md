---
name: landing-zone-vending
description: Provision a new Azure Landing Zone — collects inputs, validates, then delegates to cloud coding agent
agent: ALZ Subscription Vending
---

# Provision Azure Landing Zone

Validate a landing zone request using **Phase 0** from your instructions. Use VS Code questions to interactively gather and confirm all inputs, then create a GitHub issue to hand off to the cloud agent.

## Workflow

### Step 1: Gather Required Inputs

Use `ask_questions` to prompt the user for each required field:

- **Workload Name** — kebab-case (e.g., `payments-api`)
- **Environment** — Choose from: `Production`, `Development`, `Test`
- **Location** — Azure region (e.g., `uksouth`)
- **Team Name** — GitHub team slug (e.g., `payments-team`)
- **Address Space** — Prefix size only (e.g., `/24`)
- **Cost Center** — Code (e.g., `CC-4521`)
- **Team Email** — Email address (e.g., `team@example.com`)
- **Repository Name** — For OIDC federation (e.g., `payments-api`)

### Step 2: Gather Optional Inputs (if applicable)

Optionally gather:
- **Enable DevTest** — `true` or `false` (defaults to `false`)
- **Extra Subscription Tags** — Map (e.g., `criticality=high;compliance=sox`)
- **Spoke VNet Prefix Size** — Prefix (e.g., `/24`)
- **Subnets Map** — Map (e.g., `default=/26;app=/26`)
- **Budget Amount** — USD (e.g., `500`)
- **Budget Threshold** — Percentage (e.g., `80`)
- **Budget Emails** — Email(s) (e.g., `team@example.com`)

### Step 3: Validate & Check for Conflicts

1. Validate all inputs against Phase 0 rules in the agent instructions
2. Use read-only GitHub MCP tools to fetch `terraform/terraform.tfvars` from `nathlan/alz-subscriptions`
3. Check for:
   - **Duplicate keys:** Compute `{workload_name}-{env}` and verify it doesn't already exist
   - **Address space overlaps:** Ensure the proposed CIDR doesn't overlap with existing landing zones

### Step 4: Present Confirmation Summary

Display a formatted summary with:
- All validated inputs
- Computed values: landing zone key, env abbreviation
- Address space allocation plan
- Any optional inputs provided

### Step 5: Confirm with User

Use `ask_questions` to ask: **"Review the configuration above. Ready to create the landing zone?**

- Options: `Yes, create the issue` / `No, cancel`
- If "No", stop and allow user to provide different inputs
- If "Yes", proceed to Step 6

### Step 6: Create GitHub Issue

Use `mcp_github_issue_write` (method: `create`) to create an issue:

```
owner: nathlan
repo: alz-subscriptions
title: "🏗️ Landing Zone Request: {workload_name} ({environment})"
labels: ["alz-vending", "landing-zone"]
body: [See Phase 0 Issue Body Template in agent instructions]
```

### Step 7: Handoff Complete

Post a final message confirming:
- Issue created and linked
- Dispatcher workflow will auto-detect the `alz-vending` label
- Cloud agent will be assigned and proceed with Phase 1 (PR creation)
- **Agent responsibility ends here** — no further action needed
