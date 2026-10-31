#!/usr/bin/env bash
set -euo pipefail

script=${1:-./fedora-system-maintenance.sh}

if grep -q 'rpm-ostree cleanup -p' "$script"; then
  echo "rpm-ostree cleanup -p removes the pending deployment, which is the upgrade just staged" >&2
  exit 1
fi
grep -q 'rpm-ostree cleanup -b' "$script"

echo "ok atomic cleanup leaves the pending deployment alone"
