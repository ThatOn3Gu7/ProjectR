#!/bin/bash
# Professional subcommand dispatcher for ProjectR.

projectr_disable_color() {
    RST="" BLACK="" RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" WHITE=""
    BOLD_BLACK="" BOLD_RED="" BOLD_GREEN="" BOLD_YELLOW="" BOLD_BLUE="" BOLD_PURPLE="" BOLD_CYAN="" BOLD_WHITE=""
    BRIGHT_BLACK="" BRIGHT_RED="" BRIGHT_GREEN="" BRIGHT_YELLOW="" BRIGHT_BLUE="" BRIGHT_PURPLE="" BRIGHT_CYAN="" BRIGHT_WHITE=""
    BOLD_BRIGHT_BLACK="" BOLD_BRIGHT_RED="" BOLD_BRIGHT_GREEN="" BOLD_BRIGHT_YELLOW="" BOLD_BRIGHT_BLUE="" BOLD_BRIGHT_PURPLE="" BOLD_BRIGHT_CYAN="" BOLD_BRIGHT_WHITE=""
    BG_GREEN="" BG_BRIGHT_RED="" BG_BRIGHT_YELLOW="" BOLD="" DIM="" INFO="" OPTION="" ERROR="" BARR=""
}

projectr_cli_help() {
    cat <<EOF_HELP
ProjectR v1.3

Usage:
  projectr <command> [options]
  bash main.sh <command> [options]

Commands:
  install <tool|all> [--dry-run] [--json]   Install a tool, all tools, or simulate the plan
  install --profile=projectr.yml             Install tools from YAML/TOML configuration
  list [tools|installed|categories|manager|state]
  upgrade                                  Upgrade system packages with the detected manager
  update                                   Update ProjectR's git checkout and show a git-log summary
  doctor                                   Check PATH, dependencies, package manager, and logs
  verify                                   Verify ProjectR-managed tools are on PATH
  repair                                   Reinstall missing non-special managed tools
  dry-run install <tool|all> [--json]       Detailed dry-run plan for CI or review
  completions bash                         Print bash completion script
  self-update                              Alias for update

Global options:
  --quiet                                  Reduce extra output where supported
  --no-color                               Disable ANSI colours

Legacy flags such as --install=git and --list=tools still work.
EOF_HELP
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

projectr_cli_dispatch() {
    [[ $# -eq 0 ]] && return 1

    local args=() arg
    for arg in "$@"; do
        case "$arg" in
            --no-color) export PROJECTR_NO_COLOR=1; projectr_disable_color ;;
            --quiet) export PROJECTR_QUIET=1 ;;
            *) args+=("$arg") ;;
        esac
    done
    set -- "${args[@]}"
    [[ $# -eq 0 ]] && return 1

    case "$1" in
        help|-h|--help) projectr_cli_help; exit 0 ;;
        --version|-v|version) echo "projectr v1.3"; exit 0 ;;
        install)
            shift
            local dry=0 json=0 targets=()
            for arg in "$@"; do
                case "$arg" in
                    --dry-run) dry=1 ;;
                    --json) json=1 ;;
                    --profile=*) projectr_install_profile "${arg#--profile=}"; exit $? ;;
                    *) targets+=("$arg") ;;
                esac
            done
            [[ ${#targets[@]} -gt 0 ]] || targets=(all)
            if [[ $dry -eq 1 ]]; then
                [[ $json -eq 1 ]] && projectr_dry_run_install "${targets[@]}" --json || projectr_dry_run_install "${targets[@]}"
                exit $?
            fi
            if [[ "${targets[0]}" == "all" ]]; then install_all; exit $?; fi
            for arg in "${targets[@]}"; do _flag_install "$arg"; done
            exit 0
            ;;
        dry-run)
            shift
            [[ "${1:-}" == "install" ]] && shift
            projectr_dry_run_install "$@"
            exit $?
            ;;
        list)
            case "${2:-tools}" in
                tools) _flag_list_tools ;;
                installed) _flag_list_installed ;;
                categories) _flag_list_categories ;;
                manager|managers) _flag_list_manager ;;
                state) projectr_state_list ;;
                *) echo -e "${ERROR}[!] Unknown list target: ${2:-}${RST}"; exit 1 ;;
            esac
            exit $?
            ;;
        upgrade) pkg_upgrade; exit $? ;;
        update|--update|self-update|--self-update) projectr_run_update; exit $? ;;
        doctor) projectr_doctor; exit $? ;;
        verify) projectr_verify_state; exit $? ;;
        repair) projectr_repair_state; exit $? ;;
        completions)
            [[ "${2:-}" == "bash" ]] || { echo "Only bash completions are currently supported."; exit 1; }
            projectr_completions_bash; exit 0
            ;;
        *) return 1 ;;
    esac
}
