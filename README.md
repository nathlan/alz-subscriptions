## Azure Landing Zone Subscriptions

![Terraform](https://img.shields.io/badge/Terraform-%7E%3E%201.10-623CE4?logo=terraform)
![Azure/azapi](https://img.shields.io/badge/Azure%2Fazapi-%7E%3E%202.5-0078D4?logo=microsoftazure)
![Azure/modtm](https://img.shields.io/badge/Azure%2Fmodtm-%7E%3E%200.3-0078D4?logo=microsoftazure)
![hashicorp/random](https://img.shields.io/badge/hashicorp%2Frandom-%3E%3D%203.3.2-844FBA?logo=terraform)
![hashicorp/time](https://img.shields.io/badge/hashicorp%2Ftime-%3E%3D0.9%2C%20%3C1.0-844FBA?logo=terraform)

Terraform configuration for Azure Landing Zone subscription vending using:
`github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.0.6`.

## Quick Start

- Follow full setup: [docs/SETUP.md](docs/SETUP.md)
- Understand architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Review prerequisites: [docs/prerequisites.md](docs/prerequisites.md)
- Replace placeholders in `terraform/terraform.tfvars`:
	- `subscription_billing_scope = "PLACEHOLDER_BILLING_SCOPE"`
	- `hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID"`
- Run locally from `terraform/`:

```bash
terraform init
terraform plan
```

## What You'll Need

- [ ] Terraform `~> 1.10`
- [ ] Azure OIDC identities for plan and apply
- [ ] Repository secrets:
	- `AZURE_CLIENT_ID_PLAN`
	- `AZURE_CLIENT_ID_APPLY`
	- `AZURE_TENANT_ID`
	- `AZURE_SUBSCRIPTION_ID`
- [ ] Backend resources from `terraform/backend.tf`:
	- `rg-terraform-state`
	- `stterraformstate`
	- `alz-subscriptions`
	- `landing-zones/main.tfstate`
- [ ] Valid billing scope, management group, and hub VNet resource ID

## Deployment Model

- PRs to `main` run plan through `.github/workflows/terraform-deploy.yml`
- Merges to `main` run apply via reusable workflow:
	`nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main`
- Manual dispatch is supported with `environment` input

## Documentation

- Analysis: [docs/analysis.md](docs/analysis.md)
- Prerequisites: [docs/prerequisites.md](docs/prerequisites.md)
- Setup guide: [docs/SETUP.md](docs/SETUP.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)