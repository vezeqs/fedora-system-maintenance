#!/usr/bin/env bash
set -euo pipefail

script=${1:?usage: static.sh <script>}

bash -n "$script"
grep -q '\[y/N\]' "$script"
grep -q 'DRY_RUN' "$script"
grep -q 'EUID' "$script"

if grep -q 'rm -rf' "$script"; then
  echo "rm -rf is not allowed in this repository" >&2
  exit 1
fi

echo "ok $script"
