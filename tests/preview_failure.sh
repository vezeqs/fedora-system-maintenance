#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
mock=$(mktemp -d); trap 'rm -rf "$mock"' EXIT
cat > "$mock/dnf5" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  *--version*) echo "dnf5 version 5.4.3.0"; exit 0 ;;
  *makecache*) exit 0 ;;
  *check-upgrade*) echo "failed to download metadata" >&2; exit 1 ;;
  *repoquery*) exit 0 ;;
esac
exit 0
MOCK
chmod +x "$mock/dnf5"
out=$(printf 'n\n' | script -qec "podman run --rm -it -v $repo:/repo:ro,Z -v $mock:/mock:ro,Z fedora:latest bash -c 'PATH=/mock:\$PATH bash /repo/fedora-system-maintenance.sh'" /dev/null 2>&1)
grep -q 'Could not check for updates' <<<"$out"
if grep -q 'Packages to upgrade: .*0' <<<"$out"; then echo "failed preview reported as zero" >&2; exit 1; fi
echo "ok preview failure is reported"
