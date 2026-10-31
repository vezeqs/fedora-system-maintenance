#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

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

if [[ -f assets/source.sha256 ]]; then
  sha256sum -c assets/source.sha256
fi

echo "ok ${#images[@]} asset(s)"
