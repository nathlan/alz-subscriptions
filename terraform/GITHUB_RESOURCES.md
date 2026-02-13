# Terraform Resources Summary

This document lists all Terraform resources that will be created or referenced by the GitHub configuration.

## Resources Created (3)

### 1. github_repository.workload
**Type:** GitHub Repository  
**Name:** test-app-lz  
**Source:** Template (`nathlan/alz-workload-template`)

**Configuration:**
```hcl
resource "github_repository" "workload" {
  name        = "test-app-lz"
  description = "Azure Landing Zone workload repository for test application"
  visibility  = "internal"
  
  template {
    owner      = "nathlan"
    repository = "alz-workload-template"
  }
  
  # Settings
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  delete_branch_on_merge = true
  
  # Merge settings
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  
  # Security
  vulnerability_alerts = true
  
  # Topics
  topics = ["azure", "terraform", "payments-api"]
}
```

**What it provides:**
- Repository created from alz-workload-template
- Pre-configured GitHub Actions workflows from template
- Terraform directory structure from template
- Azure OIDC authentication setup from template

---

### 2. github_team_repository.platform_admin
**Type:** Team Repository Access  
**Team:** platform-engineering  
**Permission:** admin

**Configuration:**
```hcl
resource "github_team_repository" "platform_admin" {
  team_id    = data.github_team.platform_engineering.id
  repository = github_repository.workload.name
  permission = "admin"
}
```

**Permissions granted:**
- Pull
- Triage
- Push
- Maintain
- Admin (full control)

---

### 3. github_repository_ruleset.main_protection[0]
**Type:** Branch Protection Ruleset  
**Target:** refs/heads/main  
**Enforcement:** active

**Configuration:**
```hcl
resource "github_repository_ruleset" "main_protection" {
  name        = "main-branch-protection"
  repository  = github_repository.workload.name
  target      = "branch"
  enforcement = "active"
  
  conditions {
    ref_name {
      include = ["refs/heads/main"]
    }
  }
  
  rules {
    # Pull Request Requirements
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
    }
    
    # Status Checks
    required_status_checks {
      required_check {
        context = "terraform-plan"
      }
      required_check {
        context = "security-scan"
      }
      strict_required_status_checks_policy = true
    }
    
    # Protection Rules
    non_fast_forward = true  # Prevent force push
    deletion = true          # Prevent branch deletion
  }
  
  # Bypass Actors
  bypass_actors {
    actor_id    = data.github_team.platform_engineering.id
    actor_type  = "Team"
    bypass_mode = "pull_request"
  }
}
```

**Protection rules:**
- ✅ Require pull request with 1 approval
- ✅ Dismiss stale reviews when new commits pushed
- ✅ Require all conversations resolved
- ✅ Require status checks: terraform-plan, security-scan
- ✅ Require branches up-to-date before merge
- ✅ Block force pushes
- ✅ Block branch deletion
- 👤 Platform engineering can bypass PR (not status checks)

---

## Data Sources Referenced (2)

### 1. data.github_team.platform_engineering
**Type:** GitHub Team  
**Lookup:** By slug `platform-engineering`

**Usage:**
- Referenced for team repository access
- Referenced for branch protection bypass

**Query:**
```hcl
data "github_team" "platform_engineering" {
  slug = "platform-engineering"
}
```

---

### 2. data.github_repository.template
**Type:** GitHub Repository  
**Lookup:** Full name `nathlan/alz-workload-template`

**Purpose:**
- Verify template repository exists
- Validate template is accessible

**Query:**
```hcl
data "github_repository" "template" {
  full_name = "nathlan/alz-workload-template"
}
```

---

## Resource Dependencies

```
data.github_team.platform_engineering
  ↓
  ├─→ github_repository.workload
  │     ↓
  │     ├─→ github_team_repository.platform_admin
  │     │
  │     └─→ github_repository_ruleset.main_protection
  │           ↓
  │           └─→ uses team ID for bypass_actors
  │
  └─→ uses team ID directly

data.github_repository.template
  └─→ validation only (not directly referenced)
```

---

## Outputs Generated (10)

1. **github_repository_name** - `"test-app-lz"`
2. **github_repository_full_name** - `"nathlan/test-app-lz"`
3. **github_repository_url** - `"https://github.com/nathlan/test-app-lz"`
4. **github_repository_git_clone_url** - `"git://github.com/nathlan/test-app-lz.git"`
5. **github_repository_ssh_clone_url** - `"git@github.com:nathlan/test-app-lz.git"`
6. **github_repository_id** - Repository numeric ID
7. **github_repository_node_id** - Repository global node ID
8. **github_repository_topics** - `["azure", "terraform", "payments-api"]`
9. **github_branch_protection_ruleset_id** - Ruleset ID
10. **github_platform_team_id** - Team ID

---

## State File Contents

After `terraform apply`, the state file will contain:

```
terraform.tfstate
├── Resources (3)
│   ├── github_repository.workload
│   ├── github_team_repository.platform_admin
│   └── github_repository_ruleset.main_protection[0]
└── Data Sources (2)
    ├── data.github_team.platform_engineering
    └── data.github_repository.template
```

**State File Security:**
- Contains repository IDs (not sensitive)
- Contains team IDs (not sensitive)
- Does NOT contain GitHub token
- Safe to store in remote backend

---

## Import Existing Resources

If the repository already exists, import it before applying:

```bash
# Import repository
terraform import github_repository.workload test-app-lz

# Import team access (requires team ID and repo name)
terraform import github_team_repository.platform_admin <team-id>:test-app-lz

# Import branch protection (requires repo name and ruleset ID)
terraform import 'github_repository_ruleset.main_protection[0]' test-app-lz:<ruleset-id>
```

To find IDs:
```bash
# Get team ID
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/orgs/nathlan/teams/platform-engineering

# Get ruleset ID
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/test-app-lz/rulesets
```

---

## Resource Lifecycle

### Creation Order
1. Data source queries (team, template validation)
2. Repository creation from template
3. Team access grant
4. Branch protection ruleset

### Deletion Order (if destroyed)
1. Branch protection ruleset
2. Team access revocation
3. Repository deletion

### Updates
- Repository settings: In-place update
- Team permissions: In-place update
- Branch protection: Recreate if target branch changes

---

## Cost Implications

**GitHub Usage:**
- Repository: Free (internal visibility)
- GitHub Actions: Included minutes for organization
- Branch protection: No additional cost
- Team management: No additional cost

**Total Additional Cost:** $0

---

## Compliance & Audit

All actions are logged in GitHub audit log:
- Repository creation
- Team access changes
- Branch protection changes
- All authenticated via GITHUB_TOKEN

View audit log: `https://github.com/organizations/nathlan/settings/audit-log`

---
