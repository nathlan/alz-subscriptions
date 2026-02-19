# ==============================================================================
# GitHub Data Sources
# ==============================================================================
# Fetch existing GitHub resources like teams for reference in configurations
# ==============================================================================

# Fetch GitHub teams for access control
# Creates a map of team names to their IDs for use in repository permissions
locals {
  # Get all unique team names from all repositories
  all_teams = distinct(flatten([
    for repo_key, repo in var.github_repositories : [
      for team_name, permission in repo.team_access : team_name
    ]
  ]))
}

# Data source to fetch team information
data "github_team" "teams" {
  for_each = toset(local.all_teams)
  slug     = each.value
}
