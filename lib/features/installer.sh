#!/bin/bash

projectr_install_tool_by_fields() {
    local cmd="$1" pkg="$2" name="$3" type="$4" extra="${5:--}"

    case "$type" in
        pkg)
            install_pkg "$cmd" "$pkg" "$name"
            ;;
        pip|pip3|pipx|cargo|gem|npm|yarn|pnpm|bun)
            install_lang "$type" "$pkg" "$name" "$cmd"
            ;;
        special)
            if declare -f "$extra" >/dev/null 2>&1; then
                "$extra"
            else
                echo -e "${ERROR}  [!] Special installer '${extra}' not found — skipping ${name}.${RST}"
                log_fail "Special installer '${extra}' not found for $name" "install"
                projectr_install_result_push failed "$name"
                return 1
            fi
            ;;
        *)
            echo -e "${ERROR}  [!] Unsupported tool type '${type}' for ${name}.${RST}"
            log_fail "Unsupported tool type '${type}' for $name" "install"
            projectr_install_result_push failed "$name"
            return 1
            ;;
    esac
}

# -- install function --
install_all() {
    echo ""
    echo -e "${ERROR}  [!] Bulk install of all tools is disabled.${RST}"
    echo -e "${INFO}  [*] Use presets instead: ${BOLD_WHITE}project install --profile <file>.yml${RST}"
    echo -e "${OPTION}  [*] If you still want to go with it, then open 'installer.sh' in your preferred editor and uncomment everything in the function ${RST}"
    printf "${DIM}  [press ENTER]${RST}"
    read -s; echo
    return 1
 # # For post-install summary detection
 #  local -a INSTALLED_PKGS=()
 #  local -a SKIPPED_PKGS=()
 #  local -a FAILED_PKGS=()
 #  log INSTALL "User chose to install all tools"
 #   # Checks for Internet before proceeding
 #   require_internet 
 #   # Update package lists
 #   echo ""
 #   progress_run "Syncing repositories" \
 #                 "Package lists updated" \
 #                 pkg_update
 #   sleep 0.1
 #   echo -e "${INFO}"
 #   local upgrade_choice
 #   upgrade_choice=$(config_get "skip_sys_upgrade")
 #
 #   if [ "$upgrade_choice" = "skip" ]; then
 #       print_box center "  [*] Skipping system upgrade (saved preference)"
 #       sleep 1
 #   elif [ "$upgrade_choice" = "do" ]; then
 #       progress_run "Upgrading system" \
 #                    "System upgrade complete" \
 #                    pkg_upgrade
 #   else
 #       if ask "  [!] Upgrade the system?" "n"; then
 #           config_set "skip_sys_upgrade" "do"
 #           progress_run "Upgrading system" \
 #                        "System upgrade complete" \
 #                        pkg_upgrade
 #       else
 #           config_set "skip_sys_upgrade" "skip"
 #           print_box center "  [*] Skipping system upgrade"
 #           sleep 2
 #       fi
 #   fi
 #   declare -f projectr_snapshot_pre_install >/dev/null 2>&1 && projectr_snapshot_pre_install "install_all"
 #   clear
 #   safe_tput civis
 #   show_install_wait
 #   echo -e "${OPTION}"
 #   print_box center "[*] Installing all tools"
 #   echo -e "${RST}"
 #
 #   for entry in "${TOOLS[@]}"; do
 #        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
 #
 #        projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
 #    done
 #
 #    # -- post-install-summary
 #    echo ""
 #    post_install_summary
 #    echo -e "${OPTION}" 
 #    print_box center "[✓] installation Completed."
 #    echo -e "${RST}"
 #    printf "${DIM}  [press ENTER]${RST}"
 #    read -s; echo
 #    safe_tput cnorm

}

# For profile preset installation
install_preset_by_names() {
    local names=("$@")

    if [[ ${#names[@]} -eq 0 ]]; then
        echo -e "${ERROR}  [!] No tools provided to install_preset_by_names.${RST}"
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
            IFS="|" read -r num cmd pkg display desc type extra cat <<< "$entry"
            if [[ "$cmd" == "$name" ]]; then
                matched=1
                projectr_install_tool_by_fields "$cmd" "$pkg" "$display" "$type" "$extra"
                break
            fi
        done
        if [[ $matched -eq 0 ]]; then
            echo -e "${BOLD_YELLOW}  [!] '$name' not found in tool list — skipping.${RST}"
            log_warn "Preset requested unknown tool '$name'" "preset"
        fi
    done

    echo ""
    post_install_summary
}
# -- main installer function --
# install_pkg "git" "git" "Git: Version control"
install_pkg() {
    local cmd="$1"
    local pkg="$2"
    local name="$3"
    local PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

    if [[ -z "$cmd" || -z "$pkg" || -z "$name" ]]; then
        echo -e "${ERROR}  [!] install_pkg: missing argument (cmd='$cmd' pkg='$pkg' name='$name')${RST}"
        log_error "install_pkg missing argument cmd='$cmd' pkg='$pkg' name='$name'" "install"
        return 1
    fi

    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${OPTION}  [✓] $name is already installed - Skipping..${RST}"
        projectr_install_result_push skipped "$name"
        log SKIPPED "$name was already installed (Skipped)"
        sleep 1
        return 0
    fi

    start_spinner "  [*] Installing: $name (via $PM).."

    case "$PM" in
        apt)
            env DEBIAN_FRONTEND=noninteractive \
            sudo apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1
         if [[ $? -ne 0 ]]; then
            stop_spinner "${BOLD_YELLOW}  [!] apt install failed — refreshing package lists and retrying...${RST}"
            start_spinner "  [*] Installing: $name (retry after apt-get update).."
            sudo apt-get update >/dev/null 2>&1
            env DEBIAN_FRONTEND=noninteractive \
            sudo apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1
         fi
            ;;
        dnf|yum)
             sudo "$PM" install -y "$pkg" >/dev/null 2>&1
            ;;
        pacman)
             sudo pacman -Sy --noconfirm --needed "$pkg" >/dev/null 2>&1
            ;;
        zypper)
             sudo zypper --non-interactive install "$pkg" >/dev/null 2>&1
            ;;
        brew)
             brew install "$pkg" >/dev/null 2>&1
            ;;
        apk)
             sudo apk add --no-cache "$pkg" >/dev/null 2>&1
            ;;
        emerge)
             sudo emerge -av "$pkg" >/dev/null 2>&1
            ;;
        xbps)
             sudo xbps-install -Sy "$pkg" >/dev/null 2>&1
            ;;
        nix)
             nix-env -i "$pkg" >/dev/null 2>&1
            ;;
        guix)
             guix package --install "$pkg" >/dev/null 2>&1
            ;;
        eopkg)
             sudo eopkg install -y "$pkg" >/dev/null 2>&1
            ;;
        urpmi)
             sudo urpmi --auto "$pkg" >/dev/null 2>&1
            ;;
        slackpkg)
             sudo slackpkg install "$pkg" >/dev/null 2>&1
            ;;
        macports)
             sudo port install "$pkg" >/dev/null 2>&1
            ;;
        bsd-pkg)
             sudo pkg install -y "$pkg" >/dev/null 2>&1
            ;;
        pkg_add)
             doas pkg_add "$pkg" >/dev/null 2>&1
            ;;
        flatpak)
             flatpak install -y flathub "$pkg" >/dev/null 2>&1
            ;;
        snap)
             sudo snap install "$pkg" >/dev/null 2>&1
            ;;
        pkg)
             pkg install -y "$pkg" >/dev/null 2>&1
            ;;
        choco|chocolatey)
             choco install -y "$pkg" >/dev/null 2>&1
            ;;
        scoop)
             scoop install "$pkg" >/dev/null 2>&1
            ;;
        winget)
             winget install -e --id "$pkg" >/dev/null 2>&1
            ;;
        *)
            stop_spinner
            echo -e "${ERROR}  [x] Unsupported package manager: $PM${RST}"
            projectr_install_result_push failed "$name"
            log FAIL "$name — unsupported PM: $PM"
            return 1
            ;;
    esac

    local install_exit=$?
    if [[ $install_exit -eq 0 ]]; then
         # bookkeeping (was inside execute_pkg_command)
        mkdir -p "$SCRIPT_DIR/log/"
        echo "$(date '+%F %T')|$cmd|$pkg" >> "$SCRIPT_DIR/log/session_history.tmp" 2>/dev/null || true
        declare -f projectr_state_record_install >/dev/null 2>&1 && \
        projectr_state_record_install "$name" "$pkg" "${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}" "$cmd" || true
        projectr_install_result_push installed "$name"
        stop_spinner "${OPTION}  [✓] $name installed successfully (via $PM).${RST}"
        log INSTALLED "$name installed successfully (via $PM)"
    else
        projectr_install_result_push failed "$name"
        stop_spinner "${ERROR}  [x] Failed to install: $name.${RST}"
        log FAIL "$name failed to install (on $PM)"
    fi
    sleep 2
    return "$install_exit"
}
# Universal language package installer
# install_lang "pip" "holehe" "Holehe" "holehe"
install_lang() {
    local tool_type="$1"
    local pkg_name="$2"
    local display_name="${3:-$pkg_name}"
    local cmd="${4:-$pkg_name}"
    local check_cmd="${cmd:-$pkg_name}"
    local lang_pm
    lang_pm=$(detect_pkg_for_tool "$tool_type")

    if command -v "$check_cmd" >/dev/null 2>&1; then
        echo -e "${OPTION}  [✓] $display_name is already installed - Skipping..${RST}"
        projectr_install_result_push skipped "$display_name"
        log SKIPPED "$display_name was already installed"
        sleep 1
        return 0
    fi

    if [[ "$lang_pm" == "none" ]]; then
        echo -e "${ERROR}  [✗] No $tool_type package manager found — cannot install $display_name${RST}"
        log_fail "No $tool_type package manager found for $display_name" "install-lang"
        projectr_install_result_push failed "$display_name"
        return 1
    fi

    local max_attempts=2
    local attempt=1
    local err_tmp
    err_tmp=$(mktemp)
    export install_method="$lang_pm"

    start_spinner "  [*] Installing: $display_name (via $lang_pm).."

    while (( attempt <= max_attempts )); do
        if (( attempt > 1 )); then
            stop_spinner
            echo -e "${BOLD_YELLOW}  [!] Retry $attempt/$max_attempts for $display_name...${RST}"
            sleep 3
            start_spinner "  [*] Retrying: $display_name (via $lang_pm).."
        fi

        local install_cmd=()
        case "$lang_pm" in
            pip|pip3|pipx) install_cmd=("$lang_pm" install --quiet "$pkg_name") ;;
            npm)           install_cmd=(npm install -g --quiet "$pkg_name") ;;
            yarn)          install_cmd=(yarn global add --silent "$pkg_name") ;;
            pnpm)          install_cmd=(pnpm add -g "$pkg_name") ;;
            bun)           install_cmd=(bun add -g "$pkg_name") ;;
            gem)           install_cmd=(gem install --silent "$pkg_name") ;;
            cargo)         install_cmd=(cargo install --quiet "$pkg_name") ;;
            *)
                stop_spinner ""
                echo -e "${ERROR}  [✗] Unknown language manager: $lang_pm${RST}"
                log_fail "Unknown language manager '$lang_pm' for $display_name" "install-lang"
                projectr_install_result_push failed "$display_name"
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
        # bookkeeping
        mkdir -p "$SCRIPT_DIR/log/"
        echo "$(date '+%F %T')|$cmd|$pkg_name" >> "$SCRIPT_DIR/log/session_history.tmp" 2>/dev/null || true
        declare -f projectr_state_record_install >/dev/null 2>&1 && \
        projectr_state_record_install "$display_name" "$pkg_name" "$lang_pm" "$check_cmd" || true
        projectr_install_result_push installed "$display_name"
        stop_spinner "${OPTION}  [✓] $display_name installed successfully (via $lang_pm)${RST}"
        log INSTALLED "$display_name installed via $lang_pm"
        unset install_method
        rm -f "$err_tmp"
        sleep 1
        return 0
    else
        local err_msg
        err_msg=$(grep -v '^\s*$' "$err_tmp" 2>/dev/null | tail -n1 | tr -cd '[:print:]')
        projectr_install_result_push failed "$display_name"
        stop_spinner "${ERROR}  [✗] Failed: $display_name${err_msg:+ — ${err_msg}}${RST}"
        log FAIL "$display_name install failed${err_msg:+: $err_msg}"
        unset install_method
        rm -f "$err_tmp"
        sleep 2
        return 1
    fi
}

projectr_batch_command_for_group() {
    local manager="$1"
    shift
    case "$manager" in
        apt)    env DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends "$@" ;;
        pacman) sudo pacman -Sy --noconfirm --needed "$@" ;;
        dnf|yum) sudo "$manager" install -y "$@" ;;
        zypper) sudo zypper --non-interactive install "$@" ;;
        brew)   brew install "$@" ;;
        apk)    sudo apk add --no-cache "$@" ;;
        pkg)    pkg install -y "$@" ;;
        pip|pip3|pipx) "$manager" install --quiet "$@" ;;
        npm)    npm install -g --quiet "$@" ;;
        yarn)   yarn global add --silent "$@" ;;
        pnpm)   pnpm add -g "$@" ;;
        bun)    bun add -g "$@" ;;
        gem)    gem install --silent "$@" ;;
        cargo)  cargo install --quiet "$@" ;;
        *) return 2 ;;
    esac
}

projectr_install_batch_by_entries() {
    local -a entries=("$@")
    local -a INSTALLED_PKGS=()
    local -a SKIPPED_PKGS=()
    local -a FAILED_PKGS=()
    local PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    local entry num cmd pkg name desc type extra cat key
    local -a group_keys=()

    declare -f projectr_snapshot_pre_install >/dev/null 2>&1 && projectr_snapshot_pre_install "batch_install"

    for entry in "${entries[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        if command -v "$cmd" >/dev/null 2>&1; then
            projectr_install_result_push skipped "$name"
            continue
        fi
        case "$type" in
            pkg) key="$PM" ;;
            pip|pip3|pipx|cargo|gem|npm|yarn|pnpm|bun) key="$(detect_pkg_for_tool "$type")" ;;
            *) projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"; continue ;;
        esac
        [[ "$key" != "none" && -n "$key" ]] || { projectr_install_result_push failed "$name"; continue; }
        eval "projectr_batch_pkgs_${key//[^A-Za-z0-9_]/_}+=(\"\$pkg\")"
        eval "projectr_batch_names_${key//[^A-Za-z0-9_]/_}+=(\"\$name\")"
        case " ${group_keys[*]} " in *" $key "*) ;; *) group_keys+=("$key") ;; esac
    done

    local group safe status tmp
    for group in "${group_keys[@]}"; do
        safe=${group//[^A-Za-z0-9_]/_}
        eval 'local -a pkgs=("${projectr_batch_pkgs_'"$safe"'[@]}")'
        eval 'local -a names=("${projectr_batch_names_'"$safe"'[@]}")'
        [[ ${#pkgs[@]} -gt 0 ]] || continue

        tmp=$(mktemp)
        start_spinner "  [*] Batch installing ${#pkgs[@]} package(s) via $group.."
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            printf '[DRY-RUN] %s install payload: %s\n' "$group" "${pkgs[*]}" >"$tmp"
            status=0
        else
            projectr_batch_command_for_group "$group" "${pkgs[@]}" >"$tmp" 2>&1
            status=$?
        fi
        if [[ $status -eq 0 ]]; then
            stop_spinner "${OPTION}  [✓] Batch installed ${#pkgs[@]} package(s) via $group.${RST}"
            local n
            for n in "${names[@]}"; do projectr_install_result_push installed "$n"; done
        else
            stop_spinner "${ERROR}  [x] Batch install failed via $group; falling back to per-tool installs.${RST}"
            projectr_log_file_excerpt FAIL "$tmp" "batch-install" 30
            for entry in "${entries[@]}"; do
                IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
                case "$type" in
                    pkg) [[ "$group" == "$PM" ]] && projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra" ;;
                    pip|pip3|pipx|cargo|gem|npm|yarn|pnpm|bun) [[ "$group" == "$(detect_pkg_for_tool "$type")" ]] && projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra" ;;
                esac
            done
        fi
        rm -f "$tmp"
    done

    post_install_summary
}
