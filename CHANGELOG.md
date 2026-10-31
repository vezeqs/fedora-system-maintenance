# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-10-30

### Fixed
- The atomic path ran `rpm-ostree cleanup -p` after `rpm-ostree upgrade`. `-p`
  removes the pending deployment, which is the upgrade that was just staged, so
  the script undid its own work. It now runs `rpm-ostree cleanup -b`, which
  clears temporary files and leaves the deployment alone.

### Added
- `Makefile`, `tests/` and a GitHub Actions check workflow.
- `tests/atomic.sh` fails if `cleanup -p` comes back.
- README sections for verification and limits.

## [0.1.0] - 2026-10-30

### Added
- Initial release for Fedora and Fedora-based systems.
- Supports both dnf5 and dnf4, picked at runtime.
- Preview of upgrades and unused packages before the confirmation prompt.
- Repair step using `dnf distro-sync`, then `dnf upgrade`.
- `autoremove` and `clean all` after the upgrade.
- Reboot detection with `needs-restarting -r`, falling back to a kernel version comparison.
- Fedora Atomic path: `rpm-ostree upgrade`, `rpm-ostree cleanup -p`, and Flatpak updates when `/run/ostree-booted` is present.
- `-y/--yes`, `-n/--dry-run` and `-h/--help`.
