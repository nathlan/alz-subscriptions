# GitHub Repository Outputs

output "github_repository_name" {
  description = "Name of the created GitHub repository"
  value       = github_repository.workload.name
}

output "github_repository_full_name" {
  description = "Full name of the repository (owner/repo)"
  value       = github_repository.workload.full_name
}

output "github_repository_url" {
  description = "URL of the GitHub repository"
  value       = github_repository.workload.html_url
}

output "github_repository_git_clone_url" {
  description = "Git clone URL for the repository"
  value       = github_repository.workload.git_clone_url
}

output "github_repository_ssh_clone_url" {
  description = "SSH clone URL for the repository"
  value       = github_repository.workload.ssh_clone_url
}

output "github_repository_id" {
  description = "GitHub repository ID"
  value       = github_repository.workload.repo_id
}

output "github_repository_node_id" {
  description = "GitHub repository node ID"
  value       = github_repository.workload.node_id
}

output "github_repository_topics" {
  description = "Topics assigned to the repository"
  value       = github_repository.workload.topics
}

output "github_branch_protection_ruleset_id" {
  description = "ID of the branch protection ruleset (if enabled)"
  value       = var.github_branch_protection_enabled ? github_repository_ruleset.main_protection[0].id : null
}

output "github_platform_team_id" {
  description = "ID of the platform engineering team"
  value       = data.github_team.platform_engineering.id
}
