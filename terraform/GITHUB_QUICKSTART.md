# Quick Start: GitHub Repository Provisioning

This guide shows how to use the new GitHub Terraform configuration to create the `test-app-lz` repository.

## Prerequisites

1. **GitHub Token**: Export a GitHub Personal Access Token with required scopes:
   ```bash
   export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
   ```
   
   Required scopes: `repo`, `admin:org`, `admin:repo_hook`

2. **Verify Existing Resources**:
   - Organization: `nathlan` ✓
   - Team: `platform-engineering` ✓
   - Template: `nathlan/alz-workload-template` ✓

## Quick Apply

```bash
cd /home/runner/work/alz-subscriptions/alz-subscriptions/terraform

# Initialize (if not already done)
terraform init

# Review what will be created
terraform plan

# Create the repository
terraform apply
```

## What Gets Created

- ✅ Repository: `test-app-lz` (from template)
- ✅ Team Access: platform-engineering team with admin permission
- ✅ Branch Protection: main branch with PR reviews and status checks

## Configuration

All settings use default values from `github-variables.tf`:

```hcl
github_repository_name                = "test-app-lz"
github_repository_description         = "Azure Landing Zone workload repository for test application"
github_repository_visibility          = "internal"
github_repository_topics              = ["azure", "terraform", "payments-api"]
github_template_owner                 = "nathlan"
github_template_repository            = "alz-workload-template"
github_platform_team                  = "platform-engineering"
github_branch_protection_enabled      = true
github_required_approving_review_count = 1
```

## Customization

To override defaults, add to `terraform.tfvars` or use `-var` flags:

```bash
terraform apply -var="github_repository_name=my-app-lz"
```

## Files Added

- `github-providers.tf` - GitHub provider configuration
- `github-variables.tf` - Input variables (reuses existing github_organization)
- `github-data.tf` - Data sources for team and template
- `github-main.tf` - Repository, team access, branch protection
- `github-outputs.tf` - Repository URLs and IDs
- `GITHUB_README.md` - Detailed documentation
- `versions.tf` - Updated to include GitHub provider (~> 6.0)

## Validation Status

✅ Terraform initialization successful
✅ Code formatting validated
✅ Configuration validated
✅ No errors or warnings

## Next Steps

1. Set `GITHUB_TOKEN` environment variable
2. Run `terraform plan` to preview
3. Run `terraform apply` to create repository
4. Check outputs: `terraform output`

## Troubleshooting

**Token Issues:**
```bash
# Test token
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

**Import Existing Repository:**
```bash
terraform import github_repository.workload test-app-lz
```

For more details, see `GITHUB_README.md`.
