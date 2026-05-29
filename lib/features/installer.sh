#!/bin/bash
# --- DRY RUN & UNDO WRAPPER ENGINE ---
# Replaces or intercepts raw execution calls
execute_pkg_command() {
    local pkg_name="$1"
    local internal_name="$2"
    local action="${3:-install}"
    shift 3
    # Remaining positional args are the command + its arguments — no eval needed

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo -e "${INFO}   [DRY-RUN] Would execute: $* ${RST}"
        sleep 0.2
        return 0
    fi

    # Execute safely as an array — no string injection risk
    "$@"
    local status=$?

    if [[ $status -eq 0 && "$action" == "install" ]]; then
        mkdir -p "$SCRIPT_DIR/log/"
        echo "$(date '+%F %T')|$internal_name|$pkg_name" \
            >> "$SCRIPT_DIR/log/session_history.tmp" 2>/dev/null || true
    fi

    return $status
}
# -- install function --
install_all() {
# For post-install summary detection
  INSTALLED_PKGS=()
  SKIPPED_PKGS=()
  FAILED_PKGS=()
  log INSTALL "User chose to install all tools"
   # Checks for Internet before proceeding
   require_internet 
   # Update package lists
   echo ""
   progress_run "Syncing repositories" \
                 "Package lists updated" \
                 pkg_update
   sleep 0.1
   echo -e "${INFO}"
   local upgrade_choice
   upgrade_choice=$(config_get "skip_sys_upgrade")

   if [ "$upgrade_choice" = "skip" ]; then
       print_box center "  [*] Skipping system upgrade (saved preference)"
       sleep 1
   elif [ "$upgrade_choice" = "do" ]; then
       progress_run "Upgrading system" \
                    "System upgrade complete" \
                    pkg_upgrade
   else
       if ask "  [!] Upgrade the system?" "n"; then
           config_set "skip_sys_upgrade" "do"
           progress_run "Upgrading system" \
                        "System upgrade complete" \
                        pkg_upgrade
       else
           config_set "skip_sys_upgrade" "skip"
           print_box center "  [*] Skipping system upgrade"
           sleep 2
       fi
   fi
   clear
   safe_tput civis
   show_install_wait
   echo -e "${OPTION}"
   print_box center "[*] Installing all tools"
   echo -e "${RST}"
   
   for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"

        case "$type" in
            pkg)
                install_pkg "$cmd" "$pkg" "$name"
                ;;
            pip)
                install_lang "pip" "$pkg" "$name" "$cmd"
                ;;
            special)
                if declare -f "$extra" >/dev/null 2>&1; then
                    "$extra"
                else
                    echo -e "${ERROR}  [!] Special installer '${extra}' not found — skipping ${name}.${RST}"
                    FAILED_PKGS+=("$name")
                fi
                ;;
        esac
    done

    # -- post-install-summary
    echo ""
    post_install_summary
    echo -e "${OPTION}" 
    print_box center "[✓] installation Completed."
    echo -e "${RST}"
    printf "${DIM}  [press ENTER]${RST}"
    read -s; echo
    safe_tput cnorm

}

# For profile preset installation
install_preset() {
    local preset=("$@")

    if [[ ${#preset[@]} -eq 0 ]]; then
        echo -e "${ERROR}  [!] No tools provided to install_preset.${RST}"
        return 1
    fi

    INSTALLED_PKGS=()
    SKIPPED_PKGS=()
    FAILED_PKGS=()

    for entry in "${preset[@]}"; do
        IFS="|" read -r cmd pkg name <<< "$entry"
        if [[ -z "$cmd" || -z "$pkg" || -z "$name" ]]; then
            echo -e "${ERROR}  [!] Malformed preset entry: '$entry' — skipping.${RST}"
            continue
        fi
        install_pkg "$cmd" "$pkg" "$name"
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
        return 1
    fi

    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${OPTION}  [✓] $name is already installed - Skipping..${RST}"
        SKIPPED_PKGS+=("$name")
        log SKIPPED "$name was already installed (Skipped)"
        sleep 1
        return 0
    fi

    start_spinner "  [*] Installing: $name (via $PM).."

    case "$PM" in
        apt)
            execute_pkg_command "$pkg" "$cmd" "install" \
                sudo apt-get install -y "$pkg" >/dev/null 2>&1
            ;;
        dnf|yum)
            execute_pkg_command "$pkg" "$cmd" "install" \
                sudo "$PM" install -y "$pkg" >/dev/null 2>&1
            ;;
        pacman)
            execute_pkg_command "$pkg" "$cmd" "install" \
                sudo pacman -Sy --noconfirm --needed "$pkg" >/dev/null 2>&1
            ;;
        zypper)
            execute_pkg_command "$pkg" "$cmd" "install" \
                sudo zypper install -y "$pkg" >/dev/null 2>&1
            ;;
        brew)
            execute_pkg_command "$pkg" "$cmd" "install" \
                brew install "$pkg" >/dev/null 2>&1
            ;;
        apk)
            execute_pkg_command "$pkg" "$cmd" "install" \
                sudo apk add "$pkg" >/dev/null 2>&1
            ;;
        emerge)
            execute_pkg_command "$pkg" "$cmd" "install" \
                sudo emerge -av "$pkg" >/dev/null 2>&1
            ;;
        nix)
            execute_pkg_command "$pkg" "$cmd" "install" \
                nix-env -i "$pkg" >/dev/null 2>&1
            ;;
        flatpak)
            execute_pkg_command "$pkg" "$cmd" "install" \
                flatpak install -y flathub "$pkg" >/dev/null 2>&1
            ;;
        snap)
            execute_pkg_command "$pkg" "$cmd" "install" \
                sudo snap install "$pkg" >/dev/null 2>&1
            ;;
        pkg)
            execute_pkg_command "$pkg" "$cmd" "install" \
                pkg install -y "$pkg" >/dev/null 2>&1
            ;;
        choco|chocolatey)
            execute_pkg_command "$pkg" "$cmd" "install" \
                choco install -y "$pkg" >/dev/null 2>&1

            ;;
        scoop)
            execute_pkg_command "$pkg" "$cmd" "install" \
                scoop install "$pkg" >/dev/null 2>&1
            ;;
        winget)
            execute_pkg_command "$pkg" "$cmd" "install" \
                winget install -e --id "$pkg" >/dev/null 2>&1
            ;;
        *)
            stop_spinner
            echo -e "${ERROR}  [x] Unsupported package manager: $PM${RST}"
            FAILED_PKGS+=("$name")
            log FAIL "$name — unsupported PM: $PM"
            return 1
            ;;
    esac

    local install_exit=$?
    if [[ $install_exit -eq 0 ]]; then
        INSTALLED_PKGS+=("$name")
        stop_spinner "${OPTION}  [✓] $name installed successfully (via $PM).${RST}"
        log INSTALLED "$name installed successfully (via $PM)"
    else
        FAILED_PKGS+=("$name")
        stop_spinner "${ERROR}  [x] Failed to install: $name.${RST}"
        log FAIL "$name failed to install (on $PM)"
    fi
    sleep 2
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
        SKIPPED_PKGS+=("$display_name")
        log SKIPPED "$display_name was already installed"
        sleep 1
        return 0
    fi

    if [[ "$lang_pm" == "none" ]]; then
        echo -e "${ERROR}  [✗] No $tool_type package manager found — cannot install $display_name${RST}"
        FAILED_PKGS+=("$display_name")
        return 1
    fi

    local max_attempts=2
    local attempt=1
    local err_tmp
    err_tmp=$(mktemp)

    start_spinner "  [*] Installing: $display_name (via $lang_pm).."

    while (( attempt <= max_attempts )); do
        if (( attempt > 1 )); then
            stop_spinner
            echo -e "${BOLD_YELLOW}  [!] Retry $attempt/$max_attempts for $display_name...${RST}"
            sleep 3
            start_spinner "  [*] Retrying: $display_name (via $lang_pm).."
        fi

        case "$lang_pm" in
            pip|pip3|pipx) $lang_pm install --quiet "$pkg_name" >"$err_tmp" 2>&1 && break ;;
            npm)           npm install -g --quiet "$pkg_name" >"$err_tmp" 2>&1 && break ;;
            yarn)          yarn global add --silent "$pkg_name" >"$err_tmp" 2>&1 && break ;;
            gem)           gem install --silent "$pkg_name" >"$err_tmp" 2>&1 && break ;;
            cargo)         cargo install --quiet "$pkg_name" >"$err_tmp" 2>&1 && break ;;
            *)
                stop_spinner
                echo -e "${ERROR}  [✗] Unknown language manager: $lang_pm${RST}"
                FAILED_PKGS+=("$display_name")
                rm -f "$err_tmp"
                return 1
                ;;
        esac
        ((attempt++))
    done

    if command -v "$check_cmd" >/dev/null 2>&1; then
        INSTALLED_PKGS+=("$display_name")
        stop_spinner "${OPTION}  [✓] $display_name installed successfully (via $lang_pm)${RST}"
        log INSTALLED "$display_name installed via $lang_pm"
        rm -f "$err_tmp"
        sleep 1
        return 0
    else
        local err_msg
        err_msg=$(grep -v '^\s*$' "$err_tmp" 2>/dev/null | tail -n1 | tr -cd '[:print:]')
        FAILED_PKGS+=("$display_name")
        stop_spinner "${ERROR}  [✗] Failed: $display_name${err_msg:+ — ${err_msg}}${RST}"
        log FAIL "$display_name install failed${err_msg:+: $err_msg}"
        rm -f "$err_tmp"
        sleep 2
        return 1
    fi
}
