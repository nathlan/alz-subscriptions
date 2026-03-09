---
name: alz-vending-machine
description: Provision a new Azure Landing Zone — collects inputs, validates, then delegates to cloud coding agent
agent: ALZ Subscription Vending
model: Claude Haiku 4.5 (copilot)
---

# Provision Azure Landing Zone

Validate a landing zone request using **Phase 0** from your instructions. Use VS Code questions to interactively gather and confirm all inputs, then create a GitHub issue to hand off to the cloud agent.

## Workflow

### Step 1: Gather Required Inputs

Use `ask_questions` to prompt the user for each required field **one at a time**:

1. "What is the name of the workload being deployed to Azure?" _(kebab-case, 3-30 chars, e.g. `payments-api`)_
2. "Which environment will this landing zone be used for?" _(i.e. `dev`, `test`, or `prod`)_
3. "Which Azure region will this landing zone be deployed to?" _(e.g. `australiaeast`, `newzealandnorth`)_
4. "What is your GitHub team's slug?" _(e.g. `finance-engineering`)_
5. "How many devices do you expect to connect to this landing zone?" _(positive integer, e.g. `120`)_
6. "What is your cost center code?" _(e.g. `CC-4521`)_
7. "What email should budget alerts be sent to?" _(e.g. `team_mailbox@example.com`)_

### Step 2: Walk Through Optional Settings

After gathering required inputs, walk the user through each optional setting **individually**. For each one, present the current default value and ask if they want to change it.

**2a. Budget (Amount & Threshold)**
> "Monthly budget is **$1000 USD** with an alert when spending exceeds **80%**. Do you want to change either?"
- Options: `Keep defaults` / `Change budget settings`
- If "Change budget settings": ask for new monthly USD amount and/or alert threshold percentage

**2b. Repository Name**
> "The landing zone's associated repository will be called **alz-{workload_name}**. Do you want to change it?"
- Options: `Keep alz-{workload_name}` / `Change name`
- If "Change name": ask for the new repository name

**2c. Subnet Layout**
> "Default subnet is `workload` with 3 usable IPs( /29 ). Would you like to define your own subnets?"
- Options: `Keep default /29` / `Define custom subnets`
- If "Define custom subnets": ask for subnet names and device counts (e.g., `workload=60;data=30;cache=15`). User-provided subnets **replace** the default entirely.

**2d. Extra Subscription Tags**
> "Do you want to add any extra tags to your subscription/landing zone?"
- Options: `No extra tags` / `Add tags`
- If "Add tags": ask for key=value pairs (e.g., `criticality=high;data_classification=internal`)

### Step 3: Validate & Check for Conflicts

1. Validate all inputs against Phase 0 rules in the agent instructions
2. Use read-only GitHub MCP tools to fetch `terraform/terraform.tfvars` from `nathlan/alz-subscriptions`
3. Check for:
   - **Duplicate keys:** Compute `{workload_name}-{env}` and verify it doesn't already exist
   - **Address space overlaps:** Ensure the calculated VNet prefix doesn't overlap with existing landing zones
   - **Subnet fit:** Every subnet prefix number must be strictly greater than the VNet prefix number (e.g. VNet /24 → subnets must be /25 or higher). Reject and re-prompt if any subnet is too large.

### Step 4: Present Confirmation Summary

Display a formatted summary table showing all values the user has provided and any computed/default values. Use this exact format:

```
## 📋 Landing Zone Configuration Summary

| Setting | Value |
|---|---|
| **Workload Name** | {workload_name} |
| **Environment** | {env} |
| **Location** | {location} |
| **Team** | {team_name} |
| **Expected Devices** | {expected_devices} |
| **Cost Center** | {cost_center} |
| **Alert Email** | {team_email} |
| | |
| **Landing Zone Key** | {workload_name}-{env} |
| **VNet Prefix (calculated)** | {vnet_prefix} |
| **Subnet Layout** | {subnet_layout} |
| **Budget** | ${budget_amount}/month (alert at {threshold}%) |
| **OIDC Repository** | {repo_name} |
| **Extra Tags** | {extra_tags or "none"} |
```

Ensure computed values (landing zone key, VNet prefix, subnet prefixes) are shown so the user can verify them before confirming.

### Step 5: Confirm with User

Use `ask_questions` to ask: **"Review the landing zone configuration above. Is it correct?"**

- Options: `Yes, submit the landing zone for deployment` / `No, cancel`
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
   title: "🏗️ Landing Zone Request: {workload_name} ({env})"
   labels: ["alz-vending", "landing-zone"]
   body: [See Phase 0 Issue Body Template in agent instructions]
   ```

### Step 7: Handoff Complete

Post a final message confirming:
- Issue created and linked
- Dispatcher workflow will auto-detect the `alz-vending` label
- Cloud agent will be assigned and proceed with Phase 1 (PR creation)
- **Agent responsibility ends here** — no further action needed
