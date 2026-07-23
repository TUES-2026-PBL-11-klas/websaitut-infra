<div align="center">

# websaitut-infra

**This is the Terraform configuration** for the TUES website infrastructure on Microsoft Azure. A single `terraform apply` describes the whole platform: the container apps, the database, the secrets, the network, and the CI/CD identities.

![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![Microsoft Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Directus](https://img.shields.io/badge/Directus-6644FF?style=for-the-badge&logo=directus&logoColor=white)
![License: MIT](https://img.shields.io/github/license/TUES-2026-PBL-11-klas/websaitut-infra?style=for-the-badge&color=green)

**English | [Български](README.md)**

</div>

> **The k3s configuration has moved.** The previous GitOps stack (k3s + Flux, Traefik, Vault, VictoriaMetrics) now lives on and is archived at [codeberg.org/rangelovkiril/tues-website-infra](https://codeberg.org/rangelovkiril/tues-website-infra). This repository is Azure infrastructure only.

## Architecture

<!-- Diagram goes here -->

## Stack

| Layer | Resource | Notes |
|---|---|---|
| Compute | Azure Container Apps | Shared environment (Consumption); two apps per environment, website (Next.js) and CMS (Directus) |
| Database | PostgreSQL Flexible Server | v17, B1ms, fully private; separate databases for staging and prod |
| Secrets | Azure Key Vault | Shared vault plus one per environment, RBAC-based; opt-in data-plane firewall |
| Storage | Azure Storage | Directus media; separate container per environment |
| Network | VNet and subnets | Delegated subnet for PostgreSQL, private DNS zone |
| CI/CD | User-assigned identities | OIDC federation with GitHub Actions, least-privilege roles |

## Environments

Staging and prod are managed from a **single** state via `for_each` over locals, with no duplicated code. Staging scales to zero replicas (`min_replicas = 0`), prod keeps at least one.

## Structure

```
live/                   # the active infrastructure — where you work day to day
├── *.tf                 # root: RG, network, platform, database, vaults, apps, identities
├── terraform.tfvars     # input values (no secrets)
└── modules/
    ├── networking/      # VNet, subnets, private DNS zones
    ├── database/        # PostgreSQL Flexible Server
    ├── key_vault/       # Key Vault, RBAC, firewall
    └── container_app/   # reusable Container App (probes, secrets, registry, domains)

bootstrap/               # one-off: creates live/'s state backend — see bootstrap/README.md
```

## CI/CD

Images are built in the [application repo](https://github.com/TUES-2026-PBL-11-klas/websaitut) and pushed to GHCR. Deployment is `az containerapp update --image`, run by each environment's deploy identity over OIDC (no long-lived secrets in GitHub). Terraform has `ignore_changes` on the image so it doesn't fight with deploys.

## Secrets

Values are seeded into Key Vault manually on first setup. **Terraform never reads secrets** — it references them by a constructed URI, and the apps resolve them at runtime through their managed identities. The PostgreSQL admin password comes from `TF_VAR_pg_admin_password` (or a gitignored `*.secret.tfvars`).

## Running it

On a brand-new subscription, run [`bootstrap/`](bootstrap/README.md) once first — it creates the state backend before `live/` can `init`.

```bash
cd live
export TF_VAR_pg_admin_password="..."   # pulled from Key Vault
terraform init
terraform plan
terraform apply
```

State is kept in an Azure Storage backend (`rg-tfstate/elsystfstate`), created by `bootstrap/`.

## Roadmap

Open milestones in the repo: observability (alerting, availability), FinOps (budget alerts), enabling the Key Vault firewall, and custom domains for staging.
