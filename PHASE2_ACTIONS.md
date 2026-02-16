# Phase 2 Actions for Landing Zone: example-api-test

This document tracks Phase 2 actions that need to be completed for the `example-api-test` landing zone.

## Tracking Issue (Manual Creation Required)

Due to bot permission limitations, please manually create a tracking issue with the following content:

**Title:** 🏗️ Landing Zone: example-api-test

**Body:**
```markdown
## 🏗️ Landing Zone: example-api-test

| Field | Value |
|---|---|
| Workload | `example-api-test` |
| Requested by | @nathanjnorris |
| Date | 2026-02-16 |
| Environment | Test (test) |
| Location | australiaeast |
| Address Space | /24 |
| Team | @nathlan/platform-engineering |

### Progress

- [x] Requirements validated
- [x] PR created and under review — #22
- [ ] PR approved and merged
- [ ] Terraform workflow completed successfully
- [ ] Subscription provisioned (ID: _pending_)
- [ ] _(Optional)_ Workload repository created

### Key Outputs (Populated After Deployment)

| Output | Value |
|---|---|
| Subscription ID | _pending_ |
| Subscription Name | _pending_ |
| VNet Name | _pending_ |
| UMI Client ID | _pending_ |
| Budget ID | _pending_ |

### Next Actions

After merge:
1. Monitor terraform-deploy.yml workflow
2. Extract outputs from Terraform apply
3. Update this issue with resource IDs
4. _(Optional)_ Create workload repository with GitHub config agent
```

**Labels:** `landing-zone`, `tracking`

## Workload Repository Setup (Optional)

After the Terraform deployment is complete and the subscription is provisioned:

1. Use the `github-config` agent to create a new workload repository
2. Repository details:
   - **Name:** alz-test-api-repo
   - **Organization:** nathlan
   - **Template:** nathlan/alz-workload-template
   - **Visibility:** internal
   - **Description:** "Test environment for example-api workload"
   - **Topics:** ["azure", "terraform", "example-api-test"]

3. Configuration required:
   - **Team Access:**
     - platform-engineering: maintain
   
   - **Branch Protection (main):**
     - Require pull request reviews: 1 approval minimum
     - Require status checks: terraform-plan, security-scan
     - Require up-to-date branches: true
     - Require conversation resolution: true
   
   - **Environment (production):**
     - Required reviewers: platform-engineering
     - Deployment branch: main only
     - Secrets (to be populated after subscription provisioning):
       - AZURE_CLIENT_ID_PLAN = "PENDING_SUBSCRIPTION_APPLY"
       - AZURE_CLIENT_ID_APPLY = "PENDING_SUBSCRIPTION_APPLY"
       - AZURE_TENANT_ID = "{tenant_id}"
       - AZURE_SUBSCRIPTION_ID = "PENDING_SUBSCRIPTION_APPLY"

## Suggested PR Description Update

Please update PR #22 description with:

```markdown
## 🏗️ New Landing Zone: example-api-test

### Parameters

| Field | Value |
|---|---|
| Workload | `example-api-test` |
| Environment | Test (test) |
| Team | @nathlan/platform-engineering |
| Location | australiaeast |
| Address Space | /24 → /24 |
| Cost Center | COST-01 |
| Contact Email | team@example.com |

### Infrastructure Created

- **Azure Subscription:** Test tier, Corp management group
- **Virtual Network:** /24 with hub peering and automatic subnet allocation
- **User-Managed Identity:** With OIDC federation for GitHub repository `alz-test-api-repo`
- **Budget:** $500/month with 80% alert threshold
- **Auto-generated names:** Following Azure naming conventions

### Terraform Configuration

This PR adds a new entry to the `landing_zones` map in `terraform/terraform.tfvars`:
- **Key:** `example-api-test-test`
- **Workload:** `example-api-test`
- **Environment:** `test`

### Next Steps

1. Review this PR for configuration accuracy
2. Merge to trigger `terraform-deploy.yml` workflow
3. Workflow applies Terraform and provisions resources
4. Review outputs for subscription ID and identity details
5. _(Optional)_ Create workload repository via github-config agent

### Review Checklist

- [ ] Landing zone key `example-api-test-test` is unique
- [ ] Address space `/24` does not overlap with existing VNets
- [ ] Management group assignment is `Corp` (correct)
- [ ] Tags are complete and accurate
- [ ] UMI repository name matches intended workload repo
- [ ] Budget amount and threshold are reasonable
- [ ] Team exists in GitHub organization
```
