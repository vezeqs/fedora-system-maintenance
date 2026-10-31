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

Findings: 5 (3 fixed, 2 suspected).

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
**Status:** fixed, test `tests/atomic.sh`. Not run against a live ostree host;
the evidence is upstream documentation and issue #1990.

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

## F4 — Atomic reboot check greps "pending" anywhere (Low, suspected)

**Evidence:** code inspection: `rpm-ostree status | grep -qi 'pending'` matches
any line containing the word, not just the pending deployment.
**Status:** suspected. No ostree host was available to reproduce a false
positive, so it was left unchanged.

## F5 — Atomic preview counts indented lines, not packages (Low, suspected)

**Evidence:** code inspection: `grep -c '^  '` counts indented lines in
`rpm-ostree upgrade --check` output, which is not a package count.
**Status:** suspected. No ostree host was available, so it was left unchanged.
