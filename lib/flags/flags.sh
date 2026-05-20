#!/bin/bash
# lib/flags/flags.sh
# Central flag dispatcher — called before the main interactive loop.
# Each --flag or --flag=value is handled here and exits immediately.

parse_flags() {
    # Nothing passed — let main.sh continue normally
    [[ $# -eq 0 ]] && return 0

    for arg in "$@"; do
        case "$arg" in

            --version|-v)
                echo -e "${OPTION}ProjectR ${BOLD_WHITE}v1.0${RST}"
                exit 0
                ;;

            --help|-h)
                _flag_help
                exit 0
                ;;

            --list=manager)
                _flag_list_manager
                exit 0
                ;;

            --list=tools)
                _flag_list_tools
                exit 0
                ;;
            --install=*)
                _flag_install "${arg#--install=}"
                exit 0
                ;;

            --uninstall=*)
                _flag_uninstall "${arg#--uninstall=}"
                exit 0
                ;;

            --list=installed)
               _flag_list_installed
               exit 0
               ;;

            --list=categories)
              _flag_list_categories
              exit 0
              ;;

            --log)
              _flag_log 20
              exit 0
              ;;

            --log=*)
              _flag_log "${arg#--log=}"
              exit 0
              ;;

            --reset)
              _flag_reset
              exit 0
              ;;
            # ── Unknown flag ───────────────────────────────────────────
            --*|-*)
                echo -e "${ERROR}[!] Unknown flag: ${BOLD_WHITE}$arg${RST}"
                echo -e "${INFO}[*] Run ${BOLD_WHITE}./main.sh --help or -h${RST}${INFO} to see available flags.${RST}"
                exit 1
                ;;
        esac
    done
}

# ── Built-in helpers (small enough to live here) ─────────────────────────────
_flag_help() {
    echo ""
    echo -e "${OPTION} [*] ProjectR — Available Flags ${RST}"
    echo ""
    echo -e "${DIM} Usage:${RST} ${BOLD_WHITE}./main.sh${RST} ${DIM}[flag]${RST}"
    echo ""
    echo -e "   [*] Flags${RST}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${RST}"
    printf "  ${BOLD_WHITE}%-26s${RST}  %s\n" \
        "-v, --version"          "Show script version" \
        "-h, --help"             "Show this help message" \
        "--list=manager"         "All package managers + availability" \
        "--list=tools"           "All tools in the TOOLS array" \
        "--list=installed"       "Only tools that are currently installed" \
        "--list=categories"      "Tools grouped by category (Dev/Fun/Min…)" \
        "--install=<name>"       "Install a tool non-interactively (e.g. git)" \
        "--uninstall=<name>"     "Uninstall a tool non-interactively" \
        "--log"                  "Print last 20 lines of install.log" \
        "--log=<n>"              "Print last N lines of install.log" \
        "--reset"                "Clear all saved preferences (non-interactive)"
    echo ""
    echo -e "   [*] Examples${RST}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${RST}"
    echo -e "  ${DIM}\$${RST} ./main.sh ${DIM}                       -- Interactive mode${RST}"
    echo -e "  ${DIM}\$${RST} ./main.sh ${BOLD_WHITE}--install=git${DIM}         -- Install git silently${RST}"
    echo -e "  ${DIM}\$${RST} ./main.sh ${BOLD_WHITE}--list=installed${DIM}      -- See what's installed${RST}"
    echo -e "  ${DIM}\$${RST} ./main.sh ${BOLD_WHITE}--list=categories${DIM}     -- Browse tools by category${RST}"
    echo -e "  ${DIM}\$${RST} ./main.sh ${BOLD_WHITE}--log=50${DIM}              -- Last 50 log lines${RST}"
    echo -e "  ${DIM}\$${RST} ./main.sh ${BOLD_WHITE}--reset${DIM}               -- Wipe saved preferences${RST}"
    echo ""
}

_flag_list_tools() {

    echo ""
    # ── Header ─────────────────────────────
    echo -e "${BOLD}${OPTION} [*] Available Tools for install ${RST}"
    echo ""
    
    # ── Table ─────────────────────────────
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
    
    # ── Summary ───────────────────────────
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${RST}"
    echo -e "  ${DIM}Total:${RST}  ${BOLD_WHITE}${#TOOLS[@]}${RST} tools available"
    echo ""
}
# --list=manager : shows all known package managers, their status and OS support
_flag_list_manager() {
    # ── OS/platform detection ─────────────────
    local detected_os="Unknown"
    local detected_pm
    detected_pm="$(detect_pkg_manager)"

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

    # ── Manager registry ──────────────────────
    # Format: id|display_name|platform|check_cmd
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
        "BSD-pkg|pkg (FreeBSD)|FreeBSD|pkg"
        "pkg_add|pkg_add|OpenBSD|pkg_add"
        "winget|winget|Windows|winget.exe"
        "choco|choco|Windows|choco.exe"
        "scoop|scoop|Windows|scoop"
        "flatpak|flatpak|Linux|flatpak"
        "snap|snap|Linux|snap"
    )

    # ── Header ───────────────────────────────
    echo ""
    echo -e "${OPTION} [*] ProjectR — Supported Package Managers ${RST}"
    echo ""
    echo -e "  ${DIM}List of all package managers known to ProjectR."
    echo -e "  Legend:  ${OPTION}✔${RST} = available, ${ERROR}✘${RST} = not found,  ${OPTION}★${RST} = primary${RST}"
    echo ""

    # ── Dynamic column widths ────────────────
    local max_name=15   # "Package Manager"
    local max_os=12     # "Platform"
    for entry in "${managers[@]}"; do
        IFS="|" read -r id display platform _ <<< "$entry"
        (( ${#display} > max_name )) && max_name=${#display}
        (( ${#platform} > max_os )) && max_os=${#platform}
    done
    # Minimum widths
    (( max_name < 15 )) && max_name=15
    (( max_os < 12 )) && max_os=12

    # ── Table header ─────────────────────────
    printf "  ${BOLD_WHITE}%-${max_name}s  %-6s  %-${max_os}s${RST}\n" \
        "Package Manager" "Avail." "Platform"
    printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 $(( max_name + 7 + max_os + 2 ))))"

    # ── Table rows ───────────────────────────
local available_list=()
for entry in "${managers[@]}"; do
    IFS="|" read -r id display platform check_cmd <<< "$entry"

    # Force FreeBSD pkg to be unavailable on Termux (Termux has its own `pkg`)
    local force_unavailable=0
    [[ "$detected_os" == "Termux (Android)" && "$id" == "BSD-pkg" ]] && force_unavailable=1

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

    printf "  ${BOLD_WHITE}%-${max_name}s${RST}  ${icon_color}%-6s${RST}  ${DIM}%-${max_os}s${RST}%s\n" \
        "$display" "$icon" "$platform" "$marker"
done

    # ── Footer ───────────────────────────────
    echo ""
    printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 $(( max_name + 7 + max_os + 2 ))))"
    echo -e "  ${INFO}Detected OS :${RST}  ${BOLD_WHITE}${detected_os}${RST}"
    echo -e "  ${INFO}Primary PM  :${RST}  ${OPTION} ${detected_pm}${RST}"

    # Show other available managers (exclude the primary)
    local extra=()
    for m in "${available_list[@]}"; do
        [[ "$m" != "$detected_pm" ]] && extra+=("$m")
    done
    if [ ${#extra[@]} -gt 0 ]; then
        echo -e "  ${INFO}Also found  :${RST}  ${BOLD_WHITE}${extra[*]}${RST}"
    fi
    echo ""
}
# ── --list=installed ──────────────────────────────────────────────────────────
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

# ── --list=categories ─────────────────────────────────────────────────────────
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

# ── --log / --log=N ───────────────────────────────────────────────────────────
_flag_log() {
    local lines="${1:-20}"
    # LOG_FILE is defined in logging.sh — but flags run before it's sourced,
    # so we hardcode the same path here to stay independent
    local log_path="log/install.log"

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

# ── --reset ───────────────────────────────────────────────────────────────────
_flag_reset() {
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
        echo -e "  ${DIM}Config file is already empty.${RST}"
        echo ""
        return
    fi

    echo -e "  ${INFO}Clearing ${BOLD_WHITE}${line_count}${RST}${INFO} saved preference(s):${RST}"
    echo ""
    while IFS= read -r line; do
        echo -e "    ${DIM}✘  ${line}${RST}"
    done < "$config_path"
    echo ""

    > "$config_path"
    echo -e "  ${OPTION}[✓] All preferences cleared.${RST}"
    echo ""
}

# ── --install=<name> ──────────────────────────────────────────────────────────
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
        exit 1
    fi

    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$matched_entry"

    # Already installed?
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "  ${OPTION}[✓] ${name} is already installed — nothing to do.${RST}"
        echo ""
        exit 0
    fi

    # special type tools can't run non-interactively (they prompt the user)
    if [[ "$type" == "special" ]]; then
        echo -e "  ${ERROR}[!] '${name}' uses an interactive installer and can't be run via flag.${RST}"
        echo -e "  ${DIM}Launch the script normally and select [${num}] from the menu.${RST}"
        echo ""
        exit 1
    fi

    # Source everything needed for actual installation
    # (flags normally run before the full source block)
    source lib/core/progress_bar.sh
    source lib/core/spinner.sh
    source lib/core/logging.sh

    INSTALLED_PKGS=()
    SKIPPED_PKGS=()
    FAILED_PKGS=()

    case "$type" in
        pkg) install_pkg "$cmd" "$pkg" "$name" ;;
        pip) install_lang "pip" "$pkg" "$name" "$cmd" ;;
    esac

    echo ""
}

# ── --uninstall=<name> ────────────────────────────────────────────────────────
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
        exit 1
    fi

    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$matched_entry"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "  ${DIM}[*] ${name} is not installed — nothing to do.${RST}"
        echo ""
        exit 0
    fi

    source lib/core/spinner.sh
    source lib/core/logging.sh
    export NON_INTERACTIVE=1
    case "$type" in
        pkg|special) uninstall_pkg "$cmd" "$pkg" "$name" ;;
        pip)         uninstall_lang "pip" "$cmd" "$name" ;;
    esac
    unset NON_INTERACTIVE
    echo ""
}
