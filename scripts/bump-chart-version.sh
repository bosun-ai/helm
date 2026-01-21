#!/usr/bin/env bash
set -euo pipefail

config="cliff.toml"
chart_dir="${CHART_DIR:-charts/bosun}"
chart_file="${chart_dir}/Chart.yaml"

if ! command -v git-cliff >/dev/null 2>&1; then
	echo "git-cliff is required but not installed" >&2
	exit 1
fi

current_version=$(grep -m1 '^version:' "$chart_file" | awk '{print $2}')
git_cliff_args=(--config "$config" --bumped-version --ignore-tags '^bosun-v')
next_version_raw=$(git-cliff "${git_cliff_args[@]}" | tr -d '\n')
next_version=$(echo "$next_version_raw" | sed -E 's/^bosun-//; s/^v//')

echo "Upgrading from ${current_version} to ${next_version} (raw: ${next_version_raw})"

if [[ -z "$next_version_raw" ]]; then
	echo "git-cliff did not return a version" >&2
	exit 1
fi

semver_regex='^[0-9]+\.[0-9]+\.[0-9]+([-][0-9A-Za-z.-]+)?([+][0-9A-Za-z.-]+)?$'
if ! [[ "$next_version" =~ $semver_regex ]]; then
	echo "git-cliff returned a non-SemVer version: '${next_version_raw}' -> '${next_version}'" >&2
	exit 1
fi

if [[ "$current_version" == "$next_version" ]]; then
	echo "Chart version is already up to date or failed to bump."
	exit 1
fi

if [[ "$current_version" != "$next_version" ]]; then
	tmp_file=$(mktemp)
	awk -v v="$next_version" '
    $1 == "version:" { $2 = v }
    { print }
  ' "$chart_file" >"$tmp_file"
	mv "$tmp_file" "$chart_file"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	echo "chart_version=$next_version" >>"$GITHUB_OUTPUT"
fi

echo "Next chart version: $next_version"
