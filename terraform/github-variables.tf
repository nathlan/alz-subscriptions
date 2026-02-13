# ==============================================================================
# GitHub Configuration Variables
# ==============================================================================

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token with repo and admin:org permissions. Should be provided via environment variable GITHUB_TOKEN."
  sensitive   = true
  default     = null
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user account name"
  default     = "nathlan"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,39}$", var.github_owner))
    error_message = "GitHub owner must be a valid GitHub username/organization name."
  }
}

variable "github_repositories" {
  type = map(object({
    # Repository Configuration
    name        = string
    description = optional(string, "")
    visibility  = optional(string, "internal")
    topics      = optional(list(string), [])

    # Template Configuration
    template = optional(object({
      owner      = string
      repository = string
    }))

    # Repository Settings
    has_issues             = optional(bool, true)
    has_projects           = optional(bool, false)
    has_wiki               = optional(bool, false)
    delete_branch_on_merge = optional(bool, true)
    allow_squash_merge     = optional(bool, true)
    allow_merge_commit     = optional(bool, false)
    allow_rebase_merge     = optional(bool, false)

    # Team Access
    team_access = optional(map(string), {})

    # Branch Protection
    branch_protection = optional(object({
      required_approving_review_count   = optional(number, 1)
      dismiss_stale_reviews_on_push     = optional(bool, true)
      require_code_owner_review         = optional(bool, false)
      require_last_push_approval        = optional(bool, false)
      required_review_thread_resolution = optional(bool, true)
      required_status_checks = optional(list(object({
        context = string
      })), [])
      strict_required_status_checks_policy = optional(bool, true)
      non_fast_forward                     = optional(bool, true)
      bypass_actors = optional(list(object({
        actor_type  = string
        bypass_mode = string
      })), [])
    }))
  }))

  description = <<-EOT
    Map of GitHub repositories to create and manage.

    Each repository can be configured with:
    - name: Repository name (required)
    - description: Repository description
    - visibility: Repository visibility (public, private, internal)
    - topics: List of repository topics
    - template: Template repository to use (owner + repository)
    - has_issues, has_projects, has_wiki: Feature flags
    - delete_branch_on_merge: Auto-delete head branches after merge
    - allow_squash_merge, allow_merge_commit, allow_rebase_merge: Merge strategies
    - team_access: Map of team slugs to permissions (pull, push, maintain, admin)
    - branch_protection: Branch protection configuration for main branch

    Example:
    github_repositories = {
      alz-workload-prod = {
        name        = "alz-workload-prod"
        description = "Production workload for Azure Landing Zone"
        visibility  = "internal"
        topics      = ["azure", "terraform", "workload"]
        template = {
          owner      = "nathlan"
          repository = "alz-workload-template"
        }
        team_access = {
          platform-engineering = "admin"
        }
        branch_protection = {
          required_approving_review_count = 1
          required_status_checks = [
            { context = "terraform-plan" },
            { context = "security-scan" }
          ]
        }
      }
    }
  EOT

  default = {}
}
