# GitHub Data Sources
# Query existing GitHub resources

# Get the platform engineering team
data "github_team" "platform_engineering" {
  slug = var.github_platform_team
}

# Verify the template repository exists
data "github_repository" "template" {
  full_name = "${var.github_template_owner}/${var.github_template_repository}"
}
