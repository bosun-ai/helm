# Repository Guidelines

## Project Structure & Module Organization
- `charts/bosun/Chart.yaml` and `charts/bosun/values.yaml` define chart metadata and defaults; `charts/bosun/values.schema.json` validates user values.
- `charts/bosun/templates/` contains Helm templates organized by component (e.g., `charts/bosun/templates/bow/`, `charts/bosun/templates/stern/`, `charts/bosun/templates/quak/`) plus bundled services (Postgres/Redis/Qdrant).
- `charts/bosun/tests/` holds Helm unit tests (`*_test.yaml`) and snapshots in `charts/bosun/tests/__snapshot__/`.
- `ci/` contains k3d-based E2E scripts and example values/secrets.
- `examples/` provides quickstart secrets templates for local/demo installs.

## Build, Test, and Development Commands
- `helm lint charts/bosun` — validate chart structure and values.
- `helm template charts/bosun` — render templates locally for inspection.
- `helm unittest charts/bosun` — run Helm unit tests (requires the `helm-unittest` plugin).
- `just test` — runs the lint/template/unittest trio (see `Justfile`).
- `ci/k3d-up.sh` → `ci/e2e-run.sh` → `ci/e2e-smoke.sh` → `ci/k3d-down.sh` — full E2E flow on a local k3d cluster.

## Coding Style & Naming Conventions
- YAML and Helm templates use 2-space indentation; keep Go template directives aligned with surrounding YAML.
- Values keys use lower camelCase (e.g., `imagePullSecrets`, `fullnameOverride`); keep new keys consistent.
- Component templates follow `charts/bosun/templates/<component>/` structure and use `bosun.*` helper template names.

## Testing Guidelines
- Unit tests use the `helm-unittest` framework and live in `charts/bosun/tests/*_test.yaml`.
- Snapshots are stored in `charts/bosun/tests/__snapshot__/` and should be updated intentionally when output changes.
- E2E tests are driven by `ci/e2e-run.sh` and accept env vars like `E2E_SCM_MODE=gitlab`.

## Commit & Pull Request Guidelines
- Commit messages follow a conventional style: `feat:`, `fix:`, `docs:`, `chore:` (see `git log`).
- PRs should include a clear description, a testing note (commands run), and any config/values changes.
- If secrets or image tags are referenced, ensure examples or documentation are updated accordingly.

## Security & Configuration Notes
- Secrets are expected via Kubernetes Secrets; avoid committing real credentials. Use `examples/quickstart-secrets.yaml` as a template.
- Keep bundled service toggles and external service URLs documented when adding new dependencies.
