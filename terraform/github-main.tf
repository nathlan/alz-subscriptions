# ==============================================================================
# GitHub Repository Management
# ==============================================================================
# Creates and configures GitHub repositories with team access and branch protection
# ==============================================================================

# Create GitHub repositories
resource "github_repository" "repos" {
  for_each = var.github_repositories

  name                   = each.value.name
  description            = each.value.description
  visibility             = each.value.visibility
  topics                 = each.value.topics
  delete_branch_on_merge = each.value.delete_branch_on_merge
  allow_squash_merge     = each.value.allow_squash_merge
  allow_merge_commit     = each.value.allow_merge_commit
  allow_rebase_merge     = each.value.allow_rebase_merge

  # Use template repository if specified
  dynamic "template" {
    for_each = each.value.template_repository != null ? [1] : []
    content {
      owner      = each.value.template_owner != null ? each.value.template_owner : var.github_owner
      repository = each.value.template_repository
    }
  }
}

# Configure team access to repositories
resource "github_team_repository" "team_access" {
  for_each = merge([
    for repo_key, repo in var.github_repositories : {
      for team_name, permission in repo.team_access :
      "${repo_key}-${team_name}" => {
        repository = github_repository.repos[repo_key].name
        team_id    = data.github_team.teams[team_name].id
        permission = permission
      }
    }
  ]...)

  repository = each.value.repository
  team_id    = each.value.team_id
  permission = each.value.permission
}

# Configure branch protection rules
resource "github_repository_ruleset" "branch_protection" {
  for_each = {
    for repo_key, repo in var.github_repositories :
    repo_key => repo
    if repo.branch_protection != null
  }

  name        = "main-branch-protection"
  repository  = github_repository.repos[each.key].name
  enforcement = "active"

  target = "branch"

  conditions {
    ref_name {
      include = [each.value.branch_protection.pattern]
      exclude = []
    }
  }

  rules {
    # Require pull request before merging
    pull_request {
      required_approving_review_count = each.value.branch_protection.required_approving_review_count
      dismiss_stale_reviews_on_push   = true
      require_code_owner_review       = false
      require_last_push_approval      = false
    }

    # Require status checks
    dynamic "required_status_checks" {
      for_each = length(each.value.branch_protection.required_status_checks) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = each.value.branch_protection.required_status_checks
          content {
            context = required_check.value
          }
        }
        strict_required_status_checks_policy = each.value.branch_protection.require_branch_up_to_date
      }
    }

    # Require conversation resolution before merging (if supported by provider)
    # Note: This may need to be configured via pull_request block or separate setting
    required_linear_history = false
    required_signatures     = false
  }

  bypass_actors {
    actor_id    = 5 # Repository admins
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request"
  }
}
