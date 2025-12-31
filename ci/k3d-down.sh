#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${K3D_CLUSTER_NAME:-bosun-e2e}

if ! command -v k3d >/dev/null 2>&1; then
  echo "k3d not found. Install k3d to run e2e tests." >&2
  exit 1
fi

k3d cluster delete "${CLUSTER_NAME}"
