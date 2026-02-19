# GitHub Repository Management

This directory contains Terraform code for managing GitHub repositories in the `nathlan` organization.

## Overview

The GitHub configuration manages:
- **Repository Creation**: Create repositories from templates (e.g., `alz-workload-template`)
- **Team Access**: Configure team permissions (pull, push, maintain, admin)
- **Branch Protection**: Enforce branch protection rules for main branch
- **Repository Settings**: Configure merge strategies, features, and visibility

## Files

- `github-variables.tf`: Input variables for GitHub configuration
- `github-providers.tf`: GitHub provider configuration
- `github-data.tf`: Data sources for existing GitHub teams
- `github-main.tf`: Main resource definitions for repositories, team access, and branch protection
- `github-outputs.tf`: Output values for created repositories

## Prerequisites

### 1. GitHub Personal Access Token

Create a GitHub Personal Access Token with the following scopes:
- `repo` (Full control of private repositories)
- `admin:org` (Full control of orgs and teams)

Set the token as an environment variable:
```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"
```

### 2. Existing GitHub Teams

Ensure the following teams exist in the `nathlan` organization:
- `platform-engineering`

## Usage

### Creating a New Repository

Add a new repository configuration to `terraform.tfvars`:

```hcl
github_repositories = {
  my-workload-repo = {
    name        = "alz-workload-prod"
    description = "Production workload repository"
    visibility  = "internal"
    topics      = ["azure", "terraform", "workload"]

    # Use the standard workload template
    template = {
      owner      = "nathlan"
      repository = "alz-workload-template"
    }

    # Team Access
    team_access = {
      platform-engineering = "admin"
      dev-team            = "maintain"
    }

    # Branch Protection
    branch_protection = {
      required_approving_review_count = 1
      required_status_checks = [
        { context = "terraform-plan" },
        { context = "security-scan" }
      ]
      strict_required_status_checks_policy = true
    }
  }
}
```

### Terraform Commands

```bash
# Initialize Terraform (first time only)
terraform init

# Preview changes
terraform plan -var="github_owner=nathlan"

# Apply changes
terraform apply -var="github_owner=nathlan"
```

## Configuration Details

### Repository Template

All workload repositories should use the `nathlan/alz-workload-template` template, which includes:
- Pre-configured GitHub Actions workflows
- Terraform directory structure
- Azure OIDC authentication setup
- Security scanning and validation

### Team Permissions

Available permission levels:
- `pull`: Read-only access
- `push`: Read and write access
- `maintain`: Repository maintenance (recommended for workload teams)
- `admin`: Full administrative access (recommended for platform team)

### Branch Protection

The configuration enforces branch protection on the `main` branch with:
- **Pull Request Reviews**: Minimum 1 approval required
- **Status Checks**: Required checks must pass before merging
  - `terraform-plan`: Terraform plan must succeed
  - `security-scan`: Security scanning must pass
- **Up-to-date Branches**: Branches must be up-to-date before merging
- **Conversation Resolution**: All review comments must be resolved

## Security Considerations

🔒 **Sensitive Data**:
- Never commit GitHub tokens to version control
- Use environment variables for authentication
- Tokens are marked as sensitive in Terraform

🛡️ **Branch Protection**:
- Main branch is protected and requires reviews
- Force pushes are blocked
- Status checks must pass before merging

👥 **Team Access**:
- Follow principle of least privilege
- Platform team has admin access for repository management
- Workload teams have maintain access for day-to-day operations

## Troubleshooting

### Authentication Issues

If you see `401 Unauthorized` errors:
```bash
# Verify your token is set
echo $GITHUB_TOKEN

# Test GitHub API access
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### Team Not Found

If you see "team not found" errors:
1. Verify the team slug (lowercase, hyphenated)
2. Ensure the team exists in the organization
3. Check your token has `admin:org` scope

### Resource Already Exists

If a repository already exists:
1. Import the existing repository:
   ```bash
   terraform import github_repository.repos[\"repo-key\"] repository-name
   ```
2. Or, remove the resource from configuration if not managed by Terraform

## Related Documentation

- [GitHub Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [alz-workload-template Repository](https://github.com/nathlan/alz-workload-template)
- [Azure Landing Zone Documentation](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)

## Support

For questions or issues:
1. Check existing [GitHub Issues](https://github.com/nathlan/alz-subscriptions/issues)
2. Contact the Platform Engineering team
3. Review the [Terraform GitHub Provider docs](https://registry.terraform.io/providers/integrations/github/latest/docs)
