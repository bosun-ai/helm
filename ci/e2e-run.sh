#!/usr/bin/env bash
set -xeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CHART_DIR=$(cd "${SCRIPT_DIR}/../charts/bosun" && pwd)

NAMESPACE=${BOSUN_NAMESPACE:-bosun}
RELEASE_NAME=${BOSUN_RELEASE_NAME:-bosun}
IMAGE_PULL_SECRET_NAME=${IMAGE_PULL_SECRET_NAME:-ghcr-pull}
USE_IMAGE_PULL_SECRET=${USE_IMAGE_PULL_SECRET:-false}
E2E_DEPS=${E2E_DEPS:-false}
E2E_RESET=${E2E_RESET:-true}
E2E_SCM_MODE=${E2E_SCM_MODE:-github}

if [ -z "${KUBECONFIG:-}" ] && [ -f "${SCRIPT_DIR}/kubeconfig" ]; then
	export KUBECONFIG="${SCRIPT_DIR}/kubeconfig"
fi

if [ "${E2E_RESET}" = "true" ]; then
	kubectl delete namespace "${NAMESPACE}" --ignore-not-found
	helm -n "${NAMESPACE}" uninstall "${RELEASE_NAME}" >/dev/null 2>&1 || true
fi

kubectl create namespace "${NAMESPACE}"

SECRETS_FILE="${SCRIPT_DIR}/e2e-secrets.yaml"
VALUES_ARGS=(--values "${SCRIPT_DIR}/e2e-values.yaml")
if [ "${E2E_SCM_MODE}" = "gitlab" ]; then
	SECRETS_FILE="${SCRIPT_DIR}/e2e-secrets-gitlab.yaml"
	VALUES_ARGS+=(--values "${SCRIPT_DIR}/e2e-values-gitlab.yaml")
fi

if [ -f "${SECRETS_FILE}" ]; then
	kubectl -n "${NAMESPACE}" apply -f "${SECRETS_FILE}"
else
	echo "e2e secrets file not found; skipping secret creation."
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

if [ "${E2E_DEPS}" = "true" ] && [ -f "${SCRIPT_DIR}/e2e-deps.yaml" ]; then
	kubectl -n "${NAMESPACE}" apply -f "${SCRIPT_DIR}/e2e-deps.yaml"
	kubectl -n "${NAMESPACE}" wait --for=condition=Available deployment \
		-l app.kubernetes.io/part-of=bosun-e2e-deps --timeout=10m
else
	echo "Skipping dependency deploys (E2E_DEPS=false)."
fi

helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
	--namespace "${NAMESPACE}" \
	"${VALUES_ARGS[@]}" \
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

if [ "${E2E_SMOKE:-true}" = "true" ] && [ -f "${SCRIPT_DIR}/e2e-smoke.sh" ]; then
	"${SCRIPT_DIR}/e2e-smoke.sh"
fi
