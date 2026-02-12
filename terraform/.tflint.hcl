# ==============================================================================
# TFLint Configuration for ALZ Workload Template
# ==============================================================================
# This is a template repository. Variables are defined for users to utilize
# when they add their own resources. The unused variable warnings are expected
# and suppressed here.
# ==============================================================================

config {
  format = "compact"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Suppress unused variable warnings for template variables
# Users will utilize these when they add their own resources
rule "terraform_unused_declarations" {
  enabled = false
}
