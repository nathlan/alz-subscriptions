# Deployment Checklist - alz-handover-prod Repository

## Pre-Deployment Verification

### GitHub Prerequisites
- [ ] GitHub Personal Access Token created
  - [ ] Token has `repo` scope
  - [ ] Token has `admin:org` scope
  - [ ] Token is set as environment variable: `export GITHUB_TOKEN="ghp_..."`

- [ ] GitHub Organization: `nathlan`
  - [ ] You have admin access
  - [ ] Organization exists and is accessible

- [ ] GitHub Team: `platform-engineering`
  - [ ] Team exists in the organization
  - [ ] Team slug is correct: `platform-engineering`

- [ ] Template Repository: `nathlan/alz-workload-template`
  - [ ] Repository exists
  - [ ] Repository is marked as a template
  - [ ] You have read access to the template

### Terraform Prerequisites
- [ ] Terraform v1.10+ is installed
- [ ] Working directory: `/home/runner/work/alz-subscriptions/alz-subscriptions/terraform`
- [ ] Terraform has been initialized (or will initialize)

### Files Review
- [ ] Reviewed `terraform/github-variables.tf`
- [ ] Reviewed `terraform/github-providers.tf`
- [ ] Reviewed `terraform/github-data.tf`
- [ ] Reviewed `terraform/github-main.tf`
- [ ] Reviewed `terraform/github-outputs.tf`
- [ ] Reviewed `terraform/terraform.tfvars` changes
- [ ] Reviewed `terraform/versions.tf` changes

## Deployment Steps

### Step 1: Environment Setup
```bash
# Set GitHub token
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"

# Verify token is set
echo $GITHUB_TOKEN | cut -c1-10

# Test GitHub API access
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

- [ ] Token set successfully
- [ ] API access verified
- [ ] User information returned

### Step 2: Navigate to Terraform Directory
```bash
cd /home/runner/work/alz-subscriptions/alz-subscriptions/terraform
```

- [ ] Changed to terraform directory
- [ ] Confirmed location: `pwd`

### Step 3: Initialize Terraform (if needed)
```bash
terraform init
```

- [ ] Terraform initialized successfully
- [ ] GitHub provider downloaded
- [ ] All modules downloaded
- [ ] Lock file created

### Step 4: Validate Configuration
```bash
# Format check
terraform fmt -check -recursive

# Validate
terraform validate
```

- [ ] Format check passed
- [ ] Validation successful
- [ ] No errors reported

### Step 5: Review Plan
```bash
terraform plan -var="github_owner=nathlan" -out=tfplan
```

**Expected Resources:**
- [ ] `+ github_repository.repos["alz-handover-prod"]` - Repository creation
- [ ] `+ github_team_repository.team_access[...]` - Team access assignment
- [ ] `+ github_repository_ruleset.main_branch_protection[...]` - Branch protection

**Verify Plan Output:**
- [ ] No unexpected changes
- [ ] Repository name is correct: `alz-handover-prod`
- [ ] Organization is correct: `nathlan`
- [ ] Template is correct: `nathlan/alz-workload-template`
- [ ] Team access is correct: `platform-engineering` → `admin`
- [ ] Branch protection settings are correct

### Step 6: Apply Changes
```bash
terraform apply tfplan
```

**Or interactively:**
```bash
terraform apply -var="github_owner=nathlan"
```

- [ ] Reviewed the plan one final time
- [ ] Typed `yes` to confirm
- [ ] Apply completed successfully
- [ ] No errors reported

### Step 7: Verify Outputs
```bash
terraform output
```

**Expected Outputs:**
- [ ] `github_repository_names` - Shows `alz-handover-prod`
- [ ] `github_repository_urls` - Shows GitHub URL
- [ ] `github_repository_ids` - Shows repository ID
- [ ] `github_repository_full_names` - Shows `nathlan/alz-handover-prod`

## Post-Deployment Verification

### GitHub UI Verification
- [ ] Visit: https://github.com/nathlan/alz-handover-prod
- [ ] Repository exists
- [ ] Repository is internal
- [ ] Topics are set: azure, terraform, handover
- [ ] Description is correct

### Template Verification
- [ ] Files from template are present
- [ ] `.github/workflows` directory exists
- [ ] `terraform/` directory exists
- [ ] `README.md` exists

### Team Access Verification
- [ ] Go to Settings → Collaborators and teams
- [ ] `platform-engineering` team has admin access
- [ ] No unexpected teams have access

### Branch Protection Verification
- [ ] Go to Settings → Rules → Rulesets
- [ ] `main-branch-protection` ruleset exists
- [ ] Ruleset is active (not disabled)
- [ ] Pull request reviews: 1 approval required
- [ ] Status checks: terraform-plan, security-scan
- [ ] Check the full ruleset configuration matches requirements

### GitHub CLI Verification (Optional)
```bash
# View repository
gh repo view nathlan/alz-handover-prod

# Check if branch protection is set
gh api repos/nathlan/alz-handover-prod/rulesets
```

- [ ] Repository details retrieved successfully
- [ ] Branch protection confirmed

### Integration Verification
- [ ] Azure Landing Zone `handover-prod` is provisioned
- [ ] GitHub OIDC federated credentials match repository name
- [ ] Repository name matches expectation: `alz-handover-prod`

## Troubleshooting

### Common Issues and Solutions

#### Issue: 401 Unauthorized
**Solution:**
```bash
# Check token is set
echo $GITHUB_TOKEN

# Verify token validity
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

#### Issue: 403 Forbidden
**Solution:**
- Check token has `admin:org` scope
- Verify you have admin access to the organization

#### Issue: Team not found
**Solution:**
```bash
# List teams in organization
gh api /orgs/nathlan/teams --jq '.[].slug'

# Verify team slug is: platform-engineering
```

#### Issue: Template not found
**Solution:**
- Verify template repository exists: https://github.com/nathlan/alz-workload-template
- Check it's marked as a template (Settings → Template repository)
- Ensure you have read access

#### Issue: Repository already exists
**Solution:**
```bash
# Import existing repository
terraform import 'github_repository.repos["alz-handover-prod"]' alz-handover-prod

# Then run plan again
terraform plan -var="github_owner=nathlan"
```

## Rollback Procedure

If you need to rollback the deployment:

### Option 1: Destroy with Terraform
```bash
terraform destroy -var="github_owner=nathlan"
```

### Option 2: Manual Deletion
1. Go to: https://github.com/nathlan/alz-handover-prod/settings
2. Scroll to "Danger Zone"
3. Click "Delete this repository"
4. Type repository name to confirm
5. Remove from Terraform state:
   ```bash
   terraform state rm 'github_repository.repos["alz-handover-prod"]'
   terraform state rm 'github_team_repository.team_access[...]'
   terraform state rm 'github_repository_ruleset.main_branch_protection[...]'
   ```

## Sign-off

### Deployment Completed By
- Name: _______________________
- Date: _______________________
- Time: _______________________

### Verification Completed By
- Name: _______________________
- Date: _______________________
- Time: _______________________

### Issues Encountered
- [ ] No issues
- [ ] Issues documented below:

_______________________________________________________________________________
_______________________________________________________________________________
_______________________________________________________________________________

### Notes
_______________________________________________________________________________
_______________________________________________________________________________
_______________________________________________________________________________

## Related Documentation

- Quick Start Guide: [QUICKSTART.md](../QUICKSTART.md)
- Implementation Summary: [IMPLEMENTATION_SUMMARY.md](../IMPLEMENTATION_SUMMARY.md)
- Changes Summary: [CHANGES_SUMMARY.md](../CHANGES_SUMMARY.md)
- GitHub Configuration: [GITHUB_README.md](GITHUB_README.md)

---

**Repository**: nathlan/alz-subscriptions
**Branch**: copilot/create-workload-repository-alz-handover-prod
**Status**: Ready for Deployment
**Risk Level**: 🟢 Low Risk
