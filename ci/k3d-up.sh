#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${K3D_CLUSTER_NAME:-bosun-e2e}
K3D_PLATFORM=${K3D_PLATFORM:-}

if ! command -v k3d >/dev/null 2>&1; then
  echo "k3d not found. Install k3d to run e2e tests." >&2
  exit 1
fi

if [ -n "${K3D_PLATFORM}" ]; then
  echo "Using docker platform override: ${K3D_PLATFORM}"
  DOCKER_DEFAULT_PLATFORM="${K3D_PLATFORM}" k3d cluster create "${CLUSTER_NAME}" \
    --agents 1 \
    --servers 1
else
  k3d cluster create "${CLUSTER_NAME}" \
  --agents 1 \
  --servers 1
fi

if [ -f "ci/kubeconfig" ]; then
  rm -f ci/kubeconfig
fi

k3d kubeconfig get "${CLUSTER_NAME}" > ci/kubeconfig
echo "Wrote kubeconfig to ci/kubeconfig"
KUBECONFIG=ci/kubeconfig kubectl cluster-info
