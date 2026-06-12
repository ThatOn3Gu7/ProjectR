#!/bin/bash
# shellcheck disable=all
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
    
ProjectR v1.4

Usage:
  ${usage_cmd} <command> [options]
  ${usage_cmd} --flag[=value] [options]
  bash main.sh <command|--flag> [options]

ProjectR accepts BOTH styles. Use whichever you prefer:

  Command style                         Equivalent flag style
  ---------------------------------------------------------------------
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
  install <tool|all> [--dry-run] [--json] [--source=<manager>]
                                                Install a tool, all tools, or simulate the plan
  install --profile <file>                    Install tools from projectr.yml/projectr.toml
  install --profile=<file>                    Same as above
  uninstall <tool>                            Uninstall a tool non-interactively
  search <name>                               Search all managers and install by name
  list [tools|installed|categories|manager|state]
  upgrade                                     Upgrade system packages with the detected manager
  update | self-update                        Update a git checkout or refresh an installed copy
  doctor [--json]                             Check PATH, dependencies, package manager, and logs
  diff --profile <file> [--json]              Compare a profile against the current machine
  verify                                      Verify ProjectR-managed tools are on PATH
  repair                                      Reinstall missing non-special managed tools
  dry-run install <tool|all> [--json]         Detailed dry-run plan for CI or review
  completions bash                            Print bash completion script
  scheduler [status|enable|disable|run-check] Manage background update checks
  audit [--strict]                            Validate registry IDs, types, and special installers

Flags:
  -h, --help                                  Show this combined help message
  -v, --version                               Show ProjectR version
  --install <name>, --install=<name>          Install a tool non-interactively
  --source <manager>, --source=<manager>      Force install/search source manager when supported
  --uninstall <name>, --uninstall=<name>      Uninstall a tool non-interactively
  --search <name>, --search=<name>            Search all managers and install by name
  --list <target>, --list=<target>            List tools, installed, categories, manager, or state
  --dry-run [tool|all] [--json]               Simulate changes without installing packages
  --profile <file>, --profile=<file>          Install YAML/TOML configuration as code
  --doctor [--json]                           Run health checks
  --diff-profile <file>, --diff-profile=<file> Compare profile tools against this machine
  --verify                                    Verify managed tools on PATH
  --repair                                    Reinstall missing non-special managed tools
  --update, --self-update                     Update this checkout or refresh an installed launcher copy
  --completions bash                          Print bash completion script
  --audit [--strict]                          Validate registry IDs, types, and special installers
  --log [n], --log=<n>                        Print recent install.log lines (default: 20)
  --reset                                     Clear saved preferences
  --export                                    Export simple command profile to projectr_profile_<date>.txt
  --export-lock                               Export richer YAML lockfile with versions/managers
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
  ${usage_cmd} install fd --source apt
  ${usage_cmd} --dry-run git --json
  ${usage_cmd} install --profile projectr.yml
  ${usage_cmd} list state
  ${usage_cmd} --list state
  ${usage_cmd} doctor
  ${usage_cmd} doctor --json
  ${usage_cmd} diff --profile projectr.yml
  ${usage_cmd} --doctor
  ${usage_cmd} audit --strict
  
EOF_EXAMPLES
}


projectr_cli_find_tool_entry() {
    local target="${1:-}" entry cmd pkg name desc type extra cat
    [[ -n "$target" ]] || return 1
    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r _ cmd pkg name desc type extra cat <<< "$entry"
        if [[ "${cmd,,}" == "${target,,}" || "${pkg,,}" == "${target,,}" || "${name,,}" == "${target,,}" ]]; then
            printf '%s\n' "$entry"
            return 0
        fi
    done
    return 1
}

projectr_cli_entries_for_targets() {
    local target entry
    for target in "$@"; do
        entry=$(projectr_cli_find_tool_entry "$target") || return 1
        printf '%s\n' "$entry"
    done
}


projectr_update_metadata_field() {
    local key="$1" metadata_file="${2:-${SCRIPT_DIR}/.projectr-install}" line_key line_value
    [[ -f "$metadata_file" ]] || return 1
    while IFS='=' read -r line_key line_value || [[ -n "$line_key" ]]; do
        [[ "$line_key" == "$key" ]] || continue
        line_value="${line_value#\'}"
        line_value="${line_value%\'}"
        printf '%s\n' "$line_value"
        return 0
    done < "$metadata_file"
    return 1
}

projectr_update_refresh_installed_copy() {
    local setup_dir="$1" install_dir="$2" bin_dir="$3" command_name="$4" repo_url="${5:-}"
    [[ -f "$setup_dir/setup.sh" ]] || return 1
    if [[ -n "$repo_url" ]]; then
        PROJECTR_REPO_URL="$repo_url" bash "$setup_dir/setup.sh" --no-menu --self-update-mode --force-remote --command="$command_name" --install-dir="$install_dir" --bin-dir="$bin_dir"
    else
        bash "$setup_dir/setup.sh" --no-menu --self-update-mode --command="$command_name" --install-dir="$install_dir" --bin-dir="$bin_dir"
    fi
}

projectr_run_update() {
    if ! command -v git >/dev/null 2>&1; then
        msg_warning "Git is required for ProjectR update."
        log_error "projectr update failed: git command not found" "update"
        return 1
    fi

    local update_dir="$SCRIPT_DIR" install_dir="${PROJECTR_HOME:-$SCRIPT_DIR}" bin_dir="${PROJECTR_BIN_DIR:-${HOME}/.local/bin}" command_name="${PROJECTR_COMMAND_NAME:-project}"
    local source_dir="${PROJECTR_SOURCE_DIR:-}" repo_url="${PROJECTR_REPO_URL:-}" metadata_file="$SCRIPT_DIR/.projectr-install"

    if [[ ! -d "$update_dir/.git" ]]; then
        [[ -z "$source_dir" ]] && source_dir=$(projectr_update_metadata_field PROJECTR_SOURCE_DIR "$metadata_file" 2>/dev/null || true)
        [[ -z "$repo_url" ]] && repo_url=$(projectr_update_metadata_field PROJECTR_REPO_URL "$metadata_file" 2>/dev/null || true)
        [[ -z "$install_dir" || "$install_dir" == "$SCRIPT_DIR" ]] && install_dir=$(projectr_update_metadata_field PROJECTR_INSTALL_DIR "$metadata_file" 2>/dev/null || printf '%s' "$install_dir")
        [[ -z "$bin_dir" || "$bin_dir" == "${HOME}/.local/bin" ]] && bin_dir=$(projectr_update_metadata_field PROJECTR_BIN_DIR "$metadata_file" 2>/dev/null || printf '%s' "$bin_dir")
        [[ -z "$command_name" || "$command_name" == "project" ]] && command_name=$(projectr_update_metadata_field PROJECTR_COMMAND_NAME "$metadata_file" 2>/dev/null || printf '%s' "$command_name")
        if [[ -n "$source_dir" && -d "$source_dir/.git" ]]; then
            update_dir="$source_dir"
        fi
    fi

    local remote_url current_branch before after output status
    if [[ -d "$update_dir/.git" ]]; then
        remote_url=$(git -C "$update_dir" remote get-url origin 2>/dev/null || printf '%s' '')
        [[ -z "$repo_url" ]] && repo_url="$remote_url"
        if declare -f projectr_require_trusted_repo >/dev/null 2>&1 && ! projectr_require_trusted_repo "${remote_url:-$repo_url}" update; then
            log_fail "ProjectR update refused for untrusted remote: ${remote_url:-$repo_url}" "update"
            return 1
        fi

        current_branch=$(git -C "$update_dir" rev-parse --abbrev-ref HEAD)
        before=$(git -C "$update_dir" rev-parse HEAD)
        echo -e "${OPTION}[*] Updating ProjectR database and code from git...${RST}"
        log_info "Starting ProjectR update from git (before=$before remote=${remote_url:-$repo_url} branch=$current_branch dir=$update_dir)" "update"
        local fetch_ref="origin/$current_branch"
        if [[ -n "$remote_url" ]]; then
            if output=$(git -C "$update_dir" fetch --tags --prune origin 2>&1 && git -C "$update_dir" merge --ff-only "$fetch_ref" 2>&1 && git -C "$update_dir" diff --stat "$before"..HEAD 2>&1); then
                status=0
            else
                status=$?
            fi
        elif [[ -n "$repo_url" ]]; then
            fetch_ref="FETCH_HEAD"
            if output=$(git -C "$update_dir" fetch --tags --prune "$repo_url" "$current_branch" 2>&1 && git -C "$update_dir" merge --ff-only "$fetch_ref" 2>&1 && git -C "$update_dir" diff --stat "$before"..HEAD 2>&1); then
                status=0
            else
                status=$?
            fi
        else
            output="No git remote configured for $update_dir"
            status=1
        fi
        after=$(git -C "$update_dir" rev-parse HEAD 2>/dev/null || printf '%s' "$before")

        if [[ $status -ne 0 ]]; then
            echo -e "${ERROR}[!] Update failed.${RST}"
            echo "$output"
            log_fail "ProjectR update failed: $output" "update"
            return $status
        fi

        if [[ "$install_dir" != "$update_dir" ]]; then
            echo -e "${OPTION}[*] Refreshing installed copy at ${BOLD_WHITE}${install_dir}${RST}${OPTION}...${RST}"
            projectr_update_refresh_installed_copy "$update_dir" "$install_dir" "$bin_dir" "$command_name"
            status=$?
            [[ $status -eq 0 ]] || return $status
        fi

        if [[ "$before" == "$after" ]]; then
            echo -e "${DIM}[*] Already up to date; no commits were applied.${RST}"
            echo "$output"
            log_ok "ProjectR update already up to date at $after" "update"
            return 0
        fi

        echo -e "${OPTION}[✓] Updated ProjectR:${RST}"
        log_ok "ProjectR updated from $before to $after" "update"
        git -C "$update_dir" --no-pager log --oneline --decorate --stat "${before}..${after}"
        return 0
    fi

    repo_url="${repo_url:-https://github.com/Thaton3gu7/ProjectR.git}"
    if declare -f projectr_require_trusted_repo >/dev/null 2>&1 && ! projectr_require_trusted_repo "$repo_url" update; then
        log_fail "ProjectR update refused for untrusted remote fallback: $repo_url" "update"
        return 1
    fi
    echo -e "${OPTION}[*] No git checkout found for the installed copy; refreshing ${BOLD_WHITE}${install_dir}${RST}${OPTION} directly from ${repo_url}.${RST}"
    projectr_update_refresh_installed_copy "$install_dir" "$install_dir" "$bin_dir" "$command_name" "$repo_url"
}

projectr_completions_bash() {
    cat <<'EOF_COMP'
_projectr_complete() {
  local cur prev commands lists
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="install list upgrade update doctor verify repair dry-run completions self-update audit scheduler export-lock help"
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



projectr_cli_upgrade_args() {
    local dry=0 json=0 arg manager
    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry=1 ;;
            --json) json=1 ;;
            --*) echo -e "${ERROR}[!] Unknown upgrade option: $arg${RST}"; log_error "Unknown upgrade option: $arg" "cli"; return 2 ;;
        esac
    done
    manager="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    if [[ $dry -eq 1 ]]; then
        if [[ $json -eq 1 ]]; then
            printf '{"dry_run":true,"action":"upgrade","manager":"%s","changes":"%s"}\n' \
                "$(projectr_escape_json "$manager")" "$(projectr_escape_json "native upgrade simulation only; no changes made")"
        else
            echo -e "${OPTION}[*] ProjectR dry-run upgrade plan (${manager})${RST}"
            case "$manager" in
                apt|apt-get) apt-get -s upgrade 2>/dev/null | awk '/^Inst /{print "  upgrade " $2} /^Remv /{print "  remove " $2} /^Conf /{print "  configure " $2}' ;;
                pacman) pacman -Qu 2>/dev/null | sed 's/^/  upgrade /' ;;
                dnf|yum) "$manager" check-update 2>/dev/null | sed 's/^/  candidate /' || true ;;
                brew) brew outdated 2>/dev/null | sed 's/^/  upgrade /' ;;
                *) echo "  Native upgrade simulation is not available for $manager; would run pkg_upgrade." ;;
            esac
            echo -e "${DIM}[*] No changes were made.${RST}"
        fi
        return 0
    fi
    pkg_upgrade
}

projectr_cli_install_args() {
    local dry="${PROJECTR_CLI_DRY_RUN:-0}" json=0 batch=0 profile="" source_manager="" targets=() arg status=0 rc
    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry=1 ;;
            --json) json=1 ;;
            --batch) batch=1 ;;
            --source=*) source_manager="${arg#--source=}" ;;
            --source) source_manager="__NEXT__" ;;
            --profile=*) profile="${arg#--profile=}" ;;
            --profile) profile="__NEXT__" ;;
            --*) echo -e "${ERROR}[!] Unknown install option: $arg${RST}"; log_error "Unknown install option: $arg" "cli"; return 2 ;;
            *)
                if [[ "$profile" == "__NEXT__" ]]; then
                    profile="$arg"
                elif [[ "$source_manager" == "__NEXT__" ]]; then
                    source_manager="$arg"
                else
                    targets+=("$arg")
                fi
                ;;
        esac
    done

    [[ "$source_manager" != "__NEXT__" ]] || { echo -e "${ERROR}[!] --source requires a manager name.${RST}"; return 1; }

    if [[ -n "$profile" && "$profile" != "__NEXT__" ]]; then
        if [[ $dry -eq 1 ]]; then
            local args=("$profile")
            [[ $json -eq 1 ]] && args+=("--json")
            projectr_dry_run_profile "${args[@]}"
        else
            projectr_install_profile "$profile"
        fi
        return $?
    elif [[ "$profile" == "__NEXT__" ]]; then
        echo -e "${ERROR}[!] --profile requires a file path.${RST}"
        log_error "install --profile missing path" "cli"
        return 1
    fi

    [[ ${#targets[@]} -gt 0 ]] || targets=(all)
    if [[ $dry -eq 1 ]]; then
        export DRY_RUN=1
        [[ -n "$source_manager" ]] && export PROJECTR_INSTALL_MANAGER_OVERRIDE="$source_manager"
        [[ $json -eq 1 ]] && projectr_dry_run_install "${targets[@]}" --json || projectr_dry_run_install "${targets[@]}"
        unset PROJECTR_INSTALL_MANAGER_OVERRIDE
        return $?
    fi
    [[ -n "$source_manager" ]] && export PROJECTR_INSTALL_MANAGER_OVERRIDE="$source_manager"
    if [[ "${targets[0]}" == "all" ]]; then
        if [[ $batch -eq 1 ]]; then
            projectr_install_batch_by_entries "${TOOLS[@]}"
        else
            install_all
        fi
        rc=$?
        unset PROJECTR_INSTALL_MANAGER_OVERRIDE
        return $rc
    fi
    if [[ $batch -eq 1 ]]; then
        local -a entries=()
        for arg in "${targets[@]}"; do
            local entry
            entry=$(projectr_cli_find_tool_entry "$arg") || { echo -e "${ERROR}[!] No tool named '$arg' found in the list.${RST}"; unset PROJECTR_INSTALL_MANAGER_OVERRIDE; return 1; }
            entries+=("$entry")
        done
        projectr_install_batch_by_entries "${entries[@]}"
        rc=$?
        unset PROJECTR_INSTALL_MANAGER_OVERRIDE
        return $rc
    fi
    for arg in "${targets[@]}"; do
        _flag_install "$arg"
        rc=$?
        [[ $rc -ne 0 ]] && status=$rc
    done
    unset PROJECTR_INSTALL_MANAGER_OVERRIDE
    return "$status"
}

projectr_cli_uninstall_args() {
    local targets=() arg status=0 rc
    for arg in "$@"; do
        case "$arg" in
            --dry-run) echo -e "${ERROR}[!] Dry-run uninstall is not implemented; no changes were made.${RST}"; return 2 ;;
            --*) echo -e "${ERROR}[!] Unknown uninstall option: $arg${RST}"; log_error "Unknown uninstall option: $arg" "cli"; return 2 ;;
            *) targets+=("$arg") ;;
        esac
    done
    [[ ${#targets[@]} -gt 0 ]] || { echo -e "${ERROR}[!] uninstall requires a tool name.${RST}"; log_error "uninstall command missing target" "cli"; return 1; }
    for arg in "${targets[@]}"; do
        _flag_uninstall "$arg"
        rc=$?
        [[ $rc -ne 0 ]] && status=$rc
    done
    return "$status"
}

projectr_cli_scheduler_args() {
    local action="${1:-status}"
    projectr_scheduler_cli "$action"
}

projectr_cli_list_arg() {
    local target="${1:-tools}"
    case "$target" in
        tools) _flag_list_tools ;;
        installed) _flag_list_installed ;;
        categories|cat) _flag_list_categories ;;
        manager|managers) _flag_list_manager ;;
        state) projectr_state_list ;;
        *) echo -e "${ERROR}[!] Unknown list target: $target${RST}"; log_error "Unknown list target: $target" "cli"; return 1 ;;
    esac
}
