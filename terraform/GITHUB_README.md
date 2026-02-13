# GitHub Repository Management

This directory contains Terraform configuration for managing GitHub repositories in the `nathlan` organization.

## Overview

The GitHub configuration creates and manages:
- **Repository**: `test-app-lz` (from `alz-workload-template` template)
- **Team Access**: Platform engineering team with admin permissions
- **Branch Protection**: Main branch protection with PR reviews and status checks

## Files

- `github-providers.tf` - GitHub provider configuration
- `github-variables.tf` - Input variable definitions
- `github-data.tf` - Data sources for existing GitHub resources
- `github-main.tf` - Primary resource definitions
- `github-outputs.tf` - Output value declarations

## Prerequisites

### Authentication

Set the `GITHUB_TOKEN` environment variable with a Personal Access Token (PAT) or GitHub App token:

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
```

**Required Token Scopes:**
- `repo` - Full control of repositories
- `admin:org` - Full control of organizations (for team management)
- `admin:repo_hook` - Full control of repository hooks

### Existing Resources

The following resources must exist in GitHub before applying:
- ✅ Organization: `nathlan`
- ✅ Team: `platform-engineering`
- ✅ Template Repository: `nathlan/alz-workload-template`

## Repository Configuration

### Repository Settings

| Setting | Value |
|---------|-------|
| Name | `test-app-lz` |
| Visibility | Internal |
| Template | `nathlan/alz-workload-template` |
| Topics | `azure`, `terraform`, `payments-api` |
| Issues | Enabled |
| Wiki | Disabled |
| Projects | Disabled |

### Merge Settings

| Setting | Value |
|---------|-------|
| Squash Merge | ✅ Enabled |
| Merge Commit | ❌ Disabled |
| Rebase Merge | ❌ Disabled |
| Delete Branch on Merge | ✅ Enabled |

### Branch Protection (main)

- ✅ Require pull request with 1 approval
- ✅ Dismiss stale reviews on new push
- ✅ Require conversation resolution
- ✅ Require status checks: `terraform-plan`, `security-scan`
- ✅ Require branches to be up to date
- ✅ Prevent force pushes
- ✅ Prevent branch deletion

**Bypass Actors:**
- Platform engineering team (can bypass PR requirements)

## Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Validate Configuration

```bash
terraform fmt -check -recursive
terraform validate
```

### Plan Changes

```bash
terraform plan
```

### Apply Configuration

```bash
terraform apply
```

### View Outputs

```bash
terraform output
```

## Variables

Key variables can be customized via `terraform.tfvars` or command-line flags:

```hcl
# GitHub Configuration
github_organization                   = "nathlan"
github_repository_name                = "test-app-lz"
github_repository_description         = "Azure Landing Zone workload repository"
github_repository_visibility          = "internal"
github_repository_topics              = ["azure", "terraform", "payments-api"]
github_template_owner                 = "nathlan"
github_template_repository            = "alz-workload-template"
github_platform_team                  = "platform-engineering"
github_branch_protection_enabled      = true
github_required_approving_review_count = 1
```

## Outputs

After successful apply, the following outputs are available:

- `github_repository_name` - Repository name
- `github_repository_url` - HTTPS URL to repository
- `github_repository_git_clone_url` - Git clone URL
- `github_repository_ssh_clone_url` - SSH clone URL
- `github_repository_id` - GitHub repository ID
- `github_branch_protection_ruleset_id` - Branch protection ruleset ID

## Security Considerations

⚠️ **Important Security Notes:**

1. **Token Security**: Never commit `GITHUB_TOKEN` to version control
2. **Least Privilege**: Use tokens with minimum required scopes
3. **Token Rotation**: Regularly rotate GitHub tokens
4. **Audit Logging**: GitHub audit logs track all changes
5. **State File**: Contains repository IDs - secure the state file appropriately

## Troubleshooting

### Common Issues

**"Resource not found" error:**
- Verify the organization exists: `nathlan`
- Verify the team exists: `platform-engineering`
- Verify the template repository exists and is marked as a template

**"401 Unauthorized" error:**
- Ensure `GITHUB_TOKEN` is set
- Verify token is valid: `curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user`

**"403 Forbidden" error:**
- Ensure token has required scopes: `repo`, `admin:org`, `admin:repo_hook`
- Verify you have admin access to the organization

**"Repository already exists" error:**
- If repository exists but not managed by Terraform, import it:
  ```bash
  terraform import github_repository.workload test-app-lz
  ```

## Risk Assessment

**Risk Level:** 🟢 **Low**

- **Operation**: Creates new repository
- **Destructive Changes**: None
- **Scope**: Single repository in organization
- **Reversibility**: Repository can be deleted/archived if needed

## State Management

This configuration uses the same Terraform state backend as the Azure Landing Zone configuration. Ensure backend is properly configured in `backend.tf`.

## Additional Resources

- [GitHub Terraform Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [GitHub Repository Settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features)
- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
