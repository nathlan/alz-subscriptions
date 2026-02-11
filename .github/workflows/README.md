# GitHub Actions Workflows

## Overview

This repository implements a **single-workload deployment pattern** that follows the centralized workflow architecture from `alz-workload-template`, managing a single Azure Landing Zone through standard Terraform configuration in the `terraform/` directory.

## Architecture

### Standard Terraform Pattern

Our workflows follow the standard Terraform directory structure pattern from `nathlan/.github-workflows`:

```
┌─────────────────────────────────────────────────┐
│  Discovery Phase                                │
│  • Verifies terraform/ directory exists         │
│  • Checks terraform.tfvars is present           │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Validation & Security (Centralized Pattern)    │
│  • Terraform fmt, validate                      │
│  • TFLint static analysis                       │
│  • Checkov security scanning                    │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Plan/Apply Phase                               │
│  • Runs terraform plan/apply in terraform/      │
│  • Uses terraform.tfvars automatically          │
│  • Follows centralized deployment patterns      │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Reporting                                      │
│  • Posts results to PR or tracking issues       │
│  • Provides deployment status                   │
└─────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Standard Directory Structure**: All Terraform files reside in the `terraform/` directory, following the pattern expected by reusable workflows.

2. **Centralized Validation**: Validation and security checks run for the Terraform configuration, following the efficiency pattern from centralized workflows.

3. **Single Workload**: Configuration is managed through a single `terraform.tfvars` file that Terraform loads automatically.

## Workflows

### terraform-plan.yml

**Trigger**: Pull requests to `main` branch

**Purpose**: Validate and plan changes before merge

**Jobs**:
1. **discover**: Verifies terraform.tfvars exists
2. **validate**: Runs format check, validation, and TFLint (centralized pattern)
3. **security**: Executes Checkov security scanning (centralized pattern)
4. **plan**: Generates deployment plan
5. **summary**: Posts results as PR comment

**Features**:
- ✅ Standard Terraform directory structure
- ✅ Automatic terraform.tfvars loading
- ✅ PR comments with plan details
- ✅ Plan artifacts uploaded for reference
- ✅ Follows validation patterns from centralized workflows

### terraform-apply.yml

**Trigger**: Push to `main` branch or manual dispatch

**Purpose**: Deploy the landing zone to Azure

**Jobs**:
1. **discover**: Verifies terraform.tfvars exists
2. **apply**: Deploys the configuration with environment protection
3. **summary**: Posts results to tracking issues

**Features**:
- ✅ Environment protection on `azure-landing-zones` environment
- ✅ Apply outputs uploaded as artifacts (90-day retention)
- ✅ Automatic notification to tracking issues
- ✅ Detailed summary in workflow job summary

## Configuration Management

### Directory Structure

```
alz-subscriptions/
├── terraform/
│   ├── .terraform-version
│   ├── backend.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars          # Configuration
├── README.md
└── .github/
    └── workflows/
        ├── terraform-plan.yml
        └── terraform-apply.yml
```

### Updating Configuration

Modify `terraform/terraform.tfvars` to change the landing zone configuration:

```bash
# Edit configuration
vim terraform/terraform.tfvars

# Commit and push
git add terraform/terraform.tfvars
git commit -m "Update landing zone configuration"
git push
```

The workflows will automatically validate and plan the changes.

## Comparison with alz-workload-template

### Similarities (Centralized Pattern Reuse)

| Feature | alz-workload-template | alz-subscriptions |
|---------|----------------------|-------------------|
| Validation Steps | ✅ fmt, validate, TFLint | ✅ Same patterns |
| Security Scanning | ✅ Checkov | ✅ Same patterns |
| OIDC Authentication | ✅ Azure Login | ✅ Same patterns |
| PR Comments | ✅ Automated | ✅ Automated |
| Environment Protection | ✅ Required | ✅ Required |
| Artifact Upload | ✅ Plans & Reports | ✅ Plans & Apply outputs |

### Differences (Single vs Multi-Workload)

| Aspect | alz-workload-template | alz-subscriptions |
|--------|----------------------|-------------------|
| Workload Count | Single | Single |
| Discovery | Static | Verification |
| Deployment | Direct reusable workflow call | Standard Terraform pattern |
| Directory Structure | terraform/ | terraform/ |
| Configuration | terraform.tfvars | terraform.tfvars |

### Why Not Direct Reusable Workflow Calls?

This repository follows the same patterns as the centralized reusable workflow (located in the `nathlan/.github-workflows` repository), implementing them directly to provide:
- ✅ Same security and quality standards
- ✅ Same deployment patterns
- ✅ Easier debugging (workflow in same repo)
- ✅ Standard Terraform directory structure

## Environment Configuration

### Required Secrets

Configure these in GitHub repository settings → Secrets and variables → Actions:

```yaml
AZURE_CLIENT_ID:          # Azure Service Principal Client ID (for OIDC)
AZURE_TENANT_ID:          # Azure Tenant ID
AZURE_SUBSCRIPTION_ID:    # Azure Subscription ID (for backend/auth)
```

### Required Environment

Create an environment named `azure-landing-zones` with:
- Protection rules (e.g., required reviewers for production)
- Deployment branch rules (only `main` branch)
- Secret scoping if using environment-specific secrets

### Terraform Backend

Configure in `terraform/backend.tf`:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "alz-subscriptions"
    key                  = "landing-zones/main.tfstate"
    use_oidc             = true
  }
}
```

## Monitoring & Debugging

### Workflow Runs

View all workflow runs: **Actions** tab → Select workflow

### Individual Job Status

In the workflow run, view the job status:
- ✅ Green checkmark = Success
- ❌ Red X = Failed
- 🟡 Yellow dot = In progress

### Artifacts

Download artifacts for detailed analysis:
- **Plan outputs**: Available for 30 days after PR
- **Apply outputs**: Available for 90 days after deployment
- **Security reports**: Checkov XML reports

### PR Comments

Each PR receives:
1. **Validation results** comment (fmt, validate, TFLint status)
2. **Plan comment** with deployment preview
3. **Summary comment** with status

## Best Practices

### Pull Request Workflow

1. Create feature branch
2. Modify Terraform code or update `terraform/terraform.tfvars`
3. Push changes and open PR
4. Review automated plan results in PR comments
5. Address any validation or security issues
6. Request human review
7. Merge to `main` when approved

### Security

- ✅ Never commit secrets to `terraform.tfvars`
- ✅ Use Azure Key Vault references for sensitive data
- ✅ Review Checkov results before merging
- ✅ Require environment approval for production deployments

## Troubleshooting

### "No terraform.tfvars found"

**Cause**: Discovery job didn't find `terraform/terraform.tfvars`

**Solution**: 
```bash
# Verify file exists
ls -la terraform/terraform.tfvars

# Ensure file is in the terraform/ directory
```

### Plan/Apply Job Fails

**Cause**: Invalid Terraform configuration or Azure authentication issue

**Solution**:
1. Check job logs for specific error
2. Verify Azure credentials are configured
3. Test locally: `cd terraform && terraform plan`

### Job Shows "skipped"

**Cause**: Discovery job found no configuration or dependency job failed

**Solution**:
1. Check discovery job output
2. Verify validation/security jobs passed
3. Review conditional: `if: needs.discover.outputs.workload-count != '0'`

## Future Enhancements

### Potential Improvements

1. **Change Detection**: Only run when Terraform files change
2. **Drift Detection**: Scheduled workflow to detect configuration drift
3. **Cost Estimation**: Integrate Infracost for cost impact analysis
4. **Direct Reusable Workflow**: Call centralized workflows directly

### Contributing

When modifying workflows:
1. Test in a feature branch first
2. Verify the deployment processes correctly
3. Check PR comments format properly
4. Update this README with any changes
5. Follow the centralized patterns from `nathlan/.github-workflows`

## Support

For issues or questions:
- Review workflow run logs in Actions tab
- Check artifact outputs for detailed error messages
- Consult centralized workflow documentation: `nathlan/.github-workflows`
- Open an issue in this repository

---

**Key Takeaway**: These workflows follow centralized workflow patterns for standard Terraform deployments while maintaining the same quality, security, and deployment standards.
