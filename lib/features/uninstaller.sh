#!/usr/bin/env bash
# shellcheck disable=all

projectr_effective_uninstall_manager() {
  local tool_id="$1" package="$2"
  if [[ -n "${PROJECTR_UNINSTALL_MANAGER_OVERRIDE:-}" ]]; then
    printf '%s\n' "$PROJECTR_UNINSTALL_MANAGER_OVERRIDE"
    return 0
  fi
  if declare -f projectr_state_lookup_manager >/dev/null 2>&1; then
    local recorded
    recorded=$(projectr_state_lookup_manager "$tool_id" "$package")
    [[ -n "$recorded" ]] && {
      printf '%s\n' "$recorded"
      return 0
    }
  fi
  printf '%s\n' "${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
}

projectr_uninstall_tool_by_fields() {
  local cmd="$1" pkg="$2" name="$3" type="$4" extra="${5:--}"

  case "$type" in
  pkg)
    uninstall_pkg "$cmd" "$pkg" "$name"
    ;;
  special)
    local special_uninstaller=""
    if declare -p PROJECTR_SPECIAL_UNINSTALLERS >/dev/null 2>&1; then
      special_uninstaller="${PROJECTR_SPECIAL_UNINSTALLERS[$extra]:-}"
    fi

    if [[ -n "$special_uninstaller" ]] && declare -f "$special_uninstaller" >/dev/null 2>&1; then
      "$special_uninstaller" "$cmd" "$pkg" "$name"
    else
      uninstall_pkg "$cmd" "$pkg" "$name"
    fi
    ;;
  pip | pip3 | pipx | cargo | gem | npm | yarn | pnpm | bun | go | composer)
    uninstall_lang "$type" "$pkg" "$name" "$cmd"
    ;;
  *)
    echo -e "${ERROR} [!] Unsupported tool type for uninstallation: ${type}${RST}"
    log_fail "Unsupported tool type '$type' for uninstall of $name" "uninstall"
    return 1
    ;;
  esac
}

projectr_run_uninstall_command() {
  local component="$1" action="$2"
  shift 2
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo -e "${INFO:-}   [DRY-RUN] Would execute: $* ${RST:-}"
    return 0
  fi
  if declare -f projectr_run_logged >/dev/null 2>&1; then
    projectr_run_logged "$component" "$action" "$@"
  else
    "$@" >/dev/null 2>&1
  fi
}

uninstall_lang() {
  local pm="$1"
  local pkg="$2"
  local name="$3"
  local cmd="${4:-$pkg}"
  local tool_id effective_cmd
  tool_id=$(projectr_tool_id "$cmd")
  effective_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$pm")
  pkg=$(projectr_effective_package "$tool_id" "$pkg" "$pm")

  if [[ -z "$pm" || -z "$pkg" || -z "$name" ]]; then
    echo -e "${ERROR}  [!] uninstall_lang: Missing required arguments.${RST}"
    log_error "uninstall_lang missing arguments pm='$pm' pkg='$pkg' name='$name'" "uninstall-lang"
    return 1
  fi

  if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    if ! ask_confirm "Remove \"$name\"? (can be reinstalled later)" "n" "Remove" "Keep" "danger" "20" "center"; then
      echo -e "${INFO}  [→] Skipping: $name.${RST}"
      log_info "User skipped uninstall for $name" "uninstall"
      return 0
    fi
  fi

  if ! command -v "$effective_cmd" >/dev/null 2>&1; then
    echo -e "${ERROR}  [!] Package $name was not found via $pm.${RST}"
    log_warn "$name not found on PATH before language uninstall (cmd=$effective_cmd pm=$pm pkg=$pkg)" "uninstall-lang"
    sleep 1
    return 1
  fi

  start_spinner "   [*] Removing $name via $pm..."

  case "$pm" in
  npm) projectr_run_uninstall_command "uninstall-lang" "remove $name via npm" npm uninstall -g "$pkg" ;;
  yarn) projectr_run_uninstall_command "uninstall-lang" "remove $name via yarn" yarn global remove "$pkg" ;;
  pnpm) projectr_run_uninstall_command "uninstall-lang" "remove $name via pnpm" pnpm remove -g "$pkg" ;;
  bun) projectr_run_uninstall_command "uninstall-lang" "remove $name via bun" bun remove -g "$pkg" ;;
  pip | pip3 | pipx) projectr_run_uninstall_command "uninstall-lang" "remove $name via $pm" "$pm" uninstall -y "$pkg" ;;
  gem) projectr_run_uninstall_command "uninstall-lang" "remove $name via gem" gem uninstall "$pkg" -x ;;
  cargo) projectr_run_uninstall_command "uninstall-lang" "remove $name via cargo" cargo uninstall "$pkg" ;;
  go) projectr_run_uninstall_command "uninstall-lang" "remove $name via go" bash -lc 'go clean -i "$1" 2>/dev/null || true; rm -f "$(go env GOPATH 2>/dev/null)/bin/$2"' _ "$pkg" "$effective_cmd" ;;
  composer) projectr_run_uninstall_command "uninstall-lang" "remove $name via composer" composer global remove "$pkg" ;;
  *)
    stop_spinner
    echo -e "${ERROR} [!] Unsupported language package manager: $pm.${RST}"
    log_fail "Unsupported language package manager '$pm' while removing $name" "uninstall-lang"
    return 1
    ;;
  esac

  local exit_code=$?

  if command -v "$effective_cmd" >/dev/null 2>&1; then
    stop_spinner "${ERROR}  [!] $name remains present after the removal process. Manual cleanup may be required.${RST}"
    log FAIL "$name (lang): binary still present after $pm removal"
    return 1
  fi

  if [[ $exit_code -eq 0 ]]; then
    stop_spinner "${OPTION}  [✓] $name has been successfully removed via $pm.${RST}"
    log OK "$name removed successfully via $pm"
    declare -f projectr_state_remove_install >/dev/null 2>&1 && projectr_state_remove_install "$tool_id" "$name" "$pkg" || true
    declare -f projectr_state_record_action >/dev/null 2>&1 && projectr_state_record_action "$tool_id" "$name" "$pkg" "$pm" "$pm" "$effective_cmd" removed || true
  else
    stop_spinner "${ERROR}  [!] $name removal completed with errors (exit code: $exit_code).${RST}"
    log FAIL "$name uninstall exited $exit_code on $pm"
    return 1
  fi
}

uninstall_pkg() {
  local cmd="$1"
  local pkg="$2"
  local name="$3"
  local tool_id PM effective_cmd effective_pkg
  tool_id=$(projectr_tool_id "$cmd")
  PM=$(projectr_effective_uninstall_manager "$tool_id" "$pkg")
  effective_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$PM")
  effective_pkg=$(projectr_effective_package "$tool_id" "$pkg" "$PM")

  if [[ -z "$cmd" || -z "$pkg" || -z "$name" ]]; then
    echo -e "${ERROR}  [!] uninstall_pkg: Missing required arguments.${RST}"
    log_error "uninstall_pkg missing arguments cmd='$cmd' pkg='$pkg' name='$name'" "uninstall-pkg"
    return 1
  fi
  if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    if ! ask_confirm "Remove \"$name\"? (can be reinstalled later)" "n" "Remove" "Keep" "danger" "20" "center"; then
      echo -e "${INFO}  [→] Skipping uninstallation of $name.${RST}"
      log_info "User skipped uninstall for $name" "uninstall"
      return 0
    fi
  fi

  if ! command -v "$effective_cmd" >/dev/null 2>&1; then
    echo -e "${ERROR}  [!] Package $name was not found on $PM.${RST}"
    log_warn "$name not found on PATH before package uninstall (cmd=$effective_cmd pm=$PM pkg=$effective_pkg)" "uninstall-pkg"
    sleep 1
    return 1
  fi

  start_spinner "   [*] Removing package $name via $PM..."

  case "$PM" in
  pkg) projectr_run_uninstall_command "uninstall-pkg" "remove $name via pkg" pkg uninstall -y "$effective_pkg" ;;
  apt | apt-get) projectr_run_uninstall_command "uninstall-pkg" "purge $name via apt-get" projectr_run_privileged "$PM" apt-get purge -y "$effective_pkg" ;;
  pacman) projectr_run_uninstall_command "uninstall-pkg" "remove $name via pacman" projectr_run_privileged "$PM" pacman -Rns --noconfirm "$effective_pkg" ;;
  dnf) projectr_run_uninstall_command "uninstall-pkg" "remove $name via dnf" projectr_run_privileged "$PM" dnf remove -y "$effective_pkg" ;;
  yum) projectr_run_uninstall_command "uninstall-pkg" "remove $name via yum" projectr_run_privileged "$PM" yum remove -y "$effective_pkg" ;;
  zypper) projectr_run_uninstall_command "uninstall-pkg" "remove $name via zypper" projectr_run_privileged "$PM" zypper remove -y "$effective_pkg" ;;
  apk) projectr_run_uninstall_command "uninstall-pkg" "remove $name via apk" projectr_run_privileged "$PM" apk del "$effective_pkg" ;;
  emerge) projectr_run_uninstall_command "uninstall-pkg" "remove $name via emerge" projectr_run_privileged "$PM" emerge --unmerge "$effective_pkg" ;;
  xbps) projectr_run_uninstall_command "uninstall-pkg" "remove $name via xbps" projectr_run_privileged "$PM" xbps-remove -R "$effective_pkg" ;;
  nix) projectr_run_uninstall_command "uninstall-pkg" "remove $name via nix" nix-env --uninstall "$effective_pkg" ;;
  guix) projectr_run_uninstall_command "uninstall-pkg" "remove $name via guix" guix package --remove="$effective_pkg" ;;
  eopkg) projectr_run_uninstall_command "uninstall-pkg" "remove $name via eopkg" projectr_run_privileged "$PM" eopkg remove "$effective_pkg" ;;
  urpmi) projectr_run_uninstall_command "uninstall-pkg" "remove $name via urpmi" projectr_run_privileged "$PM" urpme "$effective_pkg" ;;
  slackpkg) projectr_run_uninstall_command "uninstall-pkg" "remove $name via slackpkg" projectr_run_privileged "$PM" slackpkg remove "$effective_pkg" ;;
  brew) projectr_run_uninstall_command "uninstall-pkg" "remove $name via brew" brew uninstall --force "$effective_pkg" ;;
  macports) projectr_run_uninstall_command "uninstall-pkg" "remove $name via macports" projectr_run_privileged "$PM" port uninstall "$effective_pkg" ;;
  bsd-pkg) projectr_run_uninstall_command "uninstall-pkg" "remove $name via FreeBSD pkg" projectr_run_privileged "$PM" pkg delete -y "$effective_pkg" ;;
  pkg_add) projectr_run_uninstall_command "uninstall-pkg" "remove $name via pkg_delete" projectr_run_privileged "$PM" pkg_delete "$effective_pkg" ;;
  winget) projectr_run_uninstall_command "uninstall-pkg" "remove $name via winget" winget uninstall --silent --accept-package-agreements "$effective_pkg" ;;
  choco) projectr_run_uninstall_command "uninstall-pkg" "remove $name via choco" choco uninstall -y "$effective_pkg" ;;
  scoop) projectr_run_uninstall_command "uninstall-pkg" "remove $name via scoop" scoop uninstall "$effective_pkg" ;;
  flatpak) projectr_run_uninstall_command "uninstall-pkg" "remove $name via flatpak" flatpak uninstall -y "$effective_pkg" ;;
  snap) projectr_run_uninstall_command "uninstall-pkg" "remove $name via snap" projectr_run_privileged "$PM" snap remove "$effective_pkg" ;;
  *)
    stop_spinner
    echo -e "${ERROR} [!] Unsupported package manager: $PM.${RST}"
    log_fail "Unsupported package manager '$PM' while removing $name" "uninstall-pkg"
    return 1
    ;;
  esac

  local exit_code=$?

  if command -v "$effective_cmd" >/dev/null 2>&1; then
    stop_spinner "${ERROR}  [!] $name remains present after the removal process. Manual cleanup may be required.${RST}"
    log FAIL "$name: binary still present after $PM removal"
    return 1
  fi

  if [[ $exit_code -eq 0 ]]; then
    stop_spinner "${OPTION}  [✓] $name has been successfully removed via $PM.${RST}"
    log OK "$name removed successfully via $PM"
    declare -f projectr_state_remove_install >/dev/null 2>&1 && projectr_state_remove_install "$tool_id" "$name" "$effective_pkg" || true
    declare -f projectr_state_record_action >/dev/null 2>&1 && projectr_state_record_action "$tool_id" "$name" "$effective_pkg" "$PM" pkg "$effective_cmd" removed || true
  else
    stop_spinner "${ERROR}  [!] $name removal completed with errors (exit code: $exit_code).${RST}"
    log FAIL "$name uninstall exited $exit_code on $PM"
    return 1
  fi
}
