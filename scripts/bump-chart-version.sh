#!/usr/bin/env bash
set -euo pipefail

config="cliff.toml"
chart_file="Chart.yaml"

if ! command -v git-cliff >/dev/null 2>&1; then
  echo "git-cliff is required but not installed" >&2
  exit 1
fi

current_version=$(grep -m1 '^version:' "$chart_file" | awk '{print $2}')
next_version=$(git cliff --config "$config" --bumped-version | tr -d '\n')

if [[ -z "$next_version" ]]; then
  echo "git-cliff did not return a version" >&2
  exit 1
fi

if [[ "$current_version" != "$next_version" ]]; then
  tmp_file=$(mktemp)
  awk -v v="$next_version" '
    $1 == "version:" { $2 = v }
    { print }
  ' "$chart_file" > "$tmp_file"
  mv "$tmp_file" "$chart_file"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "chart_version=$next_version" >> "$GITHUB_OUTPUT"
fi

echo "Next chart version: $next_version"
