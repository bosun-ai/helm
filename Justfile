set shell := ["zsh", "-lc"]

@test:
  helm lint charts/bosun
  helm template charts/bosun
  helm unittest charts/bosun

@e2e:
  ci/e2e-run.sh

@e2e-github:
  E2E_SCM_MODE=github ci/e2e-run.sh

@e2e-gitlab:
  E2E_SCM_MODE=gitlab ci/e2e-run.sh
