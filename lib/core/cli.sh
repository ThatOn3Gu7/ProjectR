#!/bin/bash
# Shared CLI helpers for ProjectR; dispatch lives in lib/flags/flags.sh.

projectr_disable_color() {
    # Respect the community NO_COLOR convention and clear every colour/style
    # variable used by ProjectR. Keep this list in sync with lib/core/colours.sh.
    export NO_COLOR=1

    local _projectr_colour_var
    for _projectr_colour_var in \
        RST \
        BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE \
        BOLD_BLACK BOLD_RED BOLD_GREEN BOLD_YELLOW BOLD_BLUE BOLD_PURPLE BOLD_CYAN BOLD_WHITE \
        ULINE_BLACK ULINE_RED ULINE_GREEN ULINE_YELLOW ULINE_BLUE ULINE_PURPLE ULINE_CYAN ULINE_WHITE \
        BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_PURPLE BG_CYAN BG_WHITE \
        BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_PURPLE BRIGHT_CYAN BRIGHT_WHITE \
        BOLD_BRIGHT_BLACK BOLD_BRIGHT_RED BOLD_BRIGHT_GREEN BOLD_BRIGHT_YELLOW BOLD_BRIGHT_BLUE BOLD_BRIGHT_PURPLE BOLD_BRIGHT_CYAN BOLD_BRIGHT_WHITE \
        BG_BRIGHT_BLACK BG_BRIGHT_RED BG_BRIGHT_GREEN BG_BRIGHT_YELLOW BG_BRIGHT_BLUE BG_BRIGHT_PURPLE BG_BRIGHT_CYAN BG_BRIGHT_WHITE \
        BOLD DIM ITALIC UNDERLINE BLINK REVERSE HIDDEN STRIKETHROUGH \
        BRIGHT_MAGENTA INFO OPTION ERROR BARR; do
        printf -v "$_projectr_colour_var" '%s' ''
    done
}

projectr_cli_help() {
    local usage_cmd="${PROJECTR_LAUNCHER_NAME:-project}"
    cat <<EOF_HELP
ProjectR v1.3

Usage:
  ${usage_cmd} <command> [options]
  ${usage_cmd} --flag[=value] [options]
  bash main.sh <command|--flag> [options]

ProjectR accepts BOTH styles. Use whichever you prefer:

  Command style                         Equivalent flag style
  -----------------------------------------------------------------------------
  ${usage_cmd} install git                  ${usage_cmd} --install git
  ${usage_cmd} install git                  ${usage_cmd} --install=git
  ${usage_cmd} uninstall tmux               ${usage_cmd} --uninstall tmux
  ${usage_cmd} list tools                   ${usage_cmd} --list tools
  ${usage_cmd} list tools                   ${usage_cmd} --list=tools
  ${usage_cmd} dry-run install git --json   ${usage_cmd} --dry-run git --json
  ${usage_cmd} doctor                       ${usage_cmd} --doctor
  ${usage_cmd} update                       ${usage_cmd} --update
  ${usage_cmd} self-update                  ${usage_cmd} --self-update

Commands:
  install <tool|all> [--dry-run] [--json]     Install a tool, all tools, or simulate the plan
  install --profile <file>                    Install tools from projectr.yml/projectr.toml
  install --profile=<file>                    Same as above
  uninstall <tool>                            Uninstall a tool non-interactively
  search <name>                               Search all managers and install by name
  list [tools|installed|categories|manager|state]
  upgrade                                     Upgrade system packages with the detected manager
  update | self-update                        Update ProjectR's git checkout and show applied commits
  doctor                                      Check PATH, dependencies, package manager, and logs
  verify                                      Verify ProjectR-managed tools are on PATH
  repair                                      Reinstall missing non-special managed tools
  dry-run install <tool|all> [--json]         Detailed dry-run plan for CI or review
  completions bash                            Print bash completion script

Flags:
  -h, --help                                  Show this combined help message
  -v, --version                               Show ProjectR version
  --install <name>, --install=<name>          Install a tool non-interactively
  --uninstall <name>, --uninstall=<name>      Uninstall a tool non-interactively
  --search <name>, --search=<name>            Search all managers and install by name
  --list <target>, --list=<target>            List tools, installed, categories, manager, or state
  --dry-run [tool|all] [--json]               Simulate changes without installing packages
  --profile <file>, --profile=<file>          Install YAML/TOML configuration as code
  --doctor                                    Run health checks
  --verify                                    Verify managed tools on PATH
  --repair                                    Reinstall missing non-special managed tools
  --update, --self-update                     Fast-forward this checkout and show git-log summary
  --completions bash                          Print bash completion script
  --log [n], --log=<n>                        Print recent install.log lines (default: 20)
  --reset                                     Clear saved preferences
  --export                                    Export profile to projectr_profile_<date>.txt
  --import <file>, --import=<file>            Import a saved profile
  --undo                                      Undo last session changes
  --quiet                                     Reduce extra output where supported
  --no-color                                  Disable ANSI colours
EOF_HELP
    if [[ -n "${PROJECTR_LAUNCHER_NAME:-}" ]]; then
        cat <<EOF_LAUNCHER
  --setup-info, --project-info               Show launcher, source, and install paths
EOF_LAUNCHER
    fi
    cat <<EOF_EXAMPLES

Examples:
  ${usage_cmd} install git
  ${usage_cmd} --install git
  ${usage_cmd} --install=git
  ${usage_cmd} install git --dry-run --json
  ${usage_cmd} --dry-run git --json
  ${usage_cmd} install --profile projectr.yml
  ${usage_cmd} list state
  ${usage_cmd} --list state
  ${usage_cmd} doctor
  ${usage_cmd} --doctor
EOF_EXAMPLES
}

projectr_run_update() {
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${ERROR}[!] git is required for projectr update.${RST}"
        return 1
    fi
    if ! git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${ERROR}[!] $SCRIPT_DIR is not a git checkout; cannot update.${RST}"
        return 1
    fi

    local before after output status
    before=$(git -C "$SCRIPT_DIR" rev-parse HEAD)
    echo -e "${OPTION}[*] Updating ProjectR database and code from git...${RST}"
    output=$(git -C "$SCRIPT_DIR" pull --ff-only --stat 2>&1)
    status=$?
    after=$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || printf '%s' "$before")

    if [[ $status -ne 0 ]]; then
        echo -e "${ERROR}[!] Update failed.${RST}"
        echo "$output"
        return $status
    fi

    if [[ "$before" == "$after" ]]; then
        echo -e "${DIM}[*] Already up to date; no commits were applied.${RST}"
        echo "$output"
        return 0
    fi

    echo -e "${OPTION}[✓] Updated ProjectR:${RST}"
    git -C "$SCRIPT_DIR" --no-pager log --oneline --decorate --stat "${before}..${after}"
}

projectr_completions_bash() {
    cat <<'EOF_COMP'
_projectr_complete() {
  local cur prev commands lists
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="install list upgrade update doctor verify repair dry-run completions self-update help"
  lists="tools installed categories manager state"
  case "$prev" in
    projectr|project|main.sh) COMPREPLY=( $(compgen -W "$commands" -- "$cur") ) ;;
    list) COMPREPLY=( $(compgen -W "$lists" -- "$cur") ) ;;
    completions) COMPREPLY=( $(compgen -W "bash" -- "$cur") ) ;;
  esac
}
complete -F _projectr_complete projectr project
EOF_COMP
}


projectr_cli_install_args() {
    local dry=0 json=0 profile="" targets=() arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry=1 ;;
            --json) json=1 ;;
            --profile=*) profile="${arg#--profile=}" ;;
            --profile) profile="__NEXT__" ;;
            *)
                if [[ "$profile" == "__NEXT__" ]]; then
                    profile="$arg"
                else
                    targets+=("$arg")
                fi
                ;;
        esac
    done

    if [[ -n "$profile" && "$profile" != "__NEXT__" ]]; then
        projectr_install_profile "$profile"
        return $?
    elif [[ "$profile" == "__NEXT__" ]]; then
        echo -e "${ERROR}[!] --profile requires a file path.${RST}"
        return 1
    fi

    [[ ${#targets[@]} -gt 0 ]] || targets=(all)
    if [[ $dry -eq 1 ]]; then
        [[ $json -eq 1 ]] && projectr_dry_run_install "${targets[@]}" --json || projectr_dry_run_install "${targets[@]}"
        return $?
    fi
    if [[ "${targets[0]}" == "all" ]]; then
        install_all
        return $?
    fi
    for arg in "${targets[@]}"; do _flag_install "$arg"; done
}

projectr_cli_uninstall_args() {
    local targets=() arg
    for arg in "$@"; do
        case "$arg" in --*) ;; *) targets+=("$arg") ;; esac
    done
    [[ ${#targets[@]} -gt 0 ]] || { echo -e "${ERROR}[!] uninstall requires a tool name.${RST}"; return 1; }
    for arg in "${targets[@]}"; do _flag_uninstall "$arg"; done
}

projectr_cli_list_arg() {
    local target="${1:-tools}"
    case "$target" in
        tools) _flag_list_tools ;;
        installed) _flag_list_installed ;;
        categories|cat) _flag_list_categories ;;
        manager|managers) _flag_list_manager ;;
        state) projectr_state_list ;;
        *) echo -e "${ERROR}[!] Unknown list target: $target${RST}"; return 1 ;;
    esac
}
