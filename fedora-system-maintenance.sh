#!/usr/bin/env bash
#
# FOR FEDORA / FEDORA-BASED SYSTEMS!!
# System Maintenance - codefactory
#

set -euo pipefail

ASSUME_YES=0
DRY_RUN=0

#color
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; NC=$'\033[0m'; BLUE=$'\033[0;34m'
  YELLOW=$'\033[1;33m'; PURPLE=$'\033[0;35m'; PINK=$'\033[38;5;213m';
  GREEN=$'\033[0;32m'
else
  RED=''; NC=''; BLUE=''; YELLOW=''; PURPLE=''; PINK=''; GREEN='';
fi

#message
info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" >&2; }
ok() { printf "${PURPLE}[OK]${NC} %s\n" "$*"; }
yay() { printf "${PINK}[SYS]${NC} %s\n" "$*"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }

#options
usage() {
  printf 'Usage: sudo %s [-y|--yes] [-n|--dry-run] [-h|--help]\n' "$0"
  printf '  -y, --yes      skip the confirmation prompt (unattended runs)\n'
  printf '  -n, --dry-run  print every command without running it\n'
  printf '  -h, --help     show this help\n'
}

while (( $# )); do
  case "$1" in
    -y|--yes) ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

#run a command, or print it in dry-run mode
run() {
  if (( DRY_RUN )); then
    printf '%s[DRY-RUN]%s %s\n' "$YELLOW" "$NC" "$*"
    return 0
  fi
  "$@"
}

#runs checks
if [[ $EUID -ne 0 ]]; then
  error "Please run as root: sudo $0"
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in
    *fedora*|*rhel*|*centos*) ;;
    *) warn "This does not look like Fedora (ID=${ID:-unknown}), continuing anyway" ;;
  esac
fi

PM=""
if command -v dnf5 >/dev/null 2>&1; then
  PM=dnf5
elif command -v dnf >/dev/null 2>&1; then
  PM=dnf
else
  error "dnf not found. This script is for Fedora-based operating systems"
  exit 1
fi

#banner
printf '%s\n' "${YELLOW}-------- SYSTEM MAINTENANCE --------${NC}"
info "==> Made by ${RED}codefactory${NC}"
info "==> Please check more of my scripts and code in https://github.com/vezeqs"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"
printf '%s\n' "${YELLOW}------------------------------------${NC}"

#Reports errors
trap 'error "Aborted (status $?): $BASH_COMMAND"' ERR

info "[$(date -Is)] starting maintenance"
info "==> Package manager: ${PURPLE}$PM${NC} ($($PM --version 2>/dev/null | head -1))"

#Fedora Atomic (Silverblue, Kinoite, Bazzite, Bluefin) cannot use dnf on the base
if command -v rpm-ostree >/dev/null 2>&1 && [[ -e /run/ostree-booted ]]; then
  warn "==> rpm-ostree system detected, using the image-based path"
  if command -v rpm-ostree >/dev/null 2>&1 && rpm-ostree upgrade --check >/dev/null 2>&1; then
    preview=$(rpm-ostree upgrade --check 2>&1 || true)
    info "==> $(grep -c '^  ' <<<"$preview" || true) package(s) in the next image"
  else
    info "==> Upgrade check is unavailable on this rpm-ostree version"
  fi

  if (( ASSUME_YES )); then
    info "==> Running unattended (--yes)"
  else
    if [[ ! -t 0 ]]; then
      error "==> No terminal to confirm on, re-run with --yes for unattended use"
      exit 1
    fi
    printf '%s' "${YELLOW}==> Deploy the next image? [y/N] ${NC}"
    read -r reply || reply=""
    case "$reply" in
      y|Y|yes|YES) ;;
      *) info "==> Aborted, nothing was changed."; exit 0 ;;
    esac
  fi

  info "==> Upgrading the image"
  run rpm-ostree upgrade

  info "==> Clearing temporary files"
  run rpm-ostree cleanup -b

  if command -v flatpak >/dev/null 2>&1; then
    info "==> Updating Flatpak apps"
    run flatpak update -y
  fi

  if rpm-ostree status 2>/dev/null | grep -qi 'pending'; then
    warn "==> Reboot required to boot the new image."
  else
    ok "==> No reboot required."
  fi

  success "Maintenance completed with no errors."
  printf '%s\n' "${YELLOW}------------------------------------${NC}"
  info "==> System update is over."
  info "==> Find more scripts in ${PINK}https://github.com/vezeqs${NC}"
  yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"
  exit 0
fi

info "==> Grabbing the new package lists"
for attempt in 1 2 3; do
  if run "$PM" -y makecache; then break; fi
  if (( attempt < 3 )); then
    warn "==> $PM makecache failed, retrying in 5s (attempt $attempt/3)"
    sleep 5
  else
    error "==> $PM makecache failed 3 times, giving up"
    exit 1
  fi
done

info "==> Checking what would change"
if (( DRY_RUN )); then
  info "==> Dry run, skipping the preview query"
else
  if [[ $PM == dnf5 ]]; then
    preview=$("$PM" -q check-upgrade 2>/dev/null || true)
  else
    preview=$("$PM" -q check-update 2>/dev/null || true)
  fi
  upgrades=$(grep -cE '^[[:alnum:]_.+-]+[[:space:]]' <<<"$preview" || true)
  info "==> Packages to upgrade: ${PURPLE}${upgrades}${NC}"
  if (( upgrades > 0 )); then
    printf '%s\n' "$preview" | awk 'NF{print "    " $1}' | head -10
    if (( upgrades > 10 )); then
      info "==> ... and $((upgrades - 10)) more"
    fi
  fi

  unneeded=$("$PM" repoquery --unneeded --qf '%{name}\n' 2>/dev/null | sort -u || true)
  if [[ -n $unneeded ]]; then
    warn "==> Unused packages to remove: $(tr '\n' ' ' <<<"$unneeded")"
  fi
fi

if (( ASSUME_YES )); then
  info "==> Running unattended (--yes)"
else
  if [[ ! -t 0 ]]; then
    error "==> No terminal to confirm on, re-run with --yes for unattended use"
    exit 1
  fi
  printf '%s' "${YELLOW}==> Proceed with these changes? [y/N] ${NC}"
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) info "==> Aborted, nothing was changed."; exit 0 ;;
  esac
fi

#the updating part
info "==> Repairing version mismatches"
run "$PM" -y distro-sync

info "==> Upgrading the system"
run "$PM" -y upgrade

info "==> Removing unused packages"
run "$PM" -y autoremove

info "==> Taking out cache from the packages"
run "$PM" -y clean all

if (( DRY_RUN )); then
  info "==> Dry run, skipping the reboot check"
elif command -v needs-restarting >/dev/null 2>&1; then
  if needs-restarting -r >/dev/null 2>&1; then
    ok "==> No reboot required."
  else
    warn "==> Reboot required."
  fi
else
  running=$(uname -r)
  latest=$(rpm -q --last kernel 2>/dev/null | head -1 | awk '{print $1}' | sed 's/^kernel-//' || true)
  if [[ $latest =~ ^[0-9] && $running != "$latest" ]]; then
    warn "==> Reboot required: running $running, installed $latest"
  else
    ok "==> No reboot required."
  fi
fi

success "Maintenance completed with no errors."

printf '%s\n' "${YELLOW}------------------------------------${NC}"

info "==> System update is over."
info "==> Find more scripts in ${PINK}https://github.com/vezeqs${NC}"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"
