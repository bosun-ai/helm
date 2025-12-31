set shell := ["zsh", "-lc"]

@test:
  helm lint .
  helm template .
  helm unittest .

@e2e:
  ci/e2e-run.sh
