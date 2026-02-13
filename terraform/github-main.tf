# ==============================================================================
# GitHub Repository Management
# ==============================================================================
# This module manages GitHub repositories with:
# - Repository creation from templates
# - Team access permissions
# - Branch protection rules
# - Repository settings (merge strategies, features)
# ==============================================================================

# ------------------------------------------------------------------------------
# GitHub Repositories
# ------------------------------------------------------------------------------

resource "github_repository" "repos" {
  for_each = var.github_repositories

  # Basic Configuration
  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility
  topics      = each.value.topics

  # Template Configuration (if specified)
  dynamic "template" {
    for_each = each.value.template != null ? [each.value.template] : []
    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }

  # Repository Features
  has_issues   = each.value.has_issues
  has_projects = each.value.has_projects
  has_wiki     = each.value.has_wiki

  # Merge Settings
  delete_branch_on_merge = each.value.delete_branch_on_merge
  allow_squash_merge     = each.value.allow_squash_merge
  allow_merge_commit     = each.value.allow_merge_commit
  allow_rebase_merge     = each.value.allow_rebase_merge

  lifecycle {
    prevent_destroy = false
  }
}

# ------------------------------------------------------------------------------
# Team Repository Access
# ------------------------------------------------------------------------------

resource "github_team_repository" "team_access" {
  for_each = merge([
    for repo_key, repo in var.github_repositories : {
      for team_slug, permission in repo.team_access :
      "${repo_key}::${team_slug}" => {
        repository = repo.name
        repo_key   = repo_key
        team_slug  = team_slug
        permission = permission
      }
    }
  ]...)

  team_id    = data.github_team.teams[each.value.team_slug].id
  repository = github_repository.repos[each.value.repo_key].name
  permission = each.value.permission

  depends_on = [github_repository.repos]
}

# ------------------------------------------------------------------------------
# Branch Protection Rules
# ------------------------------------------------------------------------------

resource "github_repository_ruleset" "main_branch_protection" {
  for_each = {
    for repo_key, repo in var.github_repositories :
    repo_key => repo
    if repo.branch_protection != null
  }

  name        = "main-branch-protection"
  repository  = github_repository.repos[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    # Pull Request Requirements
    pull_request {
      required_approving_review_count   = each.value.branch_protection.required_approving_review_count
      dismiss_stale_reviews_on_push     = each.value.branch_protection.dismiss_stale_reviews_on_push
      require_code_owner_review         = each.value.branch_protection.require_code_owner_review
      require_last_push_approval        = each.value.branch_protection.require_last_push_approval
      required_review_thread_resolution = each.value.branch_protection.required_review_thread_resolution
    }

    # Required Status Checks
    dynamic "required_status_checks" {
      for_each = length(each.value.branch_protection.required_status_checks) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = each.value.branch_protection.required_status_checks
          content {
            context = required_check.value.context
          }
        }
        strict_required_status_checks_policy = each.value.branch_protection.strict_required_status_checks_policy
      }
    }

    # Non-Fast-Forward Protection
    non_fast_forward = each.value.branch_protection.non_fast_forward
  }

  depends_on = [github_repository.repos]
}
