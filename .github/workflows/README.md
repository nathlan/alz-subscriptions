# GitHub Actions Workflows

## Overview

This repository implements a **multi-workload deployment pattern** that follows the centralized workflow architecture from `alz-workload-template`, adapted for managing multiple Azure Landing Zones through individual `.tfvars` files.

## Architecture

### Child Workflow Pattern (Adapted)

Our workflows demonstrate reuse of the centralized patterns from `nathlan/.github-workflows` while handling the unique requirement of processing multiple workloads:

```
┌─────────────────────────────────────────────────┐
│  Discovery Phase                                │
│  • Scans landing-zones/ directory               │
│  • Finds all .tfvars files                      │
│  • Creates matrix for parallel processing       │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Validation & Security (Centralized Pattern)    │
│  • Terraform fmt, validate                      │
│  • TFLint static analysis                       │
│  • Checkov security scanning                    │
│  • Runs once for entire codebase               │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Plan/Apply Phase (Matrix Strategy)             │
│  • Processes each workload independently        │
│  • Uses matrix to parallelize operations        │
│  • Follows centralized deployment patterns      │
│  • Each workload uses its own .tfvars file      │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Aggregation & Reporting                        │
│  • Combines results from all workloads          │
│  • Posts summary to PR or tracking issues       │
│  • Provides unified view of deployments         │
└─────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Discovery Job**: Dynamically finds all `.tfvars` files and creates a matrix, enabling flexible workload management without workflow changes.

2. **Centralized Validation**: Validation and security checks run once for the entire codebase, following the efficiency pattern from centralized workflows.

3. **Matrix Strategy**: Each workload is processed as a separate matrix job, maintaining independence while enabling parallelization.

4. **Workflow Reusability**: While we can't directly call the reusable workflow with different var files per matrix item (GitHub Actions limitation), we've replicated its patterns for consistency.

## Workflows

### terraform-plan.yml

**Trigger**: Pull requests to `main` branch

**Purpose**: Validate and plan changes for all workloads before merge

**Jobs**:
1. **discover**: Finds all `.tfvars` files and creates processing matrix
2. **validate**: Runs format check, validation, and TFLint (centralized pattern)
3. **security**: Executes Checkov security scanning (centralized pattern)
4. **plan**: Matrix job that plans each workload in parallel
5. **summary**: Aggregates results and posts comprehensive PR comment

**Features**:
- ✅ Parallel planning for faster feedback
- ✅ Individual PR comments per workload
- ✅ Aggregated summary comment
- ✅ Plan artifacts uploaded for reference
- ✅ Follows validation patterns from centralized workflows

### terraform-apply.yml

**Trigger**: Push to `main` branch or manual dispatch

**Purpose**: Deploy all workloads to Azure

**Jobs**:
1. **discover**: Finds all `.tfvars` files and creates processing matrix
2. **apply**: Matrix job that applies each workload with environment protection
3. **summary**: Aggregates results and posts to tracking issues

**Features**:
- ✅ Sequential deployment by default (safe)
- ✅ Optional parallel deployment via `workflow_dispatch` input
- ✅ Environment protection on `azure-landing-zones` environment
- ✅ Apply outputs uploaded as artifacts (90-day retention)
- ✅ Automatic notification to tracking issues
- ✅ Detailed summary in workflow job summary

**Deployment Modes**:
```yaml
# Sequential (default) - one workload at a time
max-parallel: 1

# Parallel (manual trigger) - up to 10 concurrent deployments
workflow_dispatch:
  inputs:
    parallel: true
```

## Multi-Workload Management

### Directory Structure

```
alz-subscriptions/
├── landing-zones/
│   ├── example-api-dev.tfvars      # Workload 1
│   ├── example-app-prod.tfvars     # Workload 2
│   └── ...                          # Additional workloads
├── main.tf
├── variables.tf
└── .github/
    └── workflows/
        ├── terraform-plan.yml
        └── terraform-apply.yml
```

### Adding New Workloads

Simply add a new `.tfvars` file to the `landing-zones/` directory:

```bash
# Create new workload configuration
cat > landing-zones/new-workload.tfvars <<EOF
subscription_name = "my-new-subscription"
workload_name     = "new-workload"
environment       = "dev"
EOF

# Commit and push
git add landing-zones/new-workload.tfvars
git commit -m "Add new workload configuration"
git push
```

The workflows will automatically discover and process the new workload.

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

### Differences (Multi-Workload Adaptations)

| Aspect | alz-workload-template | alz-subscriptions |
|--------|----------------------|-------------------|
| Workload Count | Single | Multiple (dynamic) |
| Discovery | Static | Dynamic matrix |
| Deployment | Direct reusable workflow call | Matrix + centralized patterns |
| Var Files | Single default | Multiple `.tfvars` files |
| Parallelization | N/A | Optional parallel processing |

### Why Not Direct Reusable Workflow Calls?

The centralized reusable workflow at `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml` doesn't support:
- Passing different var files per matrix item
- Dynamic input per matrix iteration

**Solution**: We replicate the centralized patterns (validation, security, deployment steps) directly in this repository while maintaining the same structure and practices. This provides:
- ✅ Same security and quality standards
- ✅ Same deployment patterns
- ✅ Easier debugging (workflow in same repo)
- ✅ Flexibility for multi-workload requirements

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

Configure in `backend.tf`:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<uniqueid>"
    container_name       = "tfstate"
    key                  = "alz-subscriptions.tfstate"
  }
}
```

**Note**: All workloads currently share the same state file. For isolated state per workload, you can either:
1. Configure separate backends in each `.tfvars` file using `-backend-config` flags
2. Use Terraform workspaces
3. Modify the workflows to dynamically set state keys per workload (not currently implemented)

## Monitoring & Debugging

### Workflow Runs

View all workflow runs: **Actions** tab → Select workflow

### Individual Workload Status

In the Plan/Apply job, expand the matrix to see individual workload status:
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
2. **Individual plan comments** (one per workload)
3. **Summary comment** (aggregate status)

## Best Practices

### Pull Request Workflow

1. Create feature branch
2. Modify Terraform code or add/update `.tfvars` files
3. Push changes and open PR
4. Review automated plan results in PR comments
5. Address any validation or security issues
6. Request human review
7. Merge to `main` when approved

### Workload Organization

- Use descriptive names: `{app}-{environment}.tfvars`
- Examples: `api-dev.tfvars`, `web-prod.tfvars`, `db-staging.tfvars`
- Keep related workloads together in subdirectories if needed

### Security

- ✅ Never commit secrets to `.tfvars` files
- ✅ Use Azure Key Vault references for sensitive data
- ✅ Review Checkov results before merging
- ✅ Require environment approval for production deployments

### State Management

- All workloads currently share the same Terraform state file
- For production use, consider implementing one of:
  - **Option 1**: Separate backends per workload with `-backend-config` in workflows
  - **Option 2**: Terraform workspaces (one per workload)
  - **Option 3**: Separate state files using dynamic state key configuration
- Evaluate based on your organization's state management preferences

## Troubleshooting

### "No .tfvars files found"

**Cause**: Discovery job found no `.tfvars` files in `landing-zones/` directory

**Solution**: 
```bash
# Verify files exist
ls -la landing-zones/*.tfvars

# Ensure files have .tfvars extension (not .tfvars.example)
```

### Plan/Apply Job Fails

**Cause**: Invalid Terraform configuration or Azure authentication issue

**Solution**:
1. Check job logs for specific error
2. Verify Azure credentials are configured
3. Test locally: `terraform plan -var-file=landing-zones/your-file.tfvars`

### Matrix Job Shows "skipped"

**Cause**: Discovery job found 0 workloads or dependency job failed

**Solution**:
1. Check discovery job output
2. Verify validation/security jobs passed
3. Review conditional: `if: needs.discover.outputs.workload-count != '0'`

## Future Enhancements

### Potential Improvements

1. **Conditional Workload Processing**: Only process workloads with changed `.tfvars` files
2. **Drift Detection**: Scheduled workflow to detect configuration drift
3. **Cost Estimation**: Integrate Infracost for cost impact analysis
4. **Approval Matrix**: Different approvers for different workload types
5. **Direct Reusable Workflow**: If GitHub adds support for matrix + reusable workflows

### Contributing

When modifying workflows:
1. Test in a feature branch first
2. Verify all workloads process correctly
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

**Key Takeaway**: These workflows demonstrate how to adapt centralized workflow patterns for multi-workload scenarios while maintaining the same quality, security, and deployment standards.
