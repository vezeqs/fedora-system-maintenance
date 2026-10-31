#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
mock=$(mktemp -d)
trap 'rm -rf "$mock"' EXIT

cat > "$mock/rpm-ostree" <<'MOCK'
#!/usr/bin/env bash
echo "rpm-ostree $*" >> /tmp/rpm-ostree.log
case "$1" in
  upgrade)
    if [[ ${2:-} == --check ]]; then printf '  kernel 6.11.4-301.fc41\n'; exit 0; fi
    touch /run/ostree-pending
    echo "Staging deployment... done"
    ;;
  cleanup) echo "cleanup $*" ;;
  status)
    if [[ -f /run/ostree-pending ]]; then
      printf '{"deployments":[{"booted":false,"staged":true}]}\n'
    else
      printf '{"deployments":[{"booted":true,"staged":false}]}\n'
    fi
    ;;
esac
MOCK
chmod +x "$mock/rpm-ostree"

out=$(podman run --rm -v "$repo:/repo:ro,Z" -v "$mock:/mock:ro,Z" fedora:latest \
  bash -c 'touch /run/ostree-booted; PATH=/mock:$PATH bash /repo/fedora-system-maintenance.sh -y; echo ===LOG===; cat /tmp/rpm-ostree.log' 2>&1)

grep -q '^rpm-ostree upgrade$' <<<"$out"
grep -q '^rpm-ostree cleanup -b$' <<<"$out"
if grep -q 'cleanup -p' <<<"$out"; then
  echo "cleanup -p would remove the staged deployment" >&2
  exit 1
fi
grep -q 'rpm-ostree upgrade check' <<<"$out"
grep -q 'Reboot required to boot the new image' <<<"$out"

echo "ok atomic runtime"
