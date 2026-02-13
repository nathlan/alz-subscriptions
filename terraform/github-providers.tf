# ==============================================================================
# GitHub Provider Configuration
# ==============================================================================
# Configures the GitHub provider for managing GitHub resources
# Uses GITHUB_TOKEN environment variable for authentication
# ==============================================================================

provider "github" {
  owner = var.github_owner
}
