# websaitut-infra

GitOps repository for the TUES website infrastructure, managed by FluxCD on a k3s cluster.

## Prerequisites

- k3s cluster running
- [Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli) installed
- GitHub fine-grained PAT scoped to this repo with **Contents** (read/write) and **Administration** (read/write) permissions

## Bootstrap

```bash
export GITHUB_TOKEN=<your-fine-grained-pat>

flux bootstrap github \
  --owner=TUES-2026-PBL-11-klas \
  --repository=websaitut-infra \
  --path=kustomizations \
  --personal=false
```

After bootstrap, update the Discord webhook URL:

```bash
kubectl -n flux-system create secret generic discord-webhook-url \
  --from-literal=address="https://discord.com/api/webhooks/YOUR_ACTUAL_WEBHOOK" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Structure

```
.
├── kustomizations/           # Flux Kustomization CRs (entry point)
├── infrastructure/
│   ├── traefik/              # Ingress controller
│   ├── cert-manager/         # TLS certificate management
│   ├── cert-manager-issuer/  # Let's Encrypt ClusterIssuer
├── external-secrets/
│   ├── operator/             # External Secrets Operator
│   └── store/                # Vault ClusterSecretStore
├── apps/
│   ├── postgres/             # PostgreSQL 16
│   ├── minio/                # S3-compatible object storage
│   ├── directus/             # Headless CMS
│   └── website/              # Next.js frontend
├── image-automation/         # Flux image update automation
└── notifications/            # Discord alerts
```

## Dependency chain

```
traefik → cert-manager → cert-manager-issuer
external-secrets-operator → external-secrets (vault store)
external-secrets → postgres ─┬─► directus ─► website
                   minio ────┘
```
