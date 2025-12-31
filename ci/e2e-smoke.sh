#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${BOSUN_NAMESPACE:-fluyt}
RELEASE_NAME=${BOSUN_RELEASE_NAME:-bosun}

if [ -z "${KUBECONFIG:-}" ] && [ -f "helm/ci/kubeconfig" ]; then
  export KUBECONFIG="helm/ci/kubeconfig"
fi

stern_service=$(kubectl -n "$NAMESPACE" get svc \
  -l app.kubernetes.io/instance="${RELEASE_NAME}",app.kubernetes.io/component=stern \
  -o jsonpath='{.items[0].metadata.name}')
quak_service=$(kubectl -n "$NAMESPACE" get svc \
  -l app.kubernetes.io/instance="${RELEASE_NAME}",app.kubernetes.io/component=quak \
  -o jsonpath='{.items[0].metadata.name}')

if [ -z "$stern_service" ] || [ -z "$quak_service" ]; then
  echo "stern/quak services not found in namespace ${NAMESPACE}" >&2
  exit 1
fi

stern_pf_log=$(mktemp)
quak_pf_log=$(mktemp)

cleanup() {
  if [ -n "${stern_pf_pid:-}" ]; then kill "$stern_pf_pid" 2>/dev/null || true; fi
  if [ -n "${quak_pf_pid:-}" ]; then kill "$quak_pf_pid" 2>/dev/null || true; fi
  rm -f "$stern_pf_log" "$quak_pf_log"
}
trap cleanup EXIT

kubectl -n "$NAMESPACE" port-forward "svc/${stern_service}" 18080:3000 >"$stern_pf_log" 2>&1 &
stern_pf_pid=$!

kubectl -n "$NAMESPACE" port-forward "svc/${quak_service}" 18081:3001 >"$quak_pf_log" 2>&1 &
quak_pf_pid=$!

sleep 2

curl -fsS "http://127.0.0.1:18080/up" >/dev/null
curl -fsS "http://127.0.0.1:18081/health" >/dev/null

echo "Smoke checks passed."
