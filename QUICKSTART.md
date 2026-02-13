# Quick Start Guide - GitHub Repository Provisioning

## ⚡ Quick Deploy

```bash
# 1. Set GitHub Token
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"

# 2. Navigate to terraform directory
cd terraform

# 3. Plan (optional but recommended)
terraform plan -var="github_organization=nathlan"

# 4. Apply
terraform apply -var="github_organization=nathlan"
```

## 📋 What Will Be Created

When you run `terraform apply`, the following will be created:

1. **GitHub Repository**: `alz-handover-prod`
   - Created from template: `nathlan/alz-workload-template`
   - Visibility: internal
   - Topics: azure, terraform, handover

2. **Team Access**: 
   - `platform-engineering` → admin access

3. **Branch Protection** (main branch):
   - 1 approval required
   - Status checks: terraform-plan, security-scan

## 🔍 Preview Changes

```bash
cd terraform
terraform plan -var="github_organization=nathlan" -out=plan.tfplan
```

Expected resources:
- `+ github_repository.repos["alz-handover-prod"]` - Repository creation
- `+ github_team_repository.team_access[...]` - Team access
- `+ github_repository_ruleset.main_branch_protection[...]` - Branch protection

## ✅ Verification

After deployment, verify the repository:

```bash
# Using GitHub CLI
gh repo view nathlan/alz-handover-prod

# Using curl
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-handover-prod
```

## 🎯 Expected Outputs

After successful deployment:

```
Outputs:

github_repository_names = {
  "alz-handover-prod" = "alz-handover-prod"
}

github_repository_urls = {
  "alz-handover-prod" = "https://github.com/nathlan/alz-handover-prod"
}

github_repository_ids = {
  "alz-handover-prod" = <repository-id>
}

github_repository_full_names = {
  "alz-handover-prod" = "nathlan/alz-handover-prod"
}
```

## 🚨 Prerequisites Checklist

Before running terraform apply, ensure:

- [ ] `GITHUB_TOKEN` environment variable is set
- [ ] Token has `repo` and `admin:org` scopes
- [ ] Team `platform-engineering` exists in organization
- [ ] Template repository `nathlan/alz-workload-template` exists and is marked as template
- [ ] You have admin access to the `nathlan` organization

## 🛠️ Troubleshooting

### Token Issues
```bash
# Verify token is set
echo $GITHUB_TOKEN | cut -c1-10

# Test API access
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### Team Not Found
```bash
# List teams in organization
gh api /orgs/nathlan/teams --jq '.[].slug'
```

### Repository Already Exists

If the repository already exists, you can import it:

```bash
terraform import 'github_repository.repos["alz-handover-prod"]' alz-handover-prod
```

## 📊 Resource Summary

| Resource Type | Count | Description |
|---------------|-------|-------------|
| github_repository | 1 | Repository from template |
| github_team_repository | 1 | Team access permission |
| github_repository_ruleset | 1 | Branch protection rules |
| **Total** | **3** | **Resources to create** |

## 🔗 Links

- **Repository URL**: https://github.com/nathlan/alz-handover-prod (after creation)
- **Template**: https://github.com/nathlan/alz-workload-template
- **Documentation**: [terraform/GITHUB_README.md](terraform/GITHUB_README.md)
- **Full Summary**: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)

## 💡 Tips

1. **Dry Run First**: Always run `terraform plan` before `apply`
2. **Save Plan**: Use `-out=plan.tfplan` to review before applying
3. **Verify Access**: Check team membership before deployment
4. **Test Template**: Ensure template repository is accessible
5. **Monitor State**: Keep Terraform state file secure

## 📞 Support

For issues or questions:
1. Check [terraform/GITHUB_README.md](terraform/GITHUB_README.md) troubleshooting section
2. Review [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for details
3. Contact Platform Engineering team
4. Open an issue in the repository

---

**Status**: ✅ Ready for deployment
**Risk Level**: 🟢 Low
**Reversible**: Yes (repository can be deleted)
