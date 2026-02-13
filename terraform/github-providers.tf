# ==============================================================================
# GitHub Provider Configuration
# ==============================================================================

provider "github" {
  owner = var.github_owner
  token = var.github_token != null ? var.github_token : null
}
