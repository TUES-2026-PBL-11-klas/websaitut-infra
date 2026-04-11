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
  --path=. \
  --personal=false \
  --components="source-controller,kustomize-controller,notification-controller"
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
├── kustomizations.yaml       # Flux Kustomization wiring
├── infrastructure/
│   ├── postgres/             # PostgreSQL 16
│   ├── minio/                # S3-compatible object storage
│   └── directus/             # Headless CMS
├── apps/
│   └── website/              # Next.js frontend
└── notifications/            # Discord alerts
```

## Dependency chain

```
postgres ─┬─► directus ─► website
minio ────┘
```
