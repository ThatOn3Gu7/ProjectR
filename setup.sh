#!/usr/bin/env bash
set -euo pipefail

# ProjectR command installer
# Copies the repo to a hidden user-level app directory and creates a `project`
# launcher so ProjectR can be run from any working directory.
#
# Supports two modes:
#   1. LOCAL  — run from a cloned ProjectR checkout (original behaviour).
#   2. REMOTE — piped through curl/wget with no prior clone required:
#        curl -fsSL https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | bash
#        wget -qO- https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | bash
#
# In remote mode, setup clones ProjectR into $XDG_DATA_HOME/projectr (or
# ~/.local/share/projectr) and then runs the normal local setup against that
# fresh clone.
#
# An interactive setup menu is shown by default. Pass --no-menu to skip it
# and use the defaults or flag/env overrides directly.

PROJECTR_REPO_URL="${PROJECTR_REPO_URL:-https://github.com/Thaton3gu7/ProjectR.git}"
PROJECT_NAME="ProjectR"
COMMAND_NAME="${PROJECTR_COMMAND_NAME:-project}"
DEFAULT_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/projectr"
DEFAULT_BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
INSTALL_DIR="${PROJECTR_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
BIN_DIR="${PROJECTR_BIN_DIR:-$DEFAULT_BIN_DIR}"
ADD_PATH=0
REMOTE_MODE=0
SHOW_MENU=1

#  Colours (self-contained) 
RST='\e[0m'
BOLD='\e[1m'
DIM='\e[2m'
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
CYAN='\e[0;36m'
MAGENTA='\e[0;35m'
WHITE='\e[0;37m'
BOLD_RED='\e[1;31m'
BOLD_GREEN='\e[1;32m'
BOLD_YELLOW='\e[1;33m'
BOLD_BLUE='\e[1;34m'
BOLD_CYAN='\e[1;36m'
BOLD_MAGENTA='\e[1;35m'
BOLD_WHITE='\e[1;37m'
BRIGHT_BLACK='\e[0;90m'
BRIGHT_GREEN='\e[0;92m'
BRIGHT_YELLOW='\e[0;93m'
BRIGHT_CYAN='\e[0;96m'
BRIGHT_MAGENTA='\e[0;95m'
BRIGHT_WHITE='\e[0;97m'
BOLD_BRIGHT_GREEN='\e[1;92m'
BOLD_BRIGHT_YELLOW='\e[1;93m'
BOLD_BRIGHT_RED='\e[1;91m'
BOLD_BRIGHT_CYAN='\e[1;96m'
BOLD_BRIGHT_MAGENTA='\e[1;95m'
BOLD_BRIGHT_WHITE='\e[1;97m'
BG_GREEN='\e[42m'
BG_CYAN='\e[46m'
BG_RED='\e[41m'

# Semantic aliases matching ProjectR's theme
INFO="${BOLD_BRIGHT_YELLOW}"
OPTION="${BOLD_BRIGHT_GREEN}"
ERROR="${BOLD_BRIGHT_RED}"
BARR="${BRIGHT_MAGENTA}"
ACCENT="${BOLD_BRIGHT_CYAN}"

#  Detect remote (piped) mode 
_detect_source_dir() {
    local candidate="${BASH_SOURCE[0]:-}"
    if [[ -n "$candidate" ]]; then
        candidate="$(cd "$(dirname "$candidate")" 2>/dev/null && pwd -P)" || candidate=""
    fi

    if [[ -n "$candidate" && -f "$candidate/main.sh" && -d "$candidate/lib" ]]; then
        SOURCE_DIR="$candidate"
        REMOTE_MODE=0
    else
        REMOTE_MODE=1
        SOURCE_DIR=""
    fi
}

_detect_source_dir

# Helpers 
info()    { printf "${ACCENT}[*]${RST} %s\n" "$*"; }
success() { printf "${OPTION}[✓]${RST} %s\n" "$*"; }
warn()    { printf "${INFO}[!]${RST} %s\n" "$*" >&2; }
fail()    { printf "${ERROR}[✗]${RST} %s\n" "$*" >&2; exit 1; }

# Read a line from the user. When stdin is a pipe (curl | bash), we must read
# from /dev/tty directly so user keyboard input actually reaches us.
_read_input() {
    local prompt_text="$1" var_name="$2"
    if [[ -t 0 ]]; then
        # stdin is a terminal — normal read
        printf "%b" "$prompt_text"
        read -r "$var_name"
    else
        # stdin is a pipe — read from /dev/tty
        printf "%b" "$prompt_text" >/dev/tty
        read -r "$var_name" </dev/tty
    fi
}

# Read a single character (for menu navigation)
_read_char() {
    local var_name="$1"
    if [[ -t 0 ]]; then
        read -r -n 1 "$var_name"
    else
        read -r -n 1 "$var_name" </dev/tty
    fi
}

# Safe tput
safe_tput() { command -v tput >/dev/null 2>&1 && tput "$@" 2>/dev/null || true; }

_term_cols() {
    local cols
    cols=$(safe_tput cols)
    [[ -z "$cols" || ! "$cols" =~ ^[0-9]+$ ]] && cols="${COLUMNS:-80}"
    [[ -z "$cols" || ! "$cols" =~ ^[0-9]+$ ]] && cols=80
    (( cols < 1 )) && cols=80
    printf '%s' "$cols"
}

_center_pad() {
    local text_len="$1"
    local cols
    cols=$(_term_cols)
    local pad=$(( (cols - text_len) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s' "$pad" ""
}

_draw_line() {
    local char="${1:-─}" width="${2:-60}"
    printf '%0.s'"$char" $(seq 1 "$width")
}

usage() {
    cat <<USAGE
$PROJECT_NAME setup

Usage: bash setup.sh [options]

  One-shot remote install (no prior clone needed):
    curl -fsSL https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | bash
    wget -qO- https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | bash

Options:
  --command=<name>       Launcher command name (default: project)
  --install-dir=<path>   Hidden install location (default: ~/.local/share/projectr)
  --bin-dir=<path>       Directory for launcher (default: ~/.local/bin)
  --add-path             Add the bin dir to common shell rc files when missing
  --no-menu              Skip interactive menu, use defaults/flags directly
  -h, --help             Show this help

Environment overrides:
  PROJECTR_COMMAND_NAME  Same as --command
  PROJECTR_INSTALL_DIR   Same as --install-dir
  PROJECTR_BIN_DIR       Same as --bin-dir
  PROJECTR_REPO_URL      Git remote to clone (default: $PROJECTR_REPO_URL)

Examples:
  bash setup.sh               - Launch interactive setup menu
  bash setup.sh --no-menu     - Install with defaults (no menu)
  project                     - Run interactive mode via launcher name
  project --help              - To see this help menu
  project --install=git       - Installs git non-interactively
  project --self-update       - Updates ProjectR via github
USAGE
}

expand_path() {
    local path="$1"
    case "$path" in
        '~') printf '%s\n' "$HOME" ;;
        '~/'*) printf '%s/%s\n' "$HOME" "${path#~/}" ;;
        *) printf '%s\n' "$path" ;;
    esac
}

require_commands() {
    local missing=()
    local cmd
    for cmd in tar mktemp mkdir rm mv chmod dirname basename; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing required setup command(s): ${missing[*]}"
    fi
}

ensure_dir_with_fallback() {
    local requested="$1"
    local fallback="$2"
    local label="$3"

    if mkdir -p "$requested" 2>/dev/null; then
        printf '%s\n' "$requested"
        return 0
    fi
    warn "Could not create $label directory: $requested"
    warn "Falling back to: $fallback"
    if mkdir -p "$fallback" 2>/dev/null; then
        printf '%s\n' "$fallback"
        return 0
    fi
    fail "Could not create $label directory at either '$requested' or '$fallback'."
}

#  Interactive Setup Menu 

_show_banner() {
    clear 2>/dev/null || true
    echo "" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  ╭──────────────────────────────────────────────────────────────────╮${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}                                                                  ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}   ${BOLD_BRIGHT_WHITE} ██████╗ ██████╗  ██████╗      ██╗███████╗ ██████╗████████╗${RST}    ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}   ${BOLD_BRIGHT_WHITE} ██╔══██╗██╔══██╗██╔═══██╗     ██║██╔════╝██╔════╝╚══██╔══╝${RST}    ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}   ${BOLD_BRIGHT_WHITE} ██████╔╝██████╔╝██║   ██║     ██║█████╗  ██║        ██║   ${RST}    ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}   ${BOLD_BRIGHT_WHITE} ██╔═══╝ ██╔══██╗██║   ██║██   ██║██╔══╝  ██║        ██║   ${RST}    ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}   ${BOLD_BRIGHT_WHITE} ██║     ██║  ██║╚██████╔╝╚█████╔╝███████╗╚██████╗   ██║   ${RST}    ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}   ${BOLD_BRIGHT_WHITE} ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚══════╝ ╚═════╝   ╚═╝   ${RST}    ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}                                                                  ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  │${RST}  ${DIM}                   Setup Wizard  •  v1.0                      ${RST}  ${BOLD_BRIGHT_CYAN}│${RST}" >&2
    echo -e "${BOLD_BRIGHT_CYAN}  ╰──────────────────────────────────────────────────────────────────╯${RST}" >&2
    echo "" >&2
}

_show_current_config() {
    local mode_label
    if (( REMOTE_MODE )); then mode_label="Remote (curl/wget)"; else mode_label="Local (cloned repo)"; fi
    local path_label
    if (( REMOTE_MODE )); then path_label="Repo URL"; else path_label="Source dir"; fi
    local path_value
    if (( REMOTE_MODE )); then path_value="$PROJECTR_REPO_URL"; else path_value="$SOURCE_DIR"; fi
    local add_path_val
    if (( ADD_PATH )); then add_path_val="Yes"; else add_path_val="No"; fi

    echo -e "${BARR}  ╭──────────────────────────────────────────────────────────────────╮${RST}" >&2
    echo -e "${BARR}  │${RST}  ${BOLD_BRIGHT_YELLOW}⚙  Current Configuration${RST}                                        ${BARR}│${RST}" >&2
    echo -e "${BARR}  ├──────────────────────────────────────────────────────────────────┤${RST}" >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-14s${RST}  ${BRIGHT_BLACK}│${RST}   ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Command name"  "$COMMAND_NAME"   >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-14s${RST}  ${BRIGHT_BLACK}│${RST}   ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Install dir"   "$INSTALL_DIR"    >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-14s${RST}  ${BRIGHT_BLACK}│${RST}   ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Bin dir"       "$BIN_DIR"        >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-14s${RST}  ${BRIGHT_BLACK}│${RST}   ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Add to PATH"   "$add_path_val"   >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-14s${RST}  ${BRIGHT_BLACK}│${RST}   ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "$path_label"   "$path_value"     >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-14s${RST}  ${BRIGHT_BLACK}│${RST}   ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Mode"          "$mode_label"     >&2
    echo -e "${BARR}  ╰──────────────────────────────────────────────────────────────────╯${RST}" >&2
    echo "" >&2
}

_show_menu_options() {
    echo -e "${BARR}  ╭──────────────────────────────────────────────────────────────────╮${RST}" >&2
    echo -e "${BARR}  │${RST}  ${BOLD_BRIGHT_YELLOW}☰  Setup Options${RST}                                                ${BARR}│${RST}" >&2
    echo -e "${BARR}  ├──────────────────────────────────────────────────────────────────┤${RST}" >&2
    echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}1${OPTION}]${RST}  Change launcher command name    ${DIM}(currently: ${COMMAND_NAME})       ${BARR}│${RST}" >&2
    echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}2${OPTION}]${RST}  Change install directory        ${DIM}(where files live)         ${BARR}│${RST}" >&2
    echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}3${OPTION}]${RST}  Change bin directory            ${DIM}(where launcher goes)      ${BARR}│${RST}" >&2
    echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}4${OPTION}]${RST}  Toggle add-to-PATH              ${DIM}(currently: $(if (( ADD_PATH )); then echo 'ON'; else echo 'OFF'; fi))           ${BARR}│${RST}" >&2
    if (( REMOTE_MODE )); then
        echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}5${OPTION}]${RST}  Change repo URL                 ${DIM}(for remote clone)               ${BARR}│${RST}" >&2
    fi
    echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}r${OPTION}]${RST}  Reset all to defaults           ${DIM}(setup with defaults)      ${BARR}│${RST}" >&2
    echo -e "${BARR}  ├──────────────────────────────────────────────────────────────────┤${RST}" >&2
    echo -e "${BARR}  │${RST}  ${ACCENT}[${BOLD_BRIGHT_WHITE}i${ACCENT}]${RST}  ${BOLD_BRIGHT_GREEN}✓  Install${RST} with current settings                           ${BARR}│${RST}" >&2
    echo -e "${BARR}  │${RST}  ${ERROR}[${BOLD_BRIGHT_WHITE}q${ERROR}]${RST}  ${BOLD_BRIGHT_RED}✗  Quit${RST}    without installing                              ${BARR}│${RST}" >&2
    echo -e "${BARR}  ╰──────────────────────────────────────────────────────────────────╯${RST}" >&2
    echo "" >&2
}

_validate_command_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo -e "  ${ERROR}[✗] Invalid command name: '${name}'. Only letters, numbers, dots, hyphens, underscores.${RST}" >&2
        return 1
    fi
    return 0
}

_validate_path() {
    local path="$1" label="$2"
    path="$(expand_path "$path")"
    if [[ -z "$path" ]]; then
        echo -e "  ${ERROR}[✗] ${label} cannot be empty.${RST}" >&2
        return 1
    fi
    printf '%s' "$path"
    return 0
}

_prompt_change_command() {
    local new_name
    echo "" >&2
    echo -e "  ${INFO}Current command name: ${BOLD_WHITE}${COMMAND_NAME}${RST}" >&2
    echo -e "  ${DIM}This is the name you'll type to run ProjectR (e.g. 'project', 'projectr', 'pr')${RST}" >&2
    _read_input "  ${ACCENT}[?]${RST} New command name ${DIM}(Enter to keep '${COMMAND_NAME}')${RST}: " new_name
    echo "" >&2
    if [[ -n "$new_name" ]]; then
        new_name="$(basename "$new_name")"
        if _validate_command_name "$new_name"; then
            COMMAND_NAME="$new_name"
            echo -e "  ${OPTION}[✓] Command name set to: ${BOLD_WHITE}${COMMAND_NAME}${RST}" >&2
        fi
    else
        echo -e "  ${DIM}[*] Keeping: ${COMMAND_NAME}${RST}" >&2
    fi
    sleep 1
}

_prompt_change_install_dir() {
    local new_dir validated
    echo "" >&2
    echo -e "  ${INFO}Current install directory: ${BOLD_WHITE}${INSTALL_DIR}${RST}" >&2
    echo -e "  ${DIM}This is where all ProjectR files (scripts, lib, tools.d, etc.) will be stored.${RST}" >&2
    _read_input "  ${ACCENT}[?]${RST} New install dir ${DIM}(Enter to keep current)${RST}: " new_dir
    echo "" >&2
    if [[ -n "$new_dir" ]]; then
        validated="$(_validate_path "$new_dir" "Install directory")" || return 0
        INSTALL_DIR="$validated"
        echo -e "  ${OPTION}[✓] Install directory set to: ${BOLD_WHITE}${INSTALL_DIR}${RST}" >&2
    else
        echo -e "  ${DIM}[*] Keeping: ${INSTALL_DIR}${RST}" >&2
    fi
    sleep 1
}

_prompt_change_bin_dir() {
    local new_dir validated
    echo "" >&2
    echo -e "  ${INFO}Current bin directory: ${BOLD_WHITE}${BIN_DIR}${RST}" >&2
    echo -e "  ${DIM}This is where the launcher script will be placed (must be in PATH or --add-path).${RST}" >&2
    _read_input "  ${ACCENT}[?]${RST} New bin dir ${DIM}(Enter to keep current)${RST}: " new_dir
    echo "" >&2
    if [[ -n "$new_dir" ]]; then
        validated="$(_validate_path "$new_dir" "Bin directory")" || return 0
        BIN_DIR="$validated"
        echo -e "  ${OPTION}[✓] Bin directory set to: ${BOLD_WHITE}${BIN_DIR}${RST}" >&2
    else
        echo -e "  ${DIM}[*] Keeping: ${BIN_DIR}${RST}" >&2
    fi
    sleep 1
}

_toggle_add_path() {
    if (( ADD_PATH )); then
        ADD_PATH=0
        echo -e "  ${INFO}[*] Add-to-PATH is now: ${BOLD_WHITE}OFF${RST}" >&2
    else
        ADD_PATH=1
        echo -e "  ${OPTION}[✓] Add-to-PATH is now: ${BOLD_WHITE}ON${RST}" >&2
    fi
    echo -e "  ${DIM}When ON, setup will add the bin dir to .bashrc, .zshrc, and .profile${RST}" >&2
    sleep 1
}

_prompt_change_repo_url() {
    local new_url
    echo "" >&2
    echo -e "  ${INFO}Current repo URL: ${BOLD_WHITE}${PROJECTR_REPO_URL}${RST}" >&2
    echo -e "  ${DIM}Change this if you're using a fork or a private mirror.${RST}" >&2
    _read_input "  ${ACCENT}[?]${RST} New repo URL ${DIM}(Enter to keep current)${RST}: " new_url
    echo "" >&2
    if [[ -n "$new_url" ]]; then
        PROJECTR_REPO_URL="$new_url"
        echo -e "  ${OPTION}[✓] Repo URL set to: ${BOLD_WHITE}${PROJECTR_REPO_URL}${RST}" >&2
    else
        echo -e "  ${DIM}[*] Keeping: ${PROJECTR_REPO_URL}${RST}" >&2
    fi
    sleep 1
}

_reset_defaults() {
    COMMAND_NAME="${PROJECTR_COMMAND_NAME:-project}"
    INSTALL_DIR="${PROJECTR_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
    BIN_DIR="${PROJECTR_BIN_DIR:-$DEFAULT_BIN_DIR}"
    ADD_PATH=0
    PROJECTR_REPO_URL="${PROJECTR_REPO_URL_ORIGINAL:-https://github.com/Thaton3gu7/ProjectR.git}"
    echo -e "  ${OPTION}[✓] All settings reset to defaults.${RST}" >&2
    sleep 1
}

_confirm_install() {
    echo "" >&2
    echo -e "${BARR}  ╭──────────────────────────────────────────────────────────────────╮${RST}" >&2
    echo -e "${BARR}  │${RST}  ${BOLD_BRIGHT_YELLOW}▶  Ready to Install${RST}                                               ${BARR}│${RST}" >&2
    echo -e "${BARR}  ├──────────────────────────────────────────────────────────────────┤${RST}" >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-12s${RST}  ${BRIGHT_BLACK}│${RST}  ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Command"    "$COMMAND_NAME"           >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-12s${RST}  ${BRIGHT_BLACK}│${RST}  ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Files"      "$INSTALL_DIR"            >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-12s${RST}  ${BRIGHT_BLACK}│${RST}  ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Launcher"   "$BIN_DIR/$COMMAND_NAME"  >&2
    printf  "${BARR}  │${RST}  ${OPTION}%-12s${RST}  ${BRIGHT_BLACK}│${RST}  ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Add PATH"   "$(if (( ADD_PATH )); then echo 'Yes'; else echo 'No'; fi)" >&2
    if (( REMOTE_MODE )); then
        printf  "${BARR}  │${RST}  ${OPTION}%-12s${RST}  ${BRIGHT_BLACK}│${RST}  ${BOLD_WHITE}%-44s${RST}${BARR}│${RST}\n" "Repo"   "$PROJECTR_REPO_URL" >&2
    fi
    echo -e "${BARR}  ╰──────────────────────────────────────────────────────────────────╯${RST}" >&2
    echo "" >&2

    local confirm
    _read_input "  ${ACCENT}[?]${RST} Proceed with installation? ${DIM}[Y/n]${RST}: " confirm
    echo "" >&2
    confirm="${confirm:-y}"
    confirm="${confirm,,}"
    case "$confirm" in
        y|yes|yeah|yep) return 0 ;;
        *) return 1 ;;
    esac
}

# Main interactive menu loop
_run_setup_menu() {
    # Save original repo URL for reset
    PROJECTR_REPO_URL_ORIGINAL="$PROJECTR_REPO_URL"

    while true; do
        _show_banner
        _show_current_config
        _show_menu_options

        local choice
        _read_input "  ${BG_GREEN}${BOLD_WHITE} [*] Choose an option ${RST} : " choice
        echo "" >&2

        case "$choice" in
            1) _prompt_change_command ;;
            2) _prompt_change_install_dir ;;
            3) _prompt_change_bin_dir ;;
            4) _toggle_add_path ;;
            5)
                if (( REMOTE_MODE )); then
                    _prompt_change_repo_url
                else
                    echo -e "  ${ERROR}[!] Invalid option: $choice${RST}" >&2
                    sleep 1
                fi
                ;;
            r|R) _reset_defaults ;;
            i|I)
                if _confirm_install; then
                    echo -e "  ${OPTION}[✓] Starting installation...${RST}" >&2
                    sleep 1
                    return 0
                else
                    echo -e "  ${INFO}[*] Installation cancelled. Returning to menu...${RST}" >&2
                    sleep 1
                fi
                ;;
            q|Q)
                echo "" >&2
                echo -e "  ${INFO}" >&2
                echo -e "  ╭──────────────────────────────────────────────╮" >&2
                echo -e "  │  Setup cancelled. No changes were made.      │" >&2
                echo -e "  │  Run setup.sh again when you're ready.       │" >&2
                echo -e "  ╰──────────────────────────────────────────────╯" >&2
                echo -e "  ${RST}" >&2
                exit 0
                ;;
            h|H)
                usage >&2
                echo "" >&2
                _read_input "  ${DIM}[press Enter to return to menu]${RST}" _discard
                ;;
            *)
                echo -e "  ${ERROR}[!] Invalid option: '$choice'. Please select a valid option.${RST}" >&2
                sleep 1
                ;;
        esac
    done
}

# ======================= Remote clone functions ============================
clone_project_remote() {
    info "Remote mode detected — no local checkout found."
    info "Cloning $PROJECT_NAME from $PROJECTR_REPO_URL ..."

    if command -v git >/dev/null 2>&1; then
        _clone_with_git
    elif command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        _clone_with_archive
    else
        fail "Neither git nor curl/wget are available. Install git and retry."
    fi
}

_clone_with_git() {
    local clone_target="$INSTALL_DIR"
    local backup=""

    if [[ -d "$clone_target/.git" ]]; then
        info "Existing clone found at $clone_target — pulling latest changes ..."
        git -C "$clone_target" pull --ff-only 2>/dev/null             || warn "Fast-forward pull failed; continuing with existing checkout."
    else
        if [[ -d "$clone_target" ]]; then
            backup="${clone_target}.bak.$$"
            mv "$clone_target" "$backup" || fail "Could not move old install directory."
        fi

        mkdir -p "$(dirname "$clone_target")" 2>/dev/null || true
        if ! git clone --depth 1 "$PROJECTR_REPO_URL" "$clone_target"; then
            if [[ -n "$backup" && -d "$backup" ]]; then
                rm -rf "$clone_target" 2>/dev/null || true
                mv "$backup" "$clone_target" 2>/dev/null || true
            fi
            fail "git clone failed. Check your network and the repo URL. Previous install was restored if it existed."
        fi

        if [[ -n "$backup" ]]; then
            rm -rf "$backup"
        fi
    fi

    SOURCE_DIR="$clone_target"
}

_clone_with_archive() {
    local archive_url="${PROJECTR_REPO_URL%.git}"
    archive_url="${archive_url}/archive/refs/heads/master.tar.gz"
    local tmp_archive tmp_extract backup=""

    tmp_archive="$(mktemp "${TMPDIR:-/tmp}/projectr-archive.XXXXXX.tar.gz")"
    tmp_extract="$(mktemp -d "${TMPDIR:-/tmp}/projectr-extract.XXXXXX")"
    trap "rm -rf '$tmp_archive' '$tmp_extract'" EXIT

    info "Downloading $PROJECT_NAME archive ..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$tmp_archive" "$archive_url"             || fail "Failed to download archive from $archive_url"
    else
        wget -qO "$tmp_archive" "$archive_url"             || fail "Failed to download archive from $archive_url"
    fi

    tar -xzf "$tmp_archive" -C "$tmp_extract" --strip-components=1         || fail "Failed to extract archive."

    if [[ -d "$INSTALL_DIR" ]]; then
        backup="${INSTALL_DIR}.bak.$$"
        mv "$INSTALL_DIR" "$backup" || fail "Could not move old install directory."
    fi

    mkdir -p "$(dirname "$INSTALL_DIR")" 2>/dev/null || true
    if ! mv "$tmp_extract" "$INSTALL_DIR"; then
        if [[ -n "$backup" && -d "$backup" ]]; then
            rm -rf "$INSTALL_DIR" 2>/dev/null || true
            mv "$backup" "$INSTALL_DIR" 2>/dev/null || true
        fi
        fail "Could not move extracted files into $INSTALL_DIR. Previous install was restored if it existed."
    fi

    if [[ -n "$backup" ]]; then
        rm -rf "$backup"
    fi

    rm -f "$tmp_archive"
    trap - EXIT

    SOURCE_DIR="$INSTALL_DIR"
}

# ======================= Install functions =================================
write_metadata() {
    local metadata_file="$INSTALL_DIR/.projectr-install"
    {
        printf 'PROJECTR_SOURCE_DIR=%q\n' "$SOURCE_DIR"
        printf 'PROJECTR_INSTALL_DIR=%q\n' "$INSTALL_DIR"
        printf 'PROJECTR_BIN_DIR=%q\n' "$BIN_DIR"
        printf 'PROJECTR_COMMAND_NAME=%q\n' "$COMMAND_NAME"
        printf 'PROJECTR_INSTALLED_AT=%q\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
        printf 'PROJECTR_REMOTE_MODE=%q\n' "$REMOTE_MODE"
    } > "$metadata_file"
}

copy_project() {
    local install_parent tmp_dir backup_dir
    install_parent="$(dirname "$INSTALL_DIR")"

    if [[ "$SOURCE_DIR" == "$(cd "$install_parent" && pwd -P)/$(basename "$INSTALL_DIR")" ]]; then
        info "Setup is running from the installed copy; skipping app-file refresh."
        return 0
    fi

    tmp_dir="$(mktemp -d "${install_parent}/projectr.XXXXXX")"
    backup_dir=""

    cleanup_tmp() { rm -rf "$tmp_dir"; }
    trap cleanup_tmp EXIT

    info "Copying app files from: $SOURCE_DIR"
    tar -C "$SOURCE_DIR" \
        --exclude='.git' \
        --exclude='./log/*.log' \
        --exclude='./log/*.tmp' \
        -cf - . | tar -C "$tmp_dir" -xf -

    if [[ -d "$INSTALL_DIR" ]]; then
        backup_dir="${INSTALL_DIR}.bak.$$"
        mv "$INSTALL_DIR" "$backup_dir" || fail "Could not move old install out of the way: $INSTALL_DIR"
    fi

    if mv "$tmp_dir" "$INSTALL_DIR"; then
        trap - EXIT
        if [[ -n "$backup_dir" ]]; then
            rm -rf "$backup_dir"
        fi
        return 0
    else
        warn "Install refresh failed while moving new files into place."
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
        [[ -n "$backup_dir" ]] && mv "$backup_dir" "$INSTALL_DIR" 2>/dev/null || true
        fail "Install refresh failed; previous install was restored if it existed."
    fi
}

write_launcher() {
    local launcher="$BIN_DIR/$COMMAND_NAME"

    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        printf 'PROJECTR_HOME=%q\n' "$INSTALL_DIR"
        printf 'PROJECTR_SOURCE_DIR=%q\n' "$SOURCE_DIR"
        printf 'PROJECTR_BIN_DIR=%q\n' "$BIN_DIR"
        printf 'PROJECTR_COMMAND_NAME=%q\n' "$COMMAND_NAME"
        echo 'export PROJECTR_LAUNCHER_NAME="$(basename "$0")"'
        echo ''
        echo 'case "${1:-}" in'
        echo '  --self-update|--projectr-update)'
        echo '    if [[ -d "$PROJECTR_SOURCE_DIR/.git" ]]; then'
        echo '      echo "[*] Pulling latest changes ..."'
        echo '      git -C "$PROJECTR_SOURCE_DIR" pull --ff-only || { echo "[!] Pull failed." >&2; exit 1; }'
        echo '    fi'
        echo '    if [[ -f "$PROJECTR_SOURCE_DIR/setup.sh" ]]; then'
        echo '      exec bash "$PROJECTR_SOURCE_DIR/setup.sh" --no-menu --command="$PROJECTR_COMMAND_NAME" --install-dir="$PROJECTR_HOME" --bin-dir="$PROJECTR_BIN_DIR"'
        echo '    fi'
        echo '    echo "[!] Original ProjectR checkout was not found: $PROJECTR_SOURCE_DIR" >&2'
        echo '    echo "    Re-clone ProjectR or rerun setup.sh from a valid checkout." >&2'
        echo '    exit 1'
        echo '    ;;'
        echo '  --setup-info|--projectr-info)'
        echo '    echo "ProjectR launcher: $PROJECTR_LAUNCHER_NAME"'
        echo '    echo "Installed app:     $PROJECTR_HOME"'
        echo '    echo "Original checkout: $PROJECTR_SOURCE_DIR"'
        echo '    echo "Launcher dir:      $PROJECTR_BIN_DIR"'
        echo '    exit 0'
        echo '    ;;'
        echo 'esac'
        echo ''
        echo 'exec bash "$PROJECTR_HOME/main.sh" "$@"'
    } > "$launcher" || fail "Could not write launcher: $launcher"

    chmod +x "$launcher" || fail "Could not make launcher executable: $launcher"
}

maybe_add_path() {
    local do_add="$ADD_PATH"

    # In remote mode, always try to add PATH (user expects turnkey install)
    if (( REMOTE_MODE )); then
        do_add=1
    fi

    if (( ! do_add )) || [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        return 0
    fi

    local rc marker
    marker="export PATH=\"$BIN_DIR:\$PATH\""
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        [[ -e "$rc" || "$rc" == "$HOME/.bashrc" ]] || continue
        touch "$rc" || { warn "Could not update shell rc file: $rc"; continue; }
        if ! grep -F "$marker" "$rc" >/dev/null 2>&1; then
            printf '\n# ProjectR launcher\n%s\n' "$marker" >> "$rc" || warn "Could not append PATH update to: $rc"
        fi
    done
}

_show_success() {
    echo "" >&2
    echo -e "${BOLD_BRIGHT_CYAN}" >&2
    echo "   ╭──────────────────────────────────────────────────────────╮" >&2
    echo "   │                                                          │" >&2
    echo "   │   ✓  ProjectR has been installed successfully!           │" >&2
    echo "   │                                                          │" >&2
    echo "   ╰──────────────────────────────────────────────────────────╯" >&2
    echo -e "${RST}" >&2
    echo "" >&2
    printf "  ${OPTION}  App files${RST} : %s\n" "$INSTALL_DIR" >&2
    printf "  ${OPTION}  Launcher ${RST} : %s\n" "$BIN_DIR/$COMMAND_NAME" >&2
    printf "  ${OPTION}  Source   ${RST} : %s\n" "$SOURCE_DIR" >&2
    echo "" >&2
    echo -e "  ${INFO}Run:${RST}" >&2
    echo -e "      ${BOLD_WHITE}${COMMAND_NAME}${RST}                  ${DIM}# Launch interactive menu${RST}" >&2
    echo -e "      ${BOLD_WHITE}${COMMAND_NAME} --help${RST}            ${DIM}# Show all flags${RST}" >&2
    echo -e "      ${BOLD_WHITE}${COMMAND_NAME} --install=git${RST}     ${DIM}# Install a tool non-interactively${RST}" >&2
    echo -e "      ${BOLD_WHITE}${COMMAND_NAME} --self-update${RST}     ${DIM}# Pull latest changes and refresh${RST}" >&2
    echo -e "      ${BOLD_WHITE}${COMMAND_NAME} --setup-info${RST}      ${DIM}# Show install/source paths${RST}" >&2
    echo "" >&2

    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "  ${INFO}[!] ${BOLD_WHITE}$BIN_DIR${INFO} is not currently in PATH for this shell.${RST}" >&2
        echo -e "      Run this once now:" >&2
        echo -e "          ${BOLD_WHITE}export PATH=\"$BIN_DIR:\$PATH\"${RST}" >&2
        echo "" >&2
        if (( ADD_PATH )) || (( REMOTE_MODE )); then
            echo -e "      ${DIM}Or open a new terminal — your shell rc file has been updated.${RST}" >&2
        else
            echo -e "      ${DIM}Or rerun setup with: ${BOLD_WHITE}bash setup.sh --add-path${RST}" >&2
        fi
        echo "" >&2
    fi
}

# ======================= Parse CLI arguments ===============================
for arg in "$@"; do
    case "$arg" in
        --command=*) COMMAND_NAME="${arg#--command=}" ;;
        --install-dir=*) INSTALL_DIR="${arg#--install-dir=}" ;;
        --bin-dir=*) BIN_DIR="${arg#--bin-dir=}" ;;
        --add-path) ADD_PATH=1 ;;
        --no-menu) SHOW_MENU=0 ;;
        -h|--help) usage; exit 0 ;;
        *) warn "Unknown setup option: $arg"; usage; exit 1 ;;
    esac
done

COMMAND_NAME="$(basename "$COMMAND_NAME")"
INSTALL_DIR="$(expand_path "$INSTALL_DIR")"
BIN_DIR="$(expand_path "$BIN_DIR")"

if [[ ! "$COMMAND_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
    fail "Invalid command name: $COMMAND_NAME"
fi

require_commands

# ======================= Show interactive menu =============================
# The menu is shown when:
#   - No --no-menu flag was passed
#   - We can read from a terminal (either stdin or /dev/tty)
# This works both locally and when piped via curl (reads from /dev/tty).
if (( SHOW_MENU )); then
    # Check if we have access to a terminal for interactive input
    if [[ -t 0 ]] || [[ -e /dev/tty ]]; then
        _run_setup_menu
    else
        info "No terminal available — skipping interactive menu, using defaults."
    fi
fi

# ======================= Run the actual installation =======================

if (( REMOTE_MODE )); then
    INSTALL_PARENT="$(dirname "$INSTALL_DIR")"
    INSTALL_PARENT="$(ensure_dir_with_fallback "$INSTALL_PARENT" "$HOME/.projectr-app" "install parent")"
    if [[ "$INSTALL_PARENT" != "$(dirname "$INSTALL_DIR")" ]]; then
        INSTALL_DIR="$INSTALL_PARENT/projectr"
    fi

    BIN_DIR="$(ensure_dir_with_fallback "$BIN_DIR" "$HOME/bin" "launcher bin")"

    clone_project_remote

    if [[ ! -f "$SOURCE_DIR/main.sh" || ! -d "$SOURCE_DIR/lib" ]]; then
        fail "Clone succeeded but the repository doesn't look like a valid ProjectR checkout."
    fi

    chmod +x "$SOURCE_DIR/main.sh" 2>/dev/null || true
    write_metadata
    write_launcher
    maybe_add_path
    _show_success

    exit 0
fi

# ======================= Local mode ========================================
if [[ ! -f "$SOURCE_DIR/main.sh" || ! -d "$SOURCE_DIR/lib" ]]; then
    fail "setup.sh must be run from a valid ProjectR checkout."
fi

INSTALL_PARENT="$(dirname "$INSTALL_DIR")"
INSTALL_PARENT="$(ensure_dir_with_fallback "$INSTALL_PARENT" "$HOME/.projectr-app" "install parent")"
if [[ "$INSTALL_PARENT" != "$(dirname "$INSTALL_DIR")" ]]; then
    INSTALL_DIR="$INSTALL_PARENT/projectr"
fi

BIN_DIR="$(ensure_dir_with_fallback "$BIN_DIR" "$HOME/bin" "launcher bin")"

copy_project
chmod +x "$INSTALL_DIR/main.sh" 2>/dev/null || warn "Could not mark main.sh executable; launcher will still run it with bash."
write_metadata
write_launcher
maybe_add_path
_show_success