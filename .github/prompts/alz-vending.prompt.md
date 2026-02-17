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

### Step 2: Ask About Optional Configuration

Use `ask_questions` to ask if the user wants to customize optional settings:

**Question:** "Do you want to customize optional settings (subnets, budget, etc.)?"
- Options: `Use defaults` (recommended) / `Customize settings`

**If "Customize settings" selected**, gather:
- **Budget Amount** — Monthly USD (default: `500`)
- **Budget Threshold** — Alert percentage (default: `80`)
- **Additional Subnets** — Beyond default and app subnets (e.g., `data=/27;cache=/28`)
- **Extra Subscription Tags** — Additional tags (e.g., `criticality=high`)

**If "Use defaults" selected**, apply:
- Budget: $500/month with 80% threshold
- Subnets: `default` (/26) and `app` (/26)
- No extra tags

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

**IMPORTANT:** Load the GitHub MCP tool before using it:

1. First, load the tool:
   ```
   tool_search_tool_regex(pattern: "mcp_github_issue_write")
   ```

2. Then create the issue:
   ```
   mcp_github_issue_write (method: create)
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
