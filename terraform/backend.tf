terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "alz-subscriptions"
    key                  = "landing-zones/main.tfstate"
    use_oidc             = true
  }
}