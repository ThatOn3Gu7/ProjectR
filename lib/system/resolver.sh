#!/usr/bin/env bash
# shellcheck disable=all
# Shared manager discovery / resolution helpers.

projectr_resolver_command_exists() {
  if declare -f projectr_command_exists >/dev/null 2>&1; then
    projectr_command_exists "$1"
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

projectr_manager_tier() {
  case "$1" in
  apt | apt-get | pacman | dnf | yum | zypper | apk | emerge | xbps | nix | guix | brew | macports | bsd-pkg | pkg_add | pkg | winget | choco | scoop) printf '1\n' ;;
  flatpak | snap | pipx) printf '2\n' ;;
  cargo | npm | yarn | pnpm | bun | pip | pip3 | gem | go | composer) printf '3\n' ;;
  *) printf '4\n' ;;
  esac
}

projectr_candidate_managers() {
  local -a items=()
  local m
  detect_pkg_manager >/dev/null 2>&1 || true
  for m in "${DETECTED_PKG_MANAGERS[@]:-}"; do
    [[ -n "$m" && "$m" != "unknown" ]] || continue
    case " ${items[*]} " in *" $m "*) ;; *) items+=("$m") ;; esac
  done
  for m in pipx pip3 pip npm yarn pnpm bun gem cargo go composer; do
    projectr_resolver_command_exists "$m" || continue
    case " ${items[*]} " in *" $m "*) ;; *) items+=("$m") ;; esac
  done
  printf '%s\n' "${items[@]}"
}

projectr_manager_availability_check() {
  local pkg="$1" mgr="$2"
  local timeout_cmd=()
  command -v timeout >/dev/null 2>&1 && timeout_cmd=(timeout 8)

  case "$mgr" in
  apt | apt-get) "${timeout_cmd[@]}" apt-cache show "$pkg" >/dev/null 2>&1 ;;
  pacman) "${timeout_cmd[@]}" pacman -Ss "^${pkg}$" >/dev/null 2>&1 ;;
  dnf | yum) "${timeout_cmd[@]}" "$mgr" info "$pkg" >/dev/null 2>&1 ;;
  zypper) "${timeout_cmd[@]}" zypper --non-interactive info "$pkg" >/dev/null 2>&1 ;;
  apk) "${timeout_cmd[@]}" apk search -e "$pkg" >/dev/null 2>&1 ;;
  brew) "${timeout_cmd[@]}" brew info "$pkg" >/dev/null 2>&1 ;;
  macports) "${timeout_cmd[@]}" port info "$pkg" >/dev/null 2>&1 ;;
  xbps) "${timeout_cmd[@]}" xbps-query -Rs "^${pkg}$" >/dev/null 2>&1 ;;
  nix) "${timeout_cmd[@]}" nix-env -qa "$pkg" >/dev/null 2>&1 ;;
  guix) "${timeout_cmd[@]}" guix package --show="$pkg" >/dev/null 2>&1 ;;
  eopkg) "${timeout_cmd[@]}" eopkg info "$pkg" >/dev/null 2>&1 ;;
  urpmi) "${timeout_cmd[@]}" urpmq "$pkg" >/dev/null 2>&1 ;;
  slackpkg) "${timeout_cmd[@]}" slackpkg search "$pkg" >/dev/null 2>&1 ;;
  bsd-pkg) "${timeout_cmd[@]}" pkg search -q "$pkg" >/dev/null 2>&1 ;;
  pkg_add) "${timeout_cmd[@]}" pkg_info -Q "$pkg" >/dev/null 2>&1 ;;
  flatpak) "${timeout_cmd[@]}" flatpak search "$pkg" >/dev/null 2>&1 ;;
  snap) "${timeout_cmd[@]}" snap find "$pkg" >/dev/null 2>&1 ;;
  pkg) "${timeout_cmd[@]}" pkg show "$pkg" >/dev/null 2>&1 ;;
  winget) "${timeout_cmd[@]}" winget search --id "$pkg" >/dev/null 2>&1 ;;
  choco) "${timeout_cmd[@]}" choco search --exact "$pkg" >/dev/null 2>&1 ;;
  scoop) "${timeout_cmd[@]}" scoop search "$pkg" >/dev/null 2>&1 ;;
  npm) "${timeout_cmd[@]}" npm info "$pkg" >/dev/null 2>&1 ;;
  yarn) "${timeout_cmd[@]}" yarn info "$pkg" >/dev/null 2>&1 ;;
  pnpm) "${timeout_cmd[@]}" pnpm view "$pkg" version >/dev/null 2>&1 ;;
  bun) "${timeout_cmd[@]}" bun pm view "$pkg" version >/dev/null 2>&1 ;;
  pip | pip3) "${timeout_cmd[@]}" "$mgr" index versions "$pkg" >/dev/null 2>&1 || "${timeout_cmd[@]}" "$mgr" install --dry-run "$pkg" >/dev/null 2>&1 ;;
  pipx) command -v pip >/dev/null 2>&1 && ("${timeout_cmd[@]}" pip index versions "$pkg" >/dev/null 2>&1 || "${timeout_cmd[@]}" pip install --dry-run "$pkg" >/dev/null 2>&1) ;;
  gem) "${timeout_cmd[@]}" gem list -r "^${pkg}$" >/dev/null 2>&1 ;;
  cargo) "${timeout_cmd[@]}" cargo search --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg " ;;
  go) return 0 ;;
  composer) "${timeout_cmd[@]}" composer show "$pkg" >/dev/null 2>&1 ;;
  *) return 1 ;;
  esac
}
