# ==============================================================================
# GitHub Outputs
# ==============================================================================
# Output values for created GitHub repositories and their configurations
# ==============================================================================

output "github_repositories" {
  description = "Map of created GitHub repositories with their details"
  value = {
    for repo_key, repo in github_repository.repos : repo_key => {
      name          = repo.name
      full_name     = repo.full_name
      html_url      = repo.html_url
      ssh_clone_url = repo.ssh_clone_url
      http_clone_url = repo.http_clone_url
      visibility    = repo.visibility
      topics        = repo.topics
    }
  }
}

output "github_repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for repo_key, repo in github_repository.repos : repo.name => repo.html_url
  }
}
