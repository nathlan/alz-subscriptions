terraform {
  backend "azurerm" {
    # Storage account, container, client ID, and auth are supplied at runtime
    # via -backend-config flags from the CI/CD workflow (azure-terraform-deploy.yml).
    key = "landing-zones/main.tfstate"
  }
}
