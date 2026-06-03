#!/bin/bash
# -- for safely Sourceimg files --
_FLAGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(cd "$_FLAGS_DIR/../.." && pwd)"

# Central flag dispatcher — called before the main interactive loop.
# Each --flag or --flag=value is handled here and exits immediately.
parse_flags() {
    # flags.sh is the one dispatcher for both modern commands and legacy flags.
    # Feature-specific implementation still lives in lib/core or lib/features,
    # but every CLI argument is routed from this function.
    [[ $# -eq 0 ]] && return 0

    local args=() arg
    for arg in "$@"; do
        case "$arg" in
            --no-color)
                export PROJECTR_NO_COLOR=1
                if declare -f projectr_disable_color >/dev/null 2>&1; then
                    projectr_disable_color
                fi
                ;;
            --quiet)
                export PROJECTR_QUIET=1
                ;;
            *) args+=("$arg") ;;
        esac
    done

    # If only global display flags were provided, continue into interactive mode.
    [[ ${#args[@]} -eq 0 ]] && return 0
    set -- "${args[@]}"
    log INFO "CLI dispatch: $*" "cli"

    case "$1" in
        --version|-v|version)
            echo -e "${OPTION}projectr ${BOLD_WHITE}v1.3${RST}"
            exit 0
            ;;

        --help|-h|help)
            _flag_help
            exit 0
            ;;

        install|--install)
            shift
            projectr_cli_install_args "$@"
            exit $?
            ;;

        --install=*)
            local first_target="${1#--install=}"
            shift
            projectr_cli_install_args "$first_target" "$@"
            exit $?
            ;;

        uninstall|--uninstall)
            shift
            projectr_cli_uninstall_args "$@"
            exit $?
            ;;

        --uninstall=*)
            local first_target="${1#--uninstall=}"
            shift
            projectr_cli_uninstall_args "$first_target" "$@"
            exit $?
            ;;

        search|--search)
            shift
            [[ -n "${1:-}" ]] || { echo -e "${ERROR}[!] search requires a name.${RST}"; log_error "search command missing required name" "cli"; exit 1; }
            _flag_search "$1"
            exit $?
            ;;

        --search=*)
            _flag_search "${1#--search=}"
            exit $?
            ;;

        list|--list)
            shift
            projectr_cli_list_arg "${1:-tools}"
            exit $?
            ;;

        --list=*)
            projectr_cli_list_arg "${1#--list=}"
            exit $?
            ;;

        dry-run|--dry-run)
            shift
            case "${1:-}" in
                "")
                    projectr_dry_run_install
                    ;;
                install)
                    shift
                    projectr_dry_run_install "$@"
                    ;;
                reset|--reset)
                    shift
                    _flag_reset --dry-run "$@"
                    ;;
                upgrade|--upgrade)
                    shift
                    projectr_cli_upgrade_args --dry-run "$@"
                    ;;
                repair|--repair)
                    shift
                    projectr_dry_run_repair "$@"
                    ;;
                --profile)
                    shift
                    projectr_dry_run_profile "$@"
                    ;;
                --profile=*)
                    local profile_path="${1#--profile=}"
                    shift
                    projectr_dry_run_profile "$profile_path" "$@"
                    ;;
                *)
                    projectr_dry_run_install "$@"
                    ;;
            esac
            exit $?
            ;;

        --profile)
            shift
            projectr_cli_install_args --profile "$@"
            exit $?
            ;;

        --profile=*)
            projectr_install_profile "${1#--profile=}"
            exit $?
            ;;

        log|--log)
            shift
            _flag_log "${1:-20}"
            exit $?
            ;;

        --log=*)
            _flag_log "${1#--log=}"
            exit $?
            ;;

        reset|--reset)
            shift
            _flag_reset "$@"
            exit $?
            ;;

        export|--export)
            export_profile
            exit $?
            ;;

        import|--import)
            shift
            [[ -n "${1:-}" ]] || { echo -e "${ERROR}[!] import requires a file path.${RST}"; log_error "import command missing file path" "cli"; exit 1; }
            import_profile "$1"
            exit $?
            ;;

        --import=*)
            import_profile "${1#--import=}"
            exit $?
            ;;

        undo|--undo)
            rollback_last_session
            exit $?
            ;;

        upgrade|--upgrade)
            shift
            projectr_cli_upgrade_args "$@"
            exit $?
            ;;

        update|--update|self-update|--self-update|projectr-update|--projectr-update)
            projectr_run_update
            exit $?
            ;;

        doctor|--doctor)
            projectr_doctor
            exit $?
            ;;

        audit|--audit)
            shift
            projectr_audit_tools "$@"
            exit $?
            ;;

        verify|--verify)
            projectr_verify_state
            exit $?
            ;;

        repair|--repair)
            shift
            if [[ "${1:-}" == "--dry-run" ]]; then
                shift
                projectr_dry_run_repair "$@"
            else
                projectr_repair_state
            fi
            exit $?
            ;;

        completions|--completions)
            shift
            [[ "${1:-}" == "bash" ]] || { echo "Only bash completions are currently supported."; exit 1; }
            projectr_completions_bash
            exit 0
            ;;

        --*|-*)
            echo -e "${ERROR}[!] Unknown flag: ${BOLD_WHITE}$1${RST}"
            log_error "Unknown flag: $1" "cli"
            echo -e "${INFO}[*] Run ${BOLD_WHITE}${PROJECTR_LAUNCHER_NAME:-./main.sh} --help or -h${RST}${INFO} to see available flags.${RST}"
            exit 1
            ;;

        *)
            echo -e "${ERROR}[!] Unknown command: ${BOLD_WHITE}$1${RST}"
            log_error "Unknown command: $1" "cli"
            echo -e "${INFO}[*] Run ${BOLD_WHITE}${PROJECTR_LAUNCHER_NAME:-./main.sh} --help or -h${RST}${INFO} to see available commands.${RST}"
            exit 1
            ;;
    esac
}

# ── Built-in helpers (small enough to live here) ────
_flag_help() {
    if declare -f projectr_cli_help >/dev/null 2>&1; then
        projectr_cli_help
        return
    fi

    local usage_cmd="${PROJECTR_LAUNCHER_NAME:-./main.sh}"
    echo ""
    echo -e "${OPTION} [*] ProjectR — Available Flags ${RST}"
    echo ""
    echo -e "${DIM} Usage:${RST} ${BOLD_WHITE}${usage_cmd}${RST} ${DIM}[flag]${RST}"
    echo ""
    echo -e "   [*] Flags${RST}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${RST}"
    printf "  ${BOLD_WHITE}%-26s${RST}  %s\n" \
        "-v, --version"          "Show script version" \
        "-h, --help"             "Show this help message" \
        "--search=<name>"       "Search all managers and install by name" \
        "--list=manager"         "All package managers + availability" \
        "--list=tools"           "All tools in the TOOLS array" \
        "--list=installed"       "Only tools that are currently installed" \
        "--list=categories"      "Tools grouped by category (Dev/Fun/Min…)" \
        "--install=<name>"       "Install a tool non-interactively (e.g. git)" \
        "--uninstall=<name>"     "Uninstall a tool non-interactively" \
        "--log"                  "Print last 20 lines of install.log" \
        "--log=<n>"              "Print last N lines of install.log" \
        "--reset"                "Clear all saved preferences (non-interactive)" \
        "--export"               "Exports profile into projectr_profile_$(date +%F).txt" \
        "--import=<file>"        "Import profile from projectr_profile_$(date +%F).txt" \
        "--dry-run"              "Simulate changes without installing packages" \
        "--undo"                 "Undo last sessions changes" \
        "--update"               "Pull the latest ProjectR git checkout and show applied commits" \
        "--doctor"               "Check PATH, dependencies, package manager, and logs" \
        "--audit"                "Validate registry IDs, types, and special installers"
    if [[ -n "${PROJECTR_LAUNCHER_NAME:-}" ]]; then
        printf "  ${BOLD_WHITE}%-26s${RST}  %s\n" \
            "--self-update"          "Refresh installed app files from the original checkout" \
            "--setup-info"           "Show launcher, source, and install paths"
    fi
    echo ""
    echo -e "   [*] Examples${RST}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${RST}"
    echo -e "  ${DIM}\$${RST} ${usage_cmd} ${DIM}                       -- Interactive mode${RST}"
    echo -e "  ${DIM}\$${RST} ${usage_cmd} ${BOLD_WHITE}--install=git${DIM}         -- Install git silently${RST}"
    echo -e "  ${DIM}\$${RST} ${usage_cmd} ${BOLD_WHITE}--list=installed${DIM}      -- See what's installed${RST}"
    echo -e "  ${DIM}\$${RST} ${usage_cmd} ${BOLD_WHITE}--list=categories${DIM}     -- Browse tools by category${RST}"
    echo -e "  ${DIM}\$${RST} ${usage_cmd} ${BOLD_WHITE}--log=50${DIM}              -- Last 50 log lines${RST}"
    echo -e "  ${DIM}\$${RST} ${usage_cmd} ${BOLD_WHITE}--reset${DIM}               -- Wipe saved preferences${RST}"
    echo ""
}

_flag_list_tools() {

    echo ""
    # ── Header ──
    echo -e "${BOLD}${OPTION} [*] Available Tools for install ${RST}"
    echo ""
    
    # ── Table ───
    printf "  ${BOLD_WHITE}%-4s  %-16s  %-40s${RST}\n" \
        "Num" "Name" "Description"
    # Separator 
    printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 66))"

    # Data
    for entry in "${TOOLS[@]}"; do
       IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
       local disp_desc="$desc"
       (( ${#disp_desc} > 40 )) && disp_desc="${disp_desc:0:37}..."
       printf "  ${BARR}%-4s${RST}  ${OPTION}%-16s${RST}  ${DIM}%-40s${RST}\n" \
           "$num" "$name" "$disp_desc"
    done
    
    # ── Summary ───
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${RST}"
    echo -e "  ${DIM}Total:${RST}  ${BOLD_WHITE}${#TOOLS[@]}${RST} tools available"
    echo ""
}
# --list=manager : shows all known package managers, their status and OS support
_flag_list_manager() {
    # ── OS/platform detection ───
    local detected_os="Unknown"
    local detected_pm
    detected_pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

    if [ -n "${PREFIX:-}" ] && [[ "$PREFIX" == *termux* ]]; then
        detected_os="Termux (Android)"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        detected_os="macOS"
    elif [[ -f /etc/os-release ]]; then
        detected_os=$(. /etc/os-release && echo "${PRETTY_NAME:-Linux}")
    elif [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"CYGWIN"* ]]; then
        detected_os="Windows (WSL/Cygwin)"
    else
        detected_os="Linux"
    fi

    # ── Manager registry ───
    local managers=(
        "apt|apt|Linux (Debian/Ubuntu)|apt"
        "apt-get|apt-get|Linux (Debian/Ubuntu)|apt-get"
        "pacman|pacman|Linux (Arch)|pacman"
        "dnf|dnf|Linux (Fedora/RHEL)|dnf"
        "yum|yum|Linux (CentOS/RHEL)|yum"
        "zypper|zypper|Linux (openSUSE)|zypper"
        "apk|apk|Linux (Alpine)|apk"
        "emerge|emerge|Linux (Gentoo)|emerge"
        "xbps|xbps-install|Linux (Void)|xbps-install"
        "nix|nix|Linux/macOS (NixOS)|nix"
        "guix|guix|Linux (GNU Guix)|guix"
        "eopkg|eopkg|Linux (Solus)|eopkg"
        "urpmi|urpmi|Linux (Mageia)|urpmi"
        "slackpkg|slackpkg|Linux (Slackware)|pkgtool"
        "pkg|pkg (Termux)|Termux (Android)|pkg"
        "brew|brew|macOS / Linux|brew"
        "macports|port|macOS|port"
        "bsd-pkg|pkg (FreeBSD)|FreeBSD|pkg"
        "pkg_add|pkg_add|OpenBSD|pkg_add"
        "winget|winget|Windows|winget.exe"
        "choco|choco|Windows|choco.exe"
        "scoop|scoop|Windows|scoop"
        "flatpak|flatpak|Linux|flatpak"
        "snap|snap|Linux|snap"
    )

    # ── Header (using echo -e, already safe) ───
    echo ""
    echo -e "${OPTION} [*] ProjectR — Supported Package Managers ${RST}"
    echo ""
    echo -e "  ${DIM}List of all package managers known to ProjectR."
    echo -e "  Legend:  ${OPTION}✔${RST} = available, ${ERROR}✘${RST} = not found,  ${OPTION}★${RST} = primary${RST}"
    echo ""

    # ── Dynamic column widths ───
    local max_name=15   # "Package Manager"
    local max_os=12     # "Platform"
    for entry in "${managers[@]}"; do
        IFS="|" read -r id display platform _ <<< "$entry"
        (( ${#display} > max_name )) && max_name=${#display}
        (( ${#platform} > max_os )) && max_os=${#platform}
    done
    (( max_name < 15 )) && max_name=15
    (( max_os < 12 )) && max_os=12

    # ── Table header (FIXED: colors as %b arguments) ───
    printf "  %b%-${max_name}s  %-6s  %-${max_os}s%b\n" \
        "$BOLD_WHITE" "Package Manager" "Avail" "Platform" "$RST"

    # Separator (FIXED)
    printf "  %b%s%b\n" \
        "$DIM" \
        "$(printf '─%.0s' $(seq 1 $(( max_name + 7 + max_os + 2 ))))" \
        "$RST"

    # ── Table rows ───
    local available_list=()
    for entry in "${managers[@]}"; do
        IFS="|" read -r id display platform check_cmd <<< "$entry"

        # Force FreeBSD pkg to be unavailable on Termux
        local force_unavailable=0
        [[ "$detected_os" == "Termux (Android)" && "$id" == "bsd-pkg" ]] && force_unavailable=1

        local icon icon_color marker=""
        if (( force_unavailable )); then
            icon="✘"
            icon_color="${ERROR}"
        elif command -v "$check_cmd" >/dev/null 2>&1; then
            icon="✔"
            icon_color="${OPTION}"
            available_list+=("$display")
            # Mark the primary (active) one
            [[ "$id" == "$detected_pm" ]] && marker=" ${OPTION}★${RST}"
        else
            icon="✘"
            icon_color="${ERROR}"
        fi

        # FIXED: all colour variables moved to %b arguments
        printf "  %b%-${max_name}s%b  %b%-6s%b  %b%-${max_os}s%b%b\n" \
            "$BOLD_WHITE" "$display" "$RST" \
            "$icon_color" "$icon" "$RST" \
            "$DIM" "$platform" "$RST" \
            "$marker"
    done

    # ── Footer ───
    echo ""
    # Separator again (FIXED)
    printf "  %b%s%b\n" \
        "$DIM" \
        "$(printf '─%.0s' $(seq 1 $(( max_name + 7 + max_os + 2 ))))" \
        "$RST"

    # Footer lines (echo -e already safe)
    echo -e "  ${INFO}Detected OS :${RST}  ${BOLD_WHITE}${detected_os}${RST}"
    echo -e "  ${INFO}Primary PM  :${RST} ${OPTION} ${detected_pm}${RST}"

    local extra=()
    for m in "${available_list[@]}"; do
        [[ "$m" != "$detected_pm" ]] && extra+=("$m")
    done
    if [ ${#extra[@]} -gt 0 ]; then
        echo -e "  ${INFO}Also found  :${RST}  ${BOLD_WHITE}${extra[*]}${RST}"
    fi
    echo ""
}
# ── --list=installed ───
_flag_list_installed() {
    echo ""
    echo -e "${OPTION} [*] Installed Tools ${RST}"
    echo ""

    local found=()
    local not_found=()

    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        if command -v "$cmd" >/dev/null 2>&1; then
            local version
            version=$("$cmd" --version 2>/dev/null | head -n1 \
                      | grep -oE '[0-9]+\.[0-9]+[.0-9]*' | head -n1)
            found+=("$num|$name|$cat|${version:--}")
        else
            not_found+=("$name")
        fi
    done

    if [ ${#found[@]} -eq 0 ]; then
        echo -e "  ${ERROR}[!] No tools from the list are currently installed.${RST}"
        echo ""
        return
    fi

    printf "  ${BOLD_WHITE}%-4s  %-16s  %-10s  %-10s${RST}\n" \
        "Num" "Name" "Category" "Version"
    printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 46))"

    for entry in "${found[@]}"; do
        IFS="|" read -r num name cat version <<< "$entry"
        printf "  ${BARR}%-4s${RST}  ${OPTION}%-16s${RST}  ${INFO}%-10s${RST}  ${DIM}%-10s${RST}\n" \
            "$num" "$name" "$cat" "$version"
    done

    echo ""
    printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 46))"
    echo -e "  ${OPTION}[*] Installed : ${BOLD_WHITE}${#found[@]}${RST} / ${#TOOLS[@]}${RST}"
    echo -e "  ${ERROR}[*] Missing   : ${BOLD_WHITE}${#not_found[@]}${RST} / ${#TOOLS[@]}${RST}"
    echo ""
}

# ── --list=categories ────
_flag_list_categories() {
    echo ""
    echo -e "${BOLD}${OPTION} [*] Tools listed by Category ${RST}"
    echo ""
    echo -e "${DIM}  Status:${RST}${GREEN} ✔ ${RST}= installed,${RED} ✘ ${RST}= not found"
    echo ""
    # Collect unique categories in insertion order
    local cats=()
    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        local found=0
        for c in "${cats[@]:-}"; do [[ "$c" == "$cat" ]] && found=1 && break; done
        (( found )) || cats+=("$cat")
    done

    for category in "${cats[@]}"; do
        echo -e "  ${BOLD_WHITE}${category}${RST}"
        printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 50))"
        for entry in "${TOOLS[@]}"; do
            IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
            [[ "$cat" != "$category" ]] && continue
            # Show install status inline
            local status_icon status_color
            if command -v "$cmd" >/dev/null 2>&1; then
                status_icon="✔" status_color="${OPTION}"
            else
                status_icon="✘" status_color="${ERROR}"
            fi
            printf "  ${BARR}[%02d]${RST}  ${status_color}%s${RST}  ${BOLD_WHITE}%-14s${RST}  ${DIM}%s${RST}\n" \
                "$num" "$status_icon" "$name" "$desc"
        done
        echo ""
    done
}

# ── --log / --log=N ───
_flag_log() {
    local lines="${1:-20}"

    # Validate: must be a positive integer
    if [[ ! "$lines" =~ ^[0-9]+$ ]] || (( lines < 1 )); then
        echo -e "  ${ERROR}[!] Invalid value for --log: '${lines}' — must be a positive integer.${RST}"
        echo -e "  ${DIM}Example: ./main.sh --log=50${RST}"
        return 1
    fi

    # LOG_FILE is defined in logging.sh — but flags run before it's sourced,
    # so we hardcode the same path here to stay independent
    local log_path="${SCRIPT_DIR:-$(pwd)}/log/install.log"

    echo ""
    echo -e "${OPTION} [*] Install Log ${DIM}(last ${lines} lines)${RST}"
    echo ""

    if [ ! -f "$log_path" ]; then
        echo -e "  ${ERROR}[!] No log file found at: ${BOLD_WHITE}${log_path}${RST}"
        echo -e "  ${DIM}Run the script interactively at least once to generate it.${RST}"
        echo ""
        return
    fi

    printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 60))"

    # Colour-code by log level
    tail -n "$lines" "$log_path" | while IFS= read -r line; do
        case "$line" in
            *\[INSTALL\]*)  echo -e "  ${OPTION}${line}${RST}" ;;
            *\[FAIL\]*)     echo -e "  ${ERROR}${line}${RST}" ;;
            *\[ERROR\]*)    echo -e "  ${ERROR}${line}${RST}" ;;
            *\[SKIPPED\]*)  echo -e "  ${DIM}${line}${RST}" ;;
            *\[EXIT\]*)     echo -e "  ${INFO}${line}${RST}" ;;
            *\[OK\]*)       echo -e "  ${OPTION}${line}${RST}" ;;
            *━━*)           echo -e "  ${BOLD_WHITE}${line}${RST}" ;;   # session separators
            *)              echo -e "  ${line}" ;;
        esac
    done

    printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 60))"
    echo -e "  ${DIM}Full log: ${BOLD_WHITE}${log_path}${RST}"
    echo ""
}

# ── --reset ───
_flag_reset() {
    local dry=0 arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry=1 ;;
            *) echo -e "${ERROR}[!] Unknown reset option: $arg${RST}"; return 2 ;;
        esac
    done
    echo ""
    echo -e "${OPTION} [*] Reset Saved Preferences ${RST}"
    echo ""

    local config_path="${HOME}/.config/projectr/session.conf"

    if [ ! -f "$config_path" ]; then
        echo -e "  ${DIM} [*] Nothing to reset — no config file found.${RST}"
        echo ""
        return
    fi

    # Show what's currently saved before wiping
    local line_count
    line_count=$(wc -l < "$config_path")

    if [ "$line_count" -eq 0 ]; then
        echo -e "${DIM} [*] Config file is already empty.${RST}"
        echo ""
        return
    fi

    echo -e "${INFO} [*] Clearing ${BOLD_WHITE}${line_count}${RST}${INFO} saved preference(s):${RST}"
    echo ""
    while IFS= read -r line; do
        echo -e "    ${DIM}✘  ${line}${RST}"
    done < "$config_path"
    echo ""

    if [[ $dry -eq 1 ]]; then
        echo -e "${DIM} [DRY-RUN] Would clear ${config_path}; no preferences were changed.${RST}"
    else
        > "$config_path"
        echo -e "${OPTION} [✓] All preferences cleared.${RST}"
    fi
    echo ""
}

# ── --install=<name> ───
_flag_install() {
    local target="$1"
    echo ""
    echo -e "${OPTION} [*] Non-interactive install: ${BOLD_WHITE}${target}${RST}"
    echo ""

    # Find the matching tool entry
    local matched_entry=""
    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        # Match against cmd, pkg name, or display name (case-insensitive)
        if [[ "${cmd,,}" == "${target,,}" || \
              "${pkg,,}" == "${target,,}" || \
              "${name,,}" == "${target,,}" ]]; then
            matched_entry="$entry"
            break
        fi
    done

    if [ -z "$matched_entry" ]; then
        echo -e "  ${ERROR}[!] No tool named '${target}' found in the list.${RST}"
        echo -e "  ${DIM}Run ${BOLD_WHITE}./main.sh --list=tools${RST}${DIM} to see valid names.${RST}"
        echo ""
        return 1
    fi

    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$matched_entry"

    # Already installed?
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "  ${OPTION}[✓] ${name} is already installed — nothing to do.${RST}"
        echo ""
        return 0
    fi

    # special type tools can't run non-interactively (they prompt the user)
    if [[ "$type" == "special" ]]; then
        echo -e "  ${ERROR}[!] '${name}' uses an interactive installer and can't be run via flag.${RST}"
        echo -e "  ${DIM}Launch the script normally and select [${num}] from the menu.${RST}"
        echo ""
        return 1
    fi

    # Guard: verify every required file exists before sourcing
    local _required=(
        "$_PROJECT_ROOT/lib/core/progress_bar.sh"
        "$_PROJECT_ROOT/lib/core/spinner.sh"
        "$_PROJECT_ROOT/lib/core/logging.sh"
    )
    for _f in "${_required[@]}"; do
        if [[ ! -f "$_f" ]]; then
            echo -e "  ${ERROR}[!] Required file missing: $_f${RST}"
            echo -e "  ${DIM}Check that \$_PROJECT_ROOT is correct: $_PROJECT_ROOT${RST}"
            return 1
        fi
        source "$_f"
    done

    local -a INSTALLED_PKGS=()
    local -a SKIPPED_PKGS=()
    local -a FAILED_PKGS=()

    projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
    local status=$?

    echo ""
    return "$status"
}

# ── --uninstall=<name> ────
_flag_uninstall() {
    local target="$1"
    echo ""
    echo -e "${OPTION} [*] Non-interactive uninstall: ${BOLD_WHITE}${target}${RST}"
    echo ""

    local matched_entry=""
    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        if [[ "${cmd,,}" == "${target,,}" || \
              "${pkg,,}" == "${target,,}" || \
              "${name,,}" == "${target,,}" ]]; then
            matched_entry="$entry"
            break
        fi
    done

    if [ -z "$matched_entry" ]; then
        echo -e "  ${ERROR}[!] No tool named '${target}' found in the list.${RST}"
        echo -e "  ${DIM}Run ${BOLD_WHITE}./main.sh --list=tools${RST}${DIM} to see valid names.${RST}"
        echo ""
        return 1
    fi

    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$matched_entry"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "  ${DIM}[*] ${name} is not installed — nothing to do.${RST}"
        echo ""
        return 0
    fi

    local _required=(
        "$_PROJECT_ROOT/lib/core/spinner.sh"
        "$_PROJECT_ROOT/lib/core/logging.sh"
    )
    for _f in "${_required[@]}"; do
        if [[ ! -f "$_f" ]]; then
            echo -e "  ${ERROR}[!] Required file missing: $_f${RST}"
            echo -e "  ${DIM}Check that \$_PROJECT_ROOT is correct: $_PROJECT_ROOT${RST}"
            return 1
        fi
        source "$_f"
    done

    export NON_INTERACTIVE=1
    projectr_uninstall_tool_by_fields "$cmd" "$pkg" "$name" "$type"
    local status=$?
    unset NON_INTERACTIVE
    echo ""
    return "$status"
}

# Search and install flag
_flag_search() {
    local target="$1"
    echo ""
    echo -e "${OPTION} [*] Search & install: ${BOLD_WHITE}${target}${RST}"
    echo ""

    local _required=(
        "$_PROJECT_ROOT/lib/features/search_install.sh"
        "$_PROJECT_ROOT/lib/core/spinner.sh"
        "$_PROJECT_ROOT/lib/core/logging.sh"
        "$_PROJECT_ROOT/lib/features/installer.sh"
        "$_PROJECT_ROOT/lib/features/post_install.sh"
    )
    for _f in "${_required[@]}"; do
        if [[ ! -f "$_f" ]]; then
            echo -e "  ${ERROR}[!] Required file missing: $_f${RST}"
            echo -e "  ${DIM}Check that \$_PROJECT_ROOT is correct: $_PROJECT_ROOT${RST}"
            return 1
        fi
        source "$_f"
    done

    local -a INSTALLED_PKGS=() SKIPPED_PKGS=() FAILED_PKGS=()
    search_and_install "$target"
    local status=$?
    echo ""
    return "$status"
}
