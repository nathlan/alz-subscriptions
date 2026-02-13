# GitHub Configuration Variables
# Note: github_organization is already defined in variables.tf for Azure Landing Zone configuration

variable "github_repository_name" {
  description = "Name of the GitHub repository to create"
  type        = string
  default     = "test-app-lz"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{1,100}$", var.github_repository_name))
    error_message = "Repository name must contain only alphanumeric characters, hyphens, underscores, or periods"
  }
}

variable "github_repository_description" {
  description = "Description of the GitHub repository"
  type        = string
  default     = "Azure Landing Zone workload repository for test application"
}

variable "github_repository_visibility" {
  description = "Visibility of the repository (public, private, or internal)"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "private", "internal"], var.github_repository_visibility)
    error_message = "Visibility must be one of: public, private, internal"
  }
}

variable "github_repository_topics" {
  description = "List of topics for the repository"
  type        = list(string)
  default     = ["azure", "terraform", "payments-api"]
}

variable "github_template_owner" {
  description = "Owner of the template repository"
  type        = string
  default     = "nathlan"
}

variable "github_template_repository" {
  description = "Name of the template repository to use"
  type        = string
  default     = "alz-workload-template"
}

variable "github_platform_team" {
  description = "GitHub team slug for platform engineering team"
  type        = string
  default     = "platform-engineering"
}

variable "github_branch_protection_enabled" {
  description = "Enable branch protection rules for main branch"
  type        = bool
  default     = true
}

variable "github_required_approving_review_count" {
  description = "Number of required approving reviews for pull requests"
  type        = number
  default     = 1

  validation {
    condition     = var.github_required_approving_review_count >= 0 && var.github_required_approving_review_count <= 6
    error_message = "Required approving review count must be between 0 and 6"
  }
}
