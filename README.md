# Bosun (Fluyt) Helm Chart

This chart installs the Bosun on-prem stack (Bow, Stern, Quak) with optional helpers
(prepull, executor overprovisioner, executor storage class).

## Quick start

1) Create required secrets in the release namespace.
2) Install:

```
helm install bosun helm/ \
  --namespace fluyt \
  --create-namespace
```

### Zero-config quickstart (non-production)

For a local/demo install with bundled services and dummy secrets:

```
kubectl create namespace fluyt
kubectl -n fluyt apply -f helm/examples/quickstart-secrets.yaml
helm install bosun helm/ --namespace fluyt
```

Replace the dummy values before production use.

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

## Bundled services (default)

Postgres, Redis (shared + indexing), and Qdrant are installed alongside the chart by default.
Disable any of them in `values.yaml` if you are providing external services.

```
postgres:
  enabled: false
redis:
  enabled: false
qdrant:
  enabled: false
```

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

`helm unittest` requires the helm-unittest plugin:

```
helm plugin install https://github.com/helm-unittest/helm-unittest --verify=false
```

## E2E (k3d)

The lightweight harness lives in `helm/ci/` and uses:
- `helm/ci/e2e-secrets.yaml` for placeholder secrets
- `helm/ci/e2e-deps.yaml` is optional (set `E2E_DEPS=true`) if you want standalone deps
  instead of the bundled services

Run:

```
K3D_PLATFORM=linux/amd64 helm/ci/k3d-up.sh
GHCR_USERNAME=... GHCR_TOKEN=... helm/ci/e2e-run.sh
helm/ci/e2e-smoke.sh
helm/ci/k3d-down.sh
```

Set `E2E_SMOKE=false` to skip smoke checks in `e2e-install.sh`.
If you already have an image pull secret, set `USE_IMAGE_PULL_SECRET=true` and `IMAGE_PULL_SECRET_NAME=...`
to inject it into the Helm release.

`k3d-up.sh` writes a kubeconfig to `helm/ci/kubeconfig` and the other scripts will use it automatically
if `KUBECONFIG` is not already set.
Use `K3D_PLATFORM=linux/amd64` on Apple Silicon if the Bosun images are not published for arm64.
