# GitHub Repository Management
# Creates and configures GitHub repository from template with branch protection

# Create repository from template
resource "github_repository" "workload" {
  name        = var.github_repository_name
  description = var.github_repository_description
  visibility  = var.github_repository_visibility

  # Use the alz-workload-template as base
  template {
    owner                = var.github_template_owner
    repository           = var.github_template_repository
    include_all_branches = false
  }

  # Repository settings
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  has_discussions        = false
  delete_branch_on_merge = true
  auto_init              = false # Template provides initial content

  # Merge settings
  allow_squash_merge          = true
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_auto_merge            = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # Security settings
  vulnerability_alerts = true

  # Topics for discoverability
  topics = var.github_repository_topics

  lifecycle {
    prevent_destroy = false # Allow deletion in non-production environments
  }
}

# Grant admin access to platform engineering team
resource "github_team_repository" "platform_admin" {
  team_id    = data.github_team.platform_engineering.id
  repository = github_repository.workload.name
  permission = "admin"

  depends_on = [github_repository.workload]
}

# Branch protection ruleset for main branch
resource "github_repository_ruleset" "main_protection" {
  count = var.github_branch_protection_enabled ? 1 : 0

  name        = "main-branch-protection"
  repository  = github_repository.workload.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    # Pull request requirements
    pull_request {
      required_approving_review_count   = var.github_required_approving_review_count
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
    }

    # Required status checks
    required_status_checks {
      required_check {
        context = "terraform-plan"
        # integration_id is optional - allows any integration to provide this check
      }
      required_check {
        context = "security-scan"
        # integration_id is optional - allows any integration to provide this check
      }
      strict_required_status_checks_policy = true # Require branches to be up to date
    }

    # Prevent force pushes
    non_fast_forward = true

    # Prevent deletion of protected branch
    deletion = true
  }

  # Allow platform engineering team to bypass pull request requirements
  bypass_actors {
    actor_id    = data.github_team.platform_engineering.id
    actor_type  = "Team"
    bypass_mode = "pull_request" # Can bypass PR requirements but not status checks
  }

  depends_on = [
    github_repository.workload,
    github_team_repository.platform_admin
  ]
}
