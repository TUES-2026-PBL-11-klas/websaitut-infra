# websaitut-infra
 
GitOps хранилище за инфраструктурата на уебсайта на ТУЕС. Управлява се от Flux CD върху k3s клъстер. Никакви ръчни `kubectl apply` — единственият начин за промяна на средата е чрез Git commit.
 
---
 
## Архитектура
 
```
┌─────────────────────────────────────────────────────────────────┐
│  k3s Cluster                                                    │
│                                                                 │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────────┐  │
│  │   Traefik   │    │ cert-manager │    │  External Secrets │  │
│  │  (ingress)  │    │ Let's Encrypt│    │  Operator         │  │
│  └──────┬──────┘    └──────────────┘    └────────┬──────────┘  │
│         │                                        │              │
│  ┌──────▼──────────────────────────────┐   ┌────▼──────────┐  │
│  │  namespace: website                 │   │  HashiCorp    │  │
│  │    Next.js Deployment               │   │  Vault        │  │
│  └──────────────┬──────────────────────┘   │  (external)   │  │
│                 │                           └───────────────┘  │
│  ┌──────────────▼──────────────────────┐                       │
│  │  namespace: directus                │                       │
│  │    Directus 11 Deployment           │                       │
│  └──────────────┬──────────────────────┘                       │
│                 │                                               │
│  ┌──────────────▼──────────────────────┐                       │
│  │  namespace: postgres                │                       │
│  │    PostgreSQL 16 StatefulSet        │                       │
│  └─────────────────────────────────────┘                       │
│                                                                 │
│  ┌──────────────────────────────────────┐                      │
│  │  namespace: minio                    │                      │
│  │    MinIO StatefulSet (S3-compatible) │                      │
│  └──────────────────────────────────────┘                      │
│                                                                 │
│  ┌──────────────────────────────────────┐                      │
│  │  namespace: vm + grafana             │                      │
│  │    VictoriaMetrics · Grafana         │                      │
│  │    VictoriaLogs · VMAlert            │                      │
│  └──────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```
 
---
 
## Структура на хранилището
 
```
.
├── kustomizations/               # Flux Kustomization CRs — точка за вход
│   ├── kustomization.yaml        # Главна Kustomization (реда на зависимостите)
│   ├── apps-postgres.yaml
│   ├── apps-minio.yaml
│   ├── apps-directus.yaml
│   ├── apps-website.yaml
│   ├── ingress-traefik.yaml
│   ├── ingress-cert-manager.yaml
│   ├── ingress-cert-manager-issuer.yaml
│   ├── secrets-operator.yaml     # External Secrets Operator
│   ├── secrets-store.yaml        # Vault ClusterSecretStore
│   ├── secrets-reloader.yaml     # Stakater Reloader
│   ├── gitops-image-automation.yaml
│   ├── gitops-receiver.yaml      # GitHub webhook → Flux receiver
│   ├── observability-vm-operator.yaml
│   ├── observability-vm.yaml
│   ├── observability-exporters.yaml
│   ├── observability-victorialogs.yaml
│   └── observability-grafana.yaml
├── apps/
│   ├── postgres/                 # PostgreSQL 16 StatefulSet + PVC
│   ├── minio/                    # MinIO StatefulSet + Service
│   ├── directus/                 # Directus Deployment + Ingress
│   └── website/                  # Next.js Deployment + Ingress
│       └── deployment.yaml       # Съдържа image tag коментар за Flux
├── infrastructure/
│   ├── ingress/                  # Traefik HelmRelease + cert-manager
│   ├── secrets/                  # External Secrets Operator + Vault store
│   ├── gitops/
│   │   ├── image-automation/     # ImageRepository + ImagePolicy + ImageUpdateAutomation
│   │   └── receiver/             # GitHub webhook receiver
│   └── observability/
│       ├── victoriametrics/      # VMSingle · VMAgent · VMAlert · Alertmanager
│       ├── victorialogs/         # VictoriaLogs StatefulSet
│       ├── exporters/            # kube-state-metrics · node-exporter
│       └── grafana/              # Grafana StatefulSet + Dashboards + Datasources
├── jobs/
│   └── minio/                    # MinIO init Job (създава bucket-и и policies)
└── vault/
    ├── README.md                 # Документация за Vault настройката
    ├── vault.hcl                 # Vault конфигурация (Raft backend)
    ├── vault.service             # systemd unit файл
    └── policies/                 # ACL policies (developer · cluster)
```
 
---
 
## Верига на зависимостите
 
```
traefik → cert-manager → cert-manager-issuer
external-secrets-operator → vault-store (ClusterSecretStore)
vault-store → postgres ──┬──► directus ──► website
             minio ───────┘
```
 
Flux прилага ресурсите в точно този ред чрез `dependsOn` в Kustomization файловете.
 
---
 
## Предварителни изисквания
 
- k3s клъстер (работещ)
- [Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli) инсталиран
- GitHub fine-grained PAT с права **Contents** (read/write) и **Administration** (read/write) за това хранилище
- HashiCorp Vault инстанция с попълнени secrets (вижте [vault/README.md](vault/README.md))
---
 
## Bootstrap на клъстера
 
```bash
export GITHUB_TOKEN=<your-fine-grained-pat>
 
flux bootstrap github \
  --owner=TUES-2026-PBL-11-klas \
  --repository=websaitut-infra \
  --path=kustomizations \
  --personal=false
```
 
След bootstrap, добавете Discord webhook URL за нотификации:
 
```bash
kubectl -n flux-system create secret generic discord-webhook-url \
  --from-literal=address="https://discord.com/api/webhooks/YOUR_WEBHOOK" \
  --dry-run=client -o yaml | kubectl apply -f -
```
 
---
 
## Secrets Management
 
Всички тайни се управляват от **HashiCorp Vault** (self-hosted, отделен сървър на `https://vault.rangelovk.xyz`). External Secrets Operator ги синхронизира в Kubernetes Secrets автоматично. Никой secret не е дефиниран като plain text в Kubernetes Secrets или ConfigMaps. Stakater Reloader рестартира pod-ове автоматично при промяна на secret.
 
### Архитектура на Vault
 
Vault работи зад [Caddy](https://caddyserver.com/) reverse proxy, който управлява TLS сертификати от Let's Encrypt:
 
```
┌───────────────────────────────────────┐
│  Hosting                              │
│                                       │
│  ┌─────────┐     ┌──────────────────┐ │
│  │  Caddy  │ --> │  Vault           │ │
│  │  :443   │     │  127.0.0.1:8200  │ │
│  └─────────┘     │                  │ │
│                  │  Storage: Raft   │ │
│                  │  /opt/vault/data │ │
│                  └──────────────────┘ │
└───────────────────────────────────────┘
```
 
Конфигурацията е ориентирана към development удобство, но е отворена за production разширение: single-node Raft backend, разделени политики за достъп, 1 unseal ключ и revoked root token.
 
### KV структура
 
KV v2 с 10 версии на промените и soft delete. Структурата е flat — по service:
 
```
secret/
├── directus/   # admin token, secret key, app key
├── postgres/   # username, password, database
├── minio/      # root credentials, directus bucket credentials
└── flux/       # ghcr_auth (GHCR token), github_webhook_token, Discord webhook
```
 
### Политики за достъп
 
| Policy | Достъп | Използва се от |
|---|---|---|
| `developer` | пълен CRUD върху `secret/*` | разработчици (userpass) |
| `cluster` | read-only върху `secret/*` | External Secrets Operator, CI |
 
### Auth методи
 
**userpass** — за хора. Два вида акаунти: `admin` (пълен достъп до secrets и Vault управление) и `developer` (CRUD достъп до secrets).
 
**kubernetes** — за External Secrets Operator от k3s клъстера. Конфигуриран с:
- `kubernetes_host` — Kubernetes API endpoint на клъстера
- `token_reviewer_jwt` — токен на ServiceAccount `vault-auth` в `external-secrets` namespace с `system:auth-delegator` ClusterRoleBinding
- `kubernetes_ca_cert` — CA сертификатът на клъстера
Ролята `external-secrets` е привързана към ServiceAccount `vault-auth` и получава `cluster` policy — ESO може да чете тайни от KV и да ги синхронизира като Kubernetes Secrets в съответните namespace-и.
 
### Конфигурационни файлове
 
| Файл | Местоположение на сървъра |
|---|---|
| [`vault/vault.hcl`](vault/vault.hcl) | `/etc/vault.d/vault.hcl` |
| [`vault/vault.service`](vault/vault.service) | `/etc/systemd/system/vault.service` |
| [`vault/policies/`](vault/policies) | `/opt/vault/policies/` |
| данни | `/opt/vault/data/` |
 
### Бъдещо развитие
 
- [ ] **Google OIDC auth** — hardcoded `bound_claims` за конкретни акаунти, след това role mapping
- [ ] **Auto-unseal** — в момента изисква ръчен unseal при рестарт; целта е автоматизация чрез transit или cloud KMS
---
 
## CI/CD Pipeline
 
### CI — GitHub Actions (в `websaitut` репото)
 
При всеки Pull Request и push:
 
1. ESLint + Prettier проверка
2. TypeScript type check
3. Next.js build
4. Push на container image в GHCR с таг: `YYYYMMDDHHMMSS-<git-sha>`
### CD — Flux Image Automation
 
1. Flux `ImageRepository` следи `ghcr.io/tues-2026-pbl-11-klas/websaitut/website` на всяка минута
2. `ImagePolicy` избира най-новия таг по alphabetical ред (`timestamp-sha` формат)
3. `ImageUpdateAutomation` обновява image tag-а в `apps/website/deployment.yaml` и прави commit в `main`
4. Flux засича промяната и синхронизира клъстера
```
git push → GitHub Actions build → push image → Flux detects → update infra repo → deploy
```
 
### Webhook ускорение
 
GitHub изпраща push webhook към `flux-webhook.vdemirev.com`, което кара Flux да синхронизира незабавно вместо да чака polling interval.
 
---
 
## Observability
 
| Компонент | Роля |
|---|---|
| VictoriaMetrics (VMSingle) | Съхранение на метрики (14 дни retention) |
| VMAgent | Scraping на метрики от всички pod-ове |
| VMAlert | Evaluation на alert rules |
| VictoriaLogs | Централизирани логове |
| kube-state-metrics | Метрики за Kubernetes обекти |
| Grafana | Визуализация на метрики и логове |
| Alertmanager | Изпращане на Discord webhook нотификации |
 
Grafana е достъпна на `https://grafana.<cluster-domain>`.
 
---
 
## Инструкции за локална разработка на инфраструктура
 
```bash
# Проверка на Flux статус
flux get all -A
 
# Форсирано синхронизиране
flux reconcile kustomization flux-system --with-source
 
# Проверка на image automation
flux get image all -A
 
# Логове на конкретен pod
kubectl -n website logs -l app=website --tail=100
 
# Проверка на secrets от Vault
kubectl -n website get secret directus-token -o jsonpath='{.data}' | base64 -d
```
 