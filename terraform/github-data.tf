# ==============================================================================
# GitHub Data Sources
# ==============================================================================

# Query existing GitHub teams for repository access configuration
data "github_team" "teams" {
  for_each = toset(distinct(flatten([
    for repo_key, repo in var.github_repositories : [
      for team_slug, permission in repo.team_access : team_slug
    ]
  ])))

  slug = each.value
}
