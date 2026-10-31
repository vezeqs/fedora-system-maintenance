# AGENTS.md

Fedora System Maintenance is a single bash script that updates, repairs and
cleans Fedora, including an rpm-ostree path for Silverblue, Kinoite, Bazzite and
Bluefin. It prints a preview and changes nothing until the user answers `y`.
There is no build step and no dependency beyond bash and dnf.

## Entry points

| Question | File |
| --- | --- |
| The maintenance script | `fedora-system-maintenance.sh` |
| Atomic-path regression test | `tests/atomic.sh` |
| Checks | `make check` |
| Screenshots | `assets/preview.png`, `assets/upgrade.png` |

## Invariants

- Nothing mutating runs before the `[y/N]` prompt returns `y`.
- `--dry-run` prints every mutating command and executes none.
- The atomic path never removes the pending deployment it just created.
- The script exits non-zero when a step fails and names the failing command.
- Without `-y`, the script refuses to run when stdin is not a terminal.
- The preview queries are read-only.

## Commands

```bash
make check    # bash -n, shellcheck, smoke tests, atomic test, assets
make lint     # bash -n + shellcheck
make test     # smoke and regression tests
```

The real proof is a container run:

```bash
podman run --rm -v "$PWD:/repo:ro,Z" fedora:latest \
  bash /repo/fedora-system-maintenance.sh --dry-run
```

## Sharp edges

- `rpm-ostree cleanup -p` removes the pending deployment, which is the upgrade
  that was just staged. It is deliberately not used; `cleanup -b` clears temp
  files and leaves deployments alone.
- `dnf distro-sync` can downgrade packages from third-party repositories. That
  is the repair step, and the README says so.
- dnf5 uses `check-upgrade`; dnf4 uses `check-update`. The script picks one at
  runtime and must keep both paths.
- The test container has no kernel package, so the reboot fallback is what runs
  there. `needs-restarting -r` is the real path on a full Fedora install.
- The atomic path is covered by `tests/atomic_runtime.sh` with a mock
  `rpm-ostree`, not a live ostree host.

## Definition of done

- [ ] `make check` passes.
- [ ] The change has a test in `tests/` that fails without it.
- [ ] `README.md` still matches behaviour.
- [ ] `CHANGELOG.md` has an entry for user-visible changes.
- [ ] No secrets, no `rm -rf`, no new dependency.

## Do not touch

- `LICENSE`.
- `assets/*.png` by hand; they are captures of a real run.
- Formatting of unrelated files.
