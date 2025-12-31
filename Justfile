set shell := ["zsh", "-lc"]

@test:
  helm lint .
  helm template .
  helm unittest .
