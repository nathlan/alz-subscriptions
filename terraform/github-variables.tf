# ==============================================================================
# GitHub Configuration Variables
# ==============================================================================
# Input variables for GitHub repository and team management
# ==============================================================================

variable "github_owner" {
  description = "GitHub organization or user account name"
  type        = string
  default     = "nathlan"
}

variable "github_repositories" {
  description = "Map of GitHub repositories to create and manage"
  type = map(object({
    name                   = string
    description            = string
    visibility             = string
    template_owner         = optional(string)
    template_repository    = optional(string)
    topics                 = optional(list(string), [])
    delete_branch_on_merge = optional(bool, true)
    allow_squash_merge     = optional(bool, true)
    allow_merge_commit     = optional(bool, false)
    allow_rebase_merge     = optional(bool, false)

    team_access = optional(map(string), {})

    branch_protection = optional(object({
      pattern                         = string
      required_approving_review_count = optional(number, 1)
      required_status_checks          = optional(list(string), [])
      require_conversation_resolution = optional(bool, true)
      require_branch_up_to_date       = optional(bool, true)
    }))
  }))
  default = {}
}
