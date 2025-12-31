#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${K3D_CLUSTER_NAME:-bosun-e2e}
NAMESPACE=${BOSUN_NAMESPACE:-fluyt}
RELEASE_NAME=${BOSUN_RELEASE_NAME:-bosun}

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

if [ -f "helm/ci/e2e-secrets.yaml" ]; then
  kubectl -n "${NAMESPACE}" apply -f helm/ci/e2e-secrets.yaml
else
  echo "helm/ci/e2e-secrets.yaml not found; skipping secret creation."
fi

helm upgrade --install "${RELEASE_NAME}" helm/ \
  --namespace "${NAMESPACE}" \
  --values helm/ci/e2e-values.yaml

kubectl -n "${NAMESPACE}" wait --for=condition=Available deployment --all --timeout=10m
