#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${K3D_CLUSTER_NAME:-bosun-e2e}
NAMESPACE=${BOSUN_NAMESPACE:-fluyt}
RELEASE_NAME=${BOSUN_RELEASE_NAME:-bosun}
IMAGE_PULL_SECRET_NAME=${IMAGE_PULL_SECRET_NAME:-ghcr-pull}
USE_IMAGE_PULL_SECRET=${USE_IMAGE_PULL_SECRET:-false}

if [ -z "${KUBECONFIG:-}" ] && [ -f "helm/ci/kubeconfig" ]; then
  export KUBECONFIG="helm/ci/kubeconfig"
fi

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

if [ -f "helm/ci/e2e-secrets.yaml" ]; then
  kubectl -n "${NAMESPACE}" apply -f helm/ci/e2e-secrets.yaml
else
  echo "helm/ci/e2e-secrets.yaml not found; skipping secret creation."
fi

if [ -n "${GHCR_USERNAME:-}" ] && [ -n "${GHCR_TOKEN:-}" ]; then
  kubectl -n "${NAMESPACE}" create secret docker-registry "${IMAGE_PULL_SECRET_NAME}" \
    --docker-server=ghcr.io \
    --docker-username="${GHCR_USERNAME}" \
    --docker-password="${GHCR_TOKEN}" \
    --docker-email="${GHCR_EMAIL:-devnull@example.com}" \
    --dry-run=client -o yaml | kubectl apply -f -
  USE_IMAGE_PULL_SECRET=true
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
  --values helm/ci/e2e-values.yaml \
  $([ "${USE_IMAGE_PULL_SECRET}" = "true" ] && echo "--set global.imagePullSecrets[0]=${IMAGE_PULL_SECRET_NAME}")

kubectl -n "${NAMESPACE}" wait --for=condition=Available deployment \
  -l app.kubernetes.io/instance="${RELEASE_NAME}" --timeout=10m

migrate_jobs=$(kubectl -n "${NAMESPACE}" get jobs \
  -l app.kubernetes.io/instance="${RELEASE_NAME}",app.kubernetes.io/component=stern-migrate \
  -o name 2>/dev/null || true)

if [ -n "${migrate_jobs}" ]; then
  for job in ${migrate_jobs}; do
    if ! kubectl -n "${NAMESPACE}" get "${job}" >/dev/null 2>&1; then
      echo "Skipping wait for ${job} (no longer exists)."
      continue
    fi
    hook=$(kubectl -n "${NAMESPACE}" get "${job}" \
      -o jsonpath='{.metadata.annotations.helm\.sh/hook}' 2>/dev/null || true)
    if [ -n "${hook}" ]; then
      echo "Skipping wait for Helm hook job ${job} (Helm already waits on hooks)."
      continue
    fi
    kubectl -n "${NAMESPACE}" wait --for=condition=complete "${job}" --timeout=10m
  done
fi

if [ "${E2E_SMOKE:-true}" = "true" ] && [ -f "helm/ci/e2e-smoke.sh" ]; then
  helm/ci/e2e-smoke.sh
fi
