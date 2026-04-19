# Vault 
Secret managment-ът се осъществява от self-hosted HashiCorp Vault. [Конфигурацията](#структура-на-конфигурацията) му е ориентирана към удобство за development, но същевременно е отворена за разширение и готовност за production:
- single-node Raft backend;
- различни policy-та за достъп;
- разделение на secret-ите;
- 1 unseal ключ и revoked root token. 

> Достъпен на https://vault.rangelovk.xyz

---

## Бъдещо развитие
- [ ] **Google OIDC auth** - първоначално с hardcoded `bound_claims` за конкретни Google акаунти, по-късно role mapping за по-гъвкаво управление
- [ ] **Auto-unseal** - в момента при рестарт на service-а трябва ръчнен unseal с ключ; целта е автоматизация чрез transit или cloud KMS

---

## Архитектура
За осигуряване на безопасен трафик използваме [Caddy](https://caddyserver.com/) като reverse proxy. Той използва безплатни сертификати от [Let's Encrypt](https://letsencrypt.org/), които автоматично обновява. 
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

---

## Структура на конфигурацията
На сървъра конфигурацията за Vault е разделена по следният начин:
- [`/etc/vault.d/vault.hcl`](config/vault.hcl) - основна кофигурация на хранилището
- [`/etc/systemd/system/vault.service`](config/vault.service) - systemd услуга за хранилището
- `/opt/vault/data/` - папката за данни на storage backend-а
- [`/opt/vault/policies/`](policies) - ACL policies

## KV структура
Използваме KV v2 с 10 версии на промените и soft delete. Структурата е flat — по service, не по роля на потребителя:
```
secret/
├── directus/        # admin credentials
├── postgres/        # credentials
├── minio/           # credential (root + directus bucket)
└── flux/            # registry token, fine-graned token for GitHub repo, webhooks
```
Достъпът се контролира от [policy-тата](policies) — `developer` има пълен CRUD, `cluster` е read-only. В момента са широки - имат '*' capabilities върху целият secret path, но това е допустимо, тъй като системата ни не изисква multi-tenant модели, а и external secrets operator-а дава на всяка услуга само нужното ѝ. 

## Auth
### userpass
Основният метод за автентикация на хора. Има два вида акаунти — `admin` с пълен достъп до secrets и Vault управление (auth methods, policies, mounts), и `developer` с CRUD достъп до всички secrets.

### kubernetes
Методът, с който External Secrets Operator-ът от k3s клъстера се автентикира пред Vault. Конфигуриран е с:
- `kubernetes_host` — Kubernetes API endpoint на клъстера;
- `token_reviewer_jwt` — токен на ServiceAccount-а `vault-auth` в namespace `external-secrets`, който има `system:auth-delegator` ClusterRoleBinding и може да валидира други ServiceAccount токени;
- `kubernetes_ca_cert` — CA сертификатът на клъстера.

Ролята `external-secrets` е привързана към ServiceAccount-а `vault-auth` (в `external-secrets` namespace) и получава `cluster` policy — read-only достъп до всички secrets. Това позволява на ESO да чете тайни от KV и да ги синхронизира като Kubernetes Secrets в съответните namespace-и.

### jwt / oidc (GitHub Actions)
Използва се от CI pipeline-ите за достъп до registry token-и и други build-time тайни без статични credentials в GitHub secrets.
