#!/usr/bin/env bash
set -euo pipefail

script=${1:?usage: smoke.sh <script>}

if [[ ! -x $script ]]; then
  echo "not executable: $script" >&2
  exit 1
fi

help=$("$script" --help)
grep -q 'Usage:' <<<"$help"
grep -q -- '--dry-run' <<<"$help"

if "$script" --definitely-not-an-option >/dev/null 2>&1; then
  echo "unknown option was accepted: $script" >&2
  exit 1
fi

echo "ok $script"
