#!/bin/bash
# shellcheck disable=all

projectr_record_successful_install() {
  local tool_id="$1" display_name="$2" package="$3" manager="$4" install_type="$5" check_cmd="$6"
  mkdir -p "$SCRIPT_DIR/log/"
  echo "$(date '+%F %T')|$check_cmd|$package|$manager" >>"$SCRIPT_DIR/log/session_history.tmp" 2>/dev/null || true
  declare -f projectr_state_record_install >/dev/null 2>&1 &&
    projectr_state_record_install "$tool_id" "$display_name" "$package" "$manager" "$install_type" "$check_cmd" || true
  declare -f projectr_state_record_action >/dev/null 2>&1 &&
    projectr_state_record_action "$tool_id" "$display_name" "$package" "$manager" "$install_type" "$check_cmd" "installed" || true
}

projectr_record_failed_install() {
  local tool_id="$1" display_name="$2" package="$3" manager="$4" install_type="$5" check_cmd="$6"
  declare -f projectr_state_record_action >/dev/null 2>&1 &&
    projectr_state_record_action "$tool_id" "$display_name" "$package" "$manager" "$install_type" "$check_cmd" "failed" || true
}

projectr_install_tool_by_fields() {
  local cmd="$1" pkg="$2" name="$3" type="$4" extra="${5:--}"

  case "$type" in
  pkg)
    install_pkg "$cmd" "$pkg" "$name"
    ;;
  pip | pip3 | pipx | cargo | gem | npm | yarn | pnpm | bun | go | composer)
    install_lang "$type" "$pkg" "$name" "$cmd"
    ;;
  special)
    if declare -f "$extra" >/dev/null 2>&1; then
      "$extra"
    else
      echo -e "${ERROR}  [!] Special installer '${extra}' not found. Skipping ${name}.${RST}"
      log_fail "Special installer '${extra}' not found for $name" "install"
      projectr_install_result_push failed "$name"
      projectr_record_failed_install "$cmd" "$name" "$pkg" special special "$cmd"
      return 1
    fi
    ;;
  *)
    echo -e "${ERROR}  [!] Unsupported tool type '${type}' for ${name}.${RST}"
    log_fail "Unsupported tool type '${type}' for $name" "install"
    projectr_install_result_push failed "$name"
    projectr_record_failed_install "$cmd" "$name" "$pkg" unknown "$type" "$cmd"
    return 1
    ;;
  esac
}

# -- install function --
install_all() {
  echo ""
  echo -e "${ERROR}  [!] Bulk installation of all tools is disabled by default.${RST}"
  echo -e "${INFO}  [*] Please use configuration presets: ${BOLD_WHITE}project install --profile <file>.yml${RST}"
  printf "${DIM}  [press ENTER]${RST}"
  read -s
  echo
  return 1
}

# For profile preset installation
install_preset_by_names() {
  local names=("$@")

  if [[ ${#names[@]} -eq 0 ]]; then
    echo -e "${ERROR}  [!] No tools specified for preset installation.${RST}"
    log_warn "install_preset_by_names called without tools" "preset"
    return 1
  fi

  local -a INSTALLED_PKGS=()
  local -a SKIPPED_PKGS=()
  local -a FAILED_PKGS=()

  declare -f projectr_snapshot_pre_install >/dev/null 2>&1 && projectr_snapshot_pre_install "install_preset"

  for name in "${names[@]}"; do
    local matched=0
    for entry in "${TOOLS[@]}"; do
      IFS="|" read -r num cmd pkg display desc type extra cat <<<"$entry"
      if [[ "$cmd" == "$name" ]]; then
        matched=1
        projectr_install_tool_by_fields "$cmd" "$pkg" "$display" "$type" "$extra"
        break
      fi
    done
    if [[ $matched -eq 0 ]]; then
      echo -e "${BOLD_YELLOW}  [!] Tool '$name' was not found in the tool registry. Skipping...${RST}"
      log_warn "Preset requested unknown tool '$name'" "preset"
    fi
  done

  echo ""
  post_install_summary
}

install_pkg() {
  local cmd="$1"
  local pkg="$2"
  local name="$3"
  local requested_manager="${4:-${PROJECTR_INSTALL_MANAGER_OVERRIDE:-}}"
  local PM="${requested_manager:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}"
  local tool_id effective_pkg effective_cmd
  tool_id=$(projectr_tool_id "$cmd")
  effective_pkg=$(projectr_effective_package "$tool_id" "$pkg" "$PM")
  effective_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$PM")

  if [[ -z "$cmd" || -z "$pkg" || -z "$name" ]]; then
    echo -e "${ERROR}  [!] install_pkg: Missing required arguments (cmd='$cmd', pkg='$pkg', name='$name').${RST}"
    log_error "install_pkg missing argument cmd='$cmd' pkg='$pkg' name='$name'" "install"
    return 1
  fi

  if command -v "$effective_cmd" >/dev/null 2>&1; then
    echo -e "${OPTION}  [✓] $name is already installed. Skipping...${RST}"
    projectr_install_result_push skipped "$name"
    log SKIPPED "$name was already installed (Skipped)"
    sleep 1
    return 0
  fi

  start_spinner "  [*] Installing $name via $PM..."

  case "$PM" in
  apt | apt-get)
    DEBIAN_FRONTEND=noninteractive \
      projectr_run_privileged "$PM" apt-get install -y --no-install-recommends "$effective_pkg" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      stop_spinner "${BOLD_YELLOW}  [!] apt installation failed. Refreshing package cache and retrying...${RST}"
      start_spinner "  [*] Retrying installation of $name..."
      projectr_run_privileged "$PM" apt-get update >/dev/null 2>&1
      DEBIAN_FRONTEND=noninteractive \
        projectr_run_privileged "$PM" apt-get install -y --no-install-recommends "$effective_pkg" >/dev/null 2>&1
    fi
    ;;
  dnf | yum)
    projectr_run_privileged "$PM" "$PM" install -y "$effective_pkg" >/dev/null 2>&1
    ;;
  pacman)
    projectr_run_privileged "$PM" pacman -Sy --noconfirm --needed "$effective_pkg" >/dev/null 2>&1
    ;;
  zypper)
    projectr_run_privileged "$PM" zypper --non-interactive install "$effective_pkg" >/dev/null 2>&1
    ;;
  brew)
    brew install "$effective_pkg" >/dev/null 2>&1
    ;;
  apk)
    projectr_run_privileged "$PM" apk add --no-cache "$effective_pkg" >/dev/null 2>&1
    ;;
  emerge)
    projectr_run_privileged "$PM" emerge -av "$effective_pkg" >/dev/null 2>&1
    ;;
  xbps)
    projectr_run_privileged "$PM" xbps-install -Sy "$effective_pkg" >/dev/null 2>&1
    ;;
  nix)
    nix-env -i "$effective_pkg" >/dev/null 2>&1
    ;;
  guix)
    guix package --install "$effective_pkg" >/dev/null 2>&1
    ;;
  eopkg)
    projectr_run_privileged "$PM" eopkg install -y "$effective_pkg" >/dev/null 2>&1
    ;;
  urpmi)
    projectr_run_privileged "$PM" urpmi --auto "$effective_pkg" >/dev/null 2>&1
    ;;
  slackpkg)
    projectr_run_privileged "$PM" slackpkg install "$effective_pkg" >/dev/null 2>&1
    ;;
  macports)
    projectr_run_privileged "$PM" port install "$effective_pkg" >/dev/null 2>&1
    ;;
  bsd-pkg)
    projectr_run_privileged "$PM" pkg install -y "$effective_pkg" >/dev/null 2>&1
    ;;
  pkg_add)
    projectr_run_privileged "$PM" pkg_add "$effective_pkg" >/dev/null 2>&1
    ;;
  flatpak)
    flatpak install -y flathub "$effective_pkg" >/dev/null 2>&1
    ;;
  snap)
    projectr_run_privileged "$PM" snap install "$effective_pkg" >/dev/null 2>&1
    ;;
  pkg)
    pkg install -y "$effective_pkg" >/dev/null 2>&1
    ;;
  choco | chocolatey)
    choco install -y "$effective_pkg" >/dev/null 2>&1
    ;;
  scoop)
    scoop install "$effective_pkg" >/dev/null 2>&1
    ;;
  winget)
    winget install -e --id "$effective_pkg" >/dev/null 2>&1
    ;;
  *)
    stop_spinner
    echo -e "${ERROR}  [x] Unsupported package manager: $PM.${RST}"
    projectr_install_result_push failed "$name"
    projectr_record_failed_install "$tool_id" "$name" "$effective_pkg" "$PM" pkg "$effective_cmd"
    log FAIL "$name — unsupported PM: $PM"
    return 1
    ;;
  esac

  local install_exit=$?
  if [[ $install_exit -eq 0 ]] && command -v "$effective_cmd" >/dev/null 2>&1; then
    projectr_record_successful_install "$tool_id" "$name" "$effective_pkg" "$PM" pkg "$effective_cmd"
    projectr_install_result_push installed "$name"
    stop_spinner "${OPTION} [✓] $name has been successfully installed via $PM.${RST}"
    log INSTALLED "$name installed successfully (via $PM)"
  else
    projectr_install_result_push failed "$name"
    projectr_record_failed_install "$tool_id" "$name" "$effective_pkg" "$PM" pkg "$effective_cmd"
    stop_spinner "${ERROR} [x] Failed to install $name.${RST}"
    log FAIL "$name failed to install (on $PM)"
    install_exit=${install_exit:-1}
  fi
  sleep 1
  return "$install_exit"
}

# Universal language package installer
install_lang() {
  local tool_type="$1"
  local pkg_name="$2"
  local display_name="${3:-$pkg_name}"
  local cmd="${4:-$pkg_name}"
  local override="${PROJECTR_INSTALL_MANAGER_OVERRIDE:-}"
  local tool_id check_cmd lang_pm
  tool_id=$(projectr_tool_id "$cmd")
  lang_pm=$(detect_pkg_for_tool "$tool_type")
  if [[ -n "$override" ]]; then
    lang_pm="$override"
  fi
  check_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$lang_pm")
  pkg_name=$(projectr_effective_package "$tool_id" "$pkg_name" "$lang_pm")

  if command -v "$check_cmd" >/dev/null 2>&1; then
    echo -e "${OPTION} [✓] $display_name is already installed. Skipping...${RST}"
    projectr_install_result_push skipped "$display_name"
    log SKIPPED "$display_name was already installed"
    sleep 1
    return 0
  fi

  if [[ "$lang_pm" == "none" ]]; then
    echo -e "${ERROR} [✗] No $tool_type package manager detected. Unable to install $display_name.${RST}"
    log_fail "No $tool_type package manager found for $display_name" "install-lang"
    projectr_install_result_push failed "$display_name"
    projectr_record_failed_install "$tool_id" "$display_name" "$pkg_name" none "$tool_type" "$check_cmd"
    return 1
  fi

  local max_attempts=2
  local attempt=1
  local err_tmp
  err_tmp=$(mktemp)
  export install_method="$lang_pm"

  start_spinner "  [*] Installing $display_name via $lang_pm..."

  while ((attempt <= max_attempts)); do
    if ((attempt > 1)); then
      stop_spinner
      echo -e "${BOLD_YELLOW}  [!] Attempt $attempt of $max_attempts failed. Retrying installation of $display_name...${RST}"
      sleep 2
      start_spinner "  [*] Retrying installation of $display_name via $lang_pm..."
    fi

    local install_cmd=()
    case "$lang_pm" in
    pip | pip3 | pipx) install_cmd=("$lang_pm" install --quiet "$pkg_name") ;;
    npm) install_cmd=(npm install -g --quiet "$pkg_name") ;;
    yarn) install_cmd=(yarn global add --silent "$pkg_name") ;;
    pnpm) install_cmd=(pnpm add -g "$pkg_name") ;;
    bun) install_cmd=(bun add -g "$pkg_name") ;;
    gem) install_cmd=(gem install --silent "$pkg_name") ;;
    cargo) install_cmd=(cargo install --quiet "$pkg_name") ;;
    go)
      install_cmd=(go install "$pkg_name@latest")
      ;;
    composer)
      install_cmd=(composer global require "$pkg_name")
      ;;
    *)
      stop_spinner ""
      echo -e "${ERROR}  [✗] Unrecognized language package manager: $lang_pm.${RST}"
      log_fail "Unknown language manager '$lang_pm' for $display_name" "install-lang"
      projectr_install_result_push failed "$display_name"
      projectr_record_failed_install "$tool_id" "$display_name" "$pkg_name" "$lang_pm" "$tool_type" "$check_cmd"
      unset install_method
      rm -f "$err_tmp"
      return 1
      ;;
    esac

    log INFO "START install $display_name package=$pkg_name via $lang_pm attempt=$attempt/$max_attempts" "install-lang"
    "${install_cmd[@]}" >"$err_tmp" 2>&1
    local lang_status=$?
    if [[ $lang_status -eq 0 ]]; then
      log OK "Command completed for $display_name via $lang_pm on attempt $attempt" "install-lang"
      break
    fi
    log FAIL "Command failed for $display_name via $lang_pm on attempt $attempt (exit=$lang_status)" "install-lang"
    projectr_log_file_excerpt FAIL "$err_tmp" "install-lang" 20
    ((attempt++))
  done

  if command -v "$check_cmd" >/dev/null 2>&1; then
    projectr_record_successful_install "$tool_id" "$display_name" "$pkg_name" "$lang_pm" "$tool_type" "$check_cmd"
    projectr_install_result_push installed "$display_name"
    stop_spinner "${OPTION}  [✓] $display_name has been successfully installed via $lang_pm.${RST}"
    log INSTALLED "$display_name installed via $lang_pm"
    unset install_method
    rm -f "$err_tmp"
    sleep 1
    return 0
  else
    local err_msg
    err_msg=$(grep -v '^\s*$' "$err_tmp" 2>/dev/null | tail -n1 | tr -cd '[:print:]')
    projectr_install_result_push failed "$display_name"
    projectr_record_failed_install "$tool_id" "$display_name" "$pkg_name" "$lang_pm" "$tool_type" "$check_cmd"
    stop_spinner "${ERROR}  [✗] Failed to install $display_name${err_msg:+: ${err_msg}}.${RST}"
    log FAIL "$display_name install failed${err_msg:+: $err_msg}"
    unset install_method
    rm -f "$err_tmp"
    sleep 1
    return 1
  fi
}

projectr_batch_command_for_group() {
  local manager="$1"
  shift
  case "$manager" in
  apt | apt-get) DEBIAN_FRONTEND=noninteractive projectr_run_privileged "$manager" apt-get install -y --no-install-recommends "$@" ;;
  pacman) projectr_run_privileged "$manager" pacman -Sy --noconfirm --needed "$@" ;;
  dnf | yum) projectr_run_privileged "$manager" "$manager" install -y "$@" ;;
  zypper) projectr_run_privileged "$manager" zypper --non-interactive install "$@" ;;
  brew) brew install "$@" ;;
  apk) projectr_run_privileged "$manager" apk add --no-cache "$@" ;;
  xbps) projectr_run_privileged "$manager" xbps-install -Sy "$@" ;;
  nix) nix-env -i "$@" ;;
  guix) guix package --install "$@" ;;
  eopkg) projectr_run_privileged "$manager" eopkg install -y "$@" ;;
  urpmi) projectr_run_privileged "$manager" urpmi --auto "$@" ;;
  slackpkg) projectr_run_privileged "$manager" slackpkg install "$@" ;;
  macports) projectr_run_privileged "$manager" port install "$@" ;;
  bsd-pkg) projectr_run_privileged "$manager" pkg install -y "$@" ;;
  pkg_add) projectr_run_privileged "$manager" pkg_add "$@" ;;
  flatpak) flatpak install -y flathub "$@" ;;
  snap) projectr_run_privileged "$manager" snap install "$@" ;;
  pkg) pkg install -y "$@" ;;
  winget) winget install -e --id "$@" ;;
  choco) choco install -y "$@" ;;
  scoop) scoop install "$@" ;;
  pip | pip3 | pipx) "$manager" install --quiet "$@" ;;
  npm) npm install -g --quiet "$@" ;;
  yarn) yarn global add --silent "$@" ;;
  pnpm) pnpm add -g "$@" ;;
  bun) bun add -g "$@" ;;
  gem) gem install --silent "$@" ;;
  cargo) cargo install --quiet "$@" ;;
  go) go install "$@" ;;
  composer) composer global require "$@" ;;
  *) return 2 ;;
  esac
}

projectr_install_batch_by_entries() {
  local -a entries=("$@")
  local -a INSTALLED_PKGS=()
  local -a SKIPPED_PKGS=()
  local -a FAILED_PKGS=()
  local PM="${PROJECTR_INSTALL_MANAGER_OVERRIDE:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}"
  local entry num cmd pkg name desc type extra cat key tool_id effective_pkg effective_cmd
  local -a group_keys=()

  declare -f projectr_snapshot_pre_install >/dev/null 2>&1 && projectr_snapshot_pre_install "batch_install"

  for entry in "${entries[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    tool_id=$(projectr_tool_id "$cmd")
    case "$type" in
    pkg) key="$PM" ;;
    pip | pip3 | pipx | cargo | gem | npm | yarn | pnpm | bun | go | composer) key="${PROJECTR_INSTALL_MANAGER_OVERRIDE:-$(detect_pkg_for_tool "$type")}" ;;
    *)
      projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
      continue
      ;;
    esac
    effective_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$key")
    effective_pkg=$(projectr_effective_package "$tool_id" "$pkg" "$key")
    if command -v "$effective_cmd" >/dev/null 2>&1; then
      projectr_install_result_push skipped "$name"
      continue
    fi
    [[ "$key" != "none" && -n "$key" ]] || {
      projectr_install_result_push failed "$name"
      projectr_record_failed_install "$tool_id" "$name" "$effective_pkg" none "$type" "$effective_cmd"
      continue
    }
    local safe="${key//[^A-Za-z0-9_]/_}"
    eval "projectr_batch_pkgs_${safe}+=(\"\$effective_pkg\")"
    eval "projectr_batch_entries_${safe}+=(\"\$entry\")"
    case " ${group_keys[*]} " in *" $key "*) ;; *) group_keys+=("$key") ;; esac
  done

  local group safe status tmp
  for group in "${group_keys[@]}"; do
    safe=${group//[^A-Za-z0-9_]/_}
    eval 'local -a pkgs=("${projectr_batch_pkgs_'"$safe"'[@]}")'
    eval 'local -a group_entries=("${projectr_batch_entries_'"$safe"'[@]}")'
    [[ ${#pkgs[@]} -gt 0 ]] || continue

    tmp=$(mktemp)
    start_spinner "  [*] Batch installing ${#pkgs[@]} package(s) via $group..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      printf '[DRY-RUN] %s install payload: %s\n' "$group" "${pkgs[*]}" >"$tmp"
      status=0
    else
      projectr_batch_command_for_group "$group" "${pkgs[@]}" >"$tmp" 2>&1
      status=$?
    fi
    if [[ $status -eq 0 ]]; then
      stop_spinner "${OPTION}  [✓] Batch installation of ${#pkgs[@]} package(s) via $group completed successfully.${RST}"
      for entry in "${group_entries[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
        tool_id=$(projectr_tool_id "$cmd")
        effective_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$group")
        effective_pkg=$(projectr_effective_package "$tool_id" "$pkg" "$group")
        if [[ "${DRY_RUN:-0}" == "1" ]] || command -v "$effective_cmd" >/dev/null 2>&1; then
          projectr_install_result_push installed "$name"
          [[ "${DRY_RUN:-0}" == "1" ]] || projectr_record_successful_install "$tool_id" "$name" "$effective_pkg" "$group" "$type" "$effective_cmd"
        else
          projectr_install_result_push failed "$name"
          projectr_record_failed_install "$tool_id" "$name" "$effective_pkg" "$group" "$type" "$effective_cmd"
        fi
      done
    else
      stop_spinner "${ERROR}  [x] Batch installation failed via $group. Falling back to individual tool installations.${RST}"
      projectr_log_file_excerpt FAIL "$tmp" "batch-install" 30
      for entry in "${group_entries[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
        projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
      done
    fi
    rm -f "$tmp"
  done

  post_install_summary
}
