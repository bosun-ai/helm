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

if [ -f "helm/ci/e2e-deps.yaml" ]; then
  kubectl -n "${NAMESPACE}" apply -f helm/ci/e2e-deps.yaml
  kubectl -n "${NAMESPACE}" wait --for=condition=Available deployment \
    -l app.kubernetes.io/part-of=bosun-e2e-deps --timeout=10m
else
  echo "helm/ci/e2e-deps.yaml not found; skipping dependency deploys."
fi

helm upgrade --install "${RELEASE_NAME}" helm/ \
  --namespace "${NAMESPACE}" \
  --values helm/ci/e2e-values.yaml

kubectl -n "${NAMESPACE}" wait --for=condition=Available deployment \
  -l app.kubernetes.io/instance="${RELEASE_NAME}" --timeout=10m

migrate_jobs=$(kubectl -n "${NAMESPACE}" get jobs \
  -l app.kubernetes.io/instance="${RELEASE_NAME}",app.kubernetes.io/component=stern-migrate \
  -o name 2>/dev/null || true)

if [ -n "${migrate_jobs}" ]; then
  kubectl -n "${NAMESPACE}" wait --for=condition=complete ${migrate_jobs} --timeout=10m
fi

if [ "${E2E_SMOKE:-true}" = "true" ] && [ -f "helm/ci/e2e-smoke.sh" ]; then
  helm/ci/e2e-smoke.sh
fi
