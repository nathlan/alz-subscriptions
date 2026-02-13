# GitHub Provider Configuration
# Documentation: https://registry.terraform.io/providers/integrations/github/latest/docs

provider "github" {
  owner = coalesce(var.github_organization, "nathlan")
  # Authentication via GITHUB_TOKEN environment variable
  # Set GITHUB_TOKEN with a Personal Access Token or GitHub App token
  # Required scopes: repo, admin:org, admin:repo_hook
}
