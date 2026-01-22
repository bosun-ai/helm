# Bosun (Fluyt) Helm Chart

This chart installs the Bosun on-prem stack (Bow, Stern, Quak) with optional helpers
(prepull, executor overprovisioner, executor storage class).

## Quickstart (minimal choices)

You must choose:
- SCM mode: `github` (default) or `gitlab`.
- Secrets: provide `stern-secrets`, `quak-secrets`, and the SCM secret for the chosen mode.
- External services: keep bundled Postgres/Redis/Qdrant (default) or point to your own.

Then do (namespace must already exist):

```
kubectl -n bosun apply -f ./your-secrets.yaml
```

Add the Helm repo:

```
helm repo add bosun https://bosun-ai.github.io/helm
helm repo update
```

Install for GitHub mode (default):

```
helm install bosun bosun/bosun \
  --namespace bosun
```

Install for GitLab mode:

```
helm install bosun bosun/bosun \
  --namespace bosun \
  --set scm.mode=gitlab \
  --set scm.gitlab.patSecretName=gitlab-secrets
```

Verify:

```
kubectl -n bosun get pods
```

## Zero-config quickstart (non-production)

For a local/demo install with bundled services and dummy secrets:

```
kubectl -n bosun apply -f helm/examples/quickstart-secrets.yaml
helm install bosun bosun/bosun --namespace bosun
```

Replace the dummy values before production use.

## Required secrets (explicit values)

The chart expects these values to be provided as Kubernetes Secrets.
Build them explicitly so it is clear what each value is used for.

Stern (Rails app):
- `SECRET_KEY_BASE`: Rails secret key base.
- `DATABASE_URL`: only if using external Postgres and `stern.database.*` is not set.
- `REDIS_URL`: only if using external Redis.

```
kubectl -n bosun create secret generic stern-secrets \
  --from-literal=SECRET_KEY_BASE=... \
  --from-literal=DATABASE_URL=... \
  --from-literal=REDIS_URL=...
```

Quak (worker/API):
- `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY` for LLM providers.
- `TAVILY_API_KEY` (if using Tavily search).
- `REDIS_URL`, `REDIS_INDEXING_URL`, `QDRANT_URL`: only if using external services.

```
kubectl -n bosun create secret generic quak-secrets \
  --from-literal=OPENAI_API_KEY=... \
  --from-literal=ANTHROPIC_API_KEY=... \
  --from-literal=TAVILY_API_KEY=... \
  --from-literal=REDIS_URL=... \
  --from-literal=REDIS_INDEXING_URL=... \
  --from-literal=QDRANT_URL=...
```

GitHub mode secrets (GitHub App + OAuth):
- `GITHUB_APP_NAME`
- `GITHUB_APP_ID`
- `GITHUB_APP_KEY`
- `GITHUB_APP_CLIENT_ID`
- `GITHUB_APP_CLIENT_SECRET`
- `GITHUB_REDIRECT_URI`

```
kubectl -n bosun create secret generic github-secrets \
  --from-literal=GITHUB_APP_NAME=... \
  --from-literal=GITHUB_APP_ID=... \
  --from-literal=GITHUB_APP_KEY=... \
  --from-literal=GITHUB_APP_CLIENT_ID=... \
  --from-literal=GITHUB_APP_CLIENT_SECRET=... \
  --from-literal=GITHUB_REDIRECT_URI=...
```

## SCM mode (GitHub or GitLab)

Bosun runs in either GitHub mode or GitLab mode (mutually exclusive).

```
scm:
  mode: github  # or gitlab
```

### GitHub mode (default)

Provide the GitHub App/OAuth secrets in `github-secrets` (see above).

### GitLab mode

GitLab mode uses a personal access token (PAT) and disables authentication by default.
Provide a secret with `GITLAB_PAT` and set:

```
scm:
  mode: gitlab
  gitlab:
    patSecretName: gitlab-secrets
    apiEndpoint: https://gitlab.com/api/v4
```

Create the secret:

```
kubectl -n bosun create secret generic gitlab-secrets \
  --from-literal=GITLAB_PAT=glpat-xxxx
```

## Envelope encryption keys

The chart generates a `fluyt-envelope-encr-secrets` Secret on install containing:
- `APP_PAYLOAD_PRIVATE_KEY` (base64 PEM)
- `QUAK_PAYLOAD_PUBLIC_KEY` (base64 PEM)

The generation uses the same RSA keypair workflow as `fluyt/justfile` (openssl).

To provide your own keys instead:

```
envelopeEncryption:
  create: false
```

Create a Secret named `fluyt-envelope-encr-secrets` with those keys, or update
`stern.secrets.existing` and `quak.secrets.existing` to point at your secret.

The generator images are configurable:

```
envelopeEncryption:
  job:
    opensslImage:
      repository: alpine/openssl
      tag: latest
    kubectlImage:
      repository: bitnami/kubectl
      tag: latest
```

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

## Images and versions

All Bosun components (Bow, Stern, Quak) must use the same version tag.
By default, the chart uses the chart `appVersion` for these images.
To override, set a single tag via:

```
global:
  image:
    tag: "2025.01.01"
```

Repositories remain configurable per component:

```
bow:
  image:
    repository: ghcr.io/bosun-ai/fluyt/bow
stern:
  image:
    repository: ghcr.io/bosun-ai/fluyt/stern
quak:
  image:
    repository: ghcr.io/bosun-ai/fluyt/quak
```

## Billing defaults (on-prem)

On-prem installs disable Stripe/subscription checks by default:

```
stern:
  env:
    BILLING_DISABLED: "true"
```

The billing worker still deploys by default; override via `stern.billingWorker.enabled`.

## Stern host authorization (Rails)

Rails host authorization defaults to `stern` and `*.bosun.ai`. To allow other
hosts, provide a comma-separated list via Helm:

```
stern:
  hostAuthorization:
    allowedHosts:
      - api.bosun.example.com
      - app.bosun.example.com
      - stern
```

## Testing

```
helm lint helm/charts/bosun
helm template helm/charts/bosun
helm unittest helm/charts/bosun
```

`helm unittest` requires the helm-unittest plugin:

```
helm plugin install https://github.com/helm-unittest/helm-unittest --verify=false
```

## E2E (k3d)

The lightweight harness lives in `helm/ci/` and uses:
- `helm/ci/e2e-secrets.yaml` for placeholder secrets
- `helm/ci/e2e-secrets-gitlab.yaml` when `E2E_SCM_MODE=gitlab`
- `helm/ci/e2e-deps.yaml` is optional (set `E2E_DEPS=true`) if you want standalone deps
  instead of the bundled services

Run:

```
K3D_PLATFORM=linux/amd64 helm/ci/k3d-up.sh
GHCR_USERNAME=... GHCR_TOKEN=... helm/ci/e2e-run.sh
helm/ci/e2e-smoke.sh
helm/ci/k3d-down.sh
```

Set `E2E_SCM_MODE=gitlab` to run the GitLab-mode e2e values/secrets.
Set `E2E_SMOKE=false` to skip smoke checks in `e2e-run.sh`.
If you already have an image pull secret, set `USE_IMAGE_PULL_SECRET=true` and `IMAGE_PULL_SECRET_NAME=...`
to inject it into the Helm release.

`k3d-up.sh` writes a kubeconfig to `helm/ci/kubeconfig` and the other scripts will use it automatically
if `KUBECONFIG` is not already set.
Use `K3D_PLATFORM=linux/amd64` on Apple Silicon if the Bosun images are not published for arm64.
