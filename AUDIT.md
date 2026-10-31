# Audit — 2026-10-30

Scope: `fedora-system-maintenance.sh`, `README.md`, `assets/`, plus the tests and
CI added by this audit.

Baseline before changes:

```console
$ bash -n fedora-system-maintenance.sh
(no output, pass)
$ shellcheck -x -S warning fedora-system-maintenance.sh
(no output, rc=0)
$ make check
make: *** No rule to make target 'check'.  Stop.
```

History read: `f4ec422` clarify the tested transaction, `3400dbd` initial
release. Pull requests: none. There is no `origin` remote, so `gh pr list` has
nothing to read.

Findings: 6 (6 fixed).

## F1 — Atomic cleanup removes the upgrade it just staged (Blocker)

**Claim:** the rpm-ostree path upgrades the image and leaves it pending for the
next boot.
**Evidence:** the upstream `rpm-ostree` documentation says `cleanup -p`
"causes the pending deployment to be removed". coreos/rpm-ostree#1990 says
"cleanup --pending removes any staged deployment that will take effect on the
next reboot". The script ran `rpm-ostree upgrade` and then
`rpm-ostree cleanup -p`.
**Cause:** cleanup ran after the upgrade, so the new pending deployment was the
one it removed.
**Fix:** `rpm-ostree cleanup -b` clears temporary files and leaves deployments
alone. `tests/atomic.sh` fails if `cleanup -p` comes back.
**Status:** fixed, tests `tests/atomic.sh` and `tests/atomic_runtime.sh`. The
runtime test uses a mock `rpm-ostree` that stages a deployment; it is not a live
ostree host, but it proves the script's call order.

## F2 — No tests, CI or Makefile (Medium)

**Claim:** the README says the script is tested on Fedora 44.
**Evidence:** `ls Makefile tests` returned nothing; `make check` failed with
"No rule to make target 'check'".
**Cause:** the repository shipped with screenshots but no executable checks.
**Fix:** `Makefile`, `tests/smoke.sh`, `tests/static.sh`, `tests/atomic.sh`,
`tests/assets.sh` and `.github/workflows/checks.yml`.
**Status:** fixed, `make check` passes.

## F3 — README had no way to verify its claims (Low)

**Evidence:** the README had no "verify it yourself" section and no limits
section, so every claim rested on the screenshots.
**Fix:** added both sections, including the exact container command.
**Status:** fixed, test `tests/docs.sh`.

## F4 — Atomic reboot check greps "pending" anywhere (Low)

**Evidence:** code inspection: `rpm-ostree status | grep -qi 'pending'` matched
any line containing the word, not just the staged deployment. The machine-
readable field is `deployments[].staged` in `rpm-ostree status --json`.
**Fix:** check `"staged": true` in the JSON. `tests/atomic_runtime.sh` runs a
mock `rpm-ostree status --json` that reports a staged deployment and asserts the
reboot warning.
**Status:** fixed, test `tests/atomic_runtime.sh`.

## F5 — Atomic preview counted indented lines, not packages (Low)

**Evidence:** code inspection: `grep -c '^  '` counted indented lines in
`rpm-ostree upgrade --check` output, which is not a package count.
**Fix:** the preview prints the real check output instead of inventing a count.
`tests/atomic_runtime.sh` asserts the raw line is shown.
**Status:** fixed, test `tests/atomic_runtime.sh`.

## F6 — A failed update check is reported as zero (High)

**Claim:** the preview shows how many packages would be upgraded.
**Evidence:** with a mock `dnf5` whose `check-upgrade` exits 1 and prints
"failed to download metadata", the script printed "Packages to upgrade: 0".
The same `|| true` also masks dnf's exit 100, which is the "updates available"
code.
**Cause:** `preview=$(... || true)` discarded the exit status.
**Fix:** capture the status; 0 and 100 are valid, anything else warns that the
check failed. The upgrade still runs.
**Status:** fixed, test `tests/preview_failure.sh`.

## Post-audit verification

- `tests/atomic_runtime.sh` passes: the mock `rpm-ostree` logs `upgrade` then
  `cleanup -b`, `status --json` reports `"staged": true`, and the script warns
  that a reboot is needed. No `cleanup -p` call.
- F4 and F5 are covered by the same test: the JSON check replaced the free-text
  grep, and the preview prints the real check output instead of a line count.
