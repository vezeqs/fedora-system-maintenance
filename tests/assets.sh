#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
images=(assets/*.png)
if (( ${#images[@]} == 0 )); then
  echo "no assets found" >&2
  exit 1
fi

for img in "${images[@]}"; do
  if [[ ! -s $img ]]; then
    echo "missing or empty: $img" >&2
    exit 1
  fi
done

echo "ok ${#images[@]} asset(s)"
