# Bosun (Fluyt) Helm Chart

This chart installs the Bosun on-prem stack (Bow, Stern, Quak) with optional helpers
(prepull, executor overprovisioner, executor storage class).

## Quick start

1) Create required secrets in the release namespace (examples below).
2) Install:

```
helm install bosun helm/ \
  --namespace fluyt \
  --create-namespace
```

## Required secrets (external)

The chart assumes secrets are managed outside Helm.

- `stern-secrets`
  - `REDIS_URL`
  - `DATABASE_URL` (if not using `stern.database.*`)
  - `QUAK_PAYLOAD_PUBLIC_KEY`
- `quak-secrets`
  - `QDRANT_URL`
  - `REDIS_URL`
  - `REDIS_INDEXING_URL`
  - `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `TAVILY_API_KEY`
  - `PAYLOAD_PRIVATE_KEY`
- `github-secrets`
  - `GITHUB_APP_NAME`
  - `GITHUB_APP_ID`
  - `GITHUB_APP_KEY`
  - `GITHUB_APP_CLIENT_ID`
  - `GITHUB_APP_CLIENT_SECRET`
  - `GITHUB_REDIRECT_URI`
- `fluyt-envelope-encr-secrets`
  - envelope encryption keys

## Bring-your-own services

- Postgres: set `stern.database.url` or `stern.database.existingSecret` + `existingSecretKey`.
- Redis/Qdrant: set `stern.env.REDIS_URL`, `quak.env.REDIS_URL`, `quak.env.REDIS_INDEXING_URL`, `quak.env.QDRANT_URL`.

## Billing defaults (on-prem)

On-prem installs disable Stripe/subscription checks by default:

```
stern:
  env:
    BILLING_DISABLED: "true"
```

The billing worker still deploys by default; override via `stern.billingWorker.enabled`.

## Testing

```
helm lint helm/
helm template helm/
helm unittest helm/
```
