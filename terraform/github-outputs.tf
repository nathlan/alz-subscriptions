# ==============================================================================
# GitHub Outputs
# ==============================================================================

output "github_repository_names" {
  description = "Map of repository keys to their names"
  value = {
    for repo_key, repo in github_repository.repos :
    repo_key => repo.name
  }
}

output "github_repository_urls" {
  description = "Map of repository keys to their HTML URLs"
  value = {
    for repo_key, repo in github_repository.repos :
    repo_key => repo.html_url
  }
}

output "github_repository_ids" {
  description = "Map of repository keys to their GitHub repository IDs"
  value = {
    for repo_key, repo in github_repository.repos :
    repo_key => repo.repo_id
  }
}

output "github_repository_full_names" {
  description = "Map of repository keys to their full names (owner/repo)"
  value = {
    for repo_key, repo in github_repository.repos :
    repo_key => repo.full_name
  }
}
