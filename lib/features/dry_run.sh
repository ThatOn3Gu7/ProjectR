#!/bin/bash
# shellcheck disable=all
# Rich dry-run planner. It asks native package managers for simulations when possible
# and falls back to a deterministic ProjectR plan when the manager cannot simulate.
# This file must never execute mutating package-manager subcommands.

projectr_escape_json() {
    local value="${1-}"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\t'/\\t}
    value=${value//$'\r'/\\r}
    value=${value//$'\n'/\\n}
    printf '%s' "$value"
}
projectr_find_tool() {
    local target="$1" entry
    for entry in "${TOOLS[@]}"; do
        IFS='|' read -r _ cmd pkg name desc type extra cat <<< "$entry"
        if [[ "${cmd,,}" == "${target,,}" || "${pkg,,}" == "${target,,}" || "${name,,}" == "${target,,}" ]]; then
            printf '%s\n' "$entry"
            return 0
        fi
    done
    return 1
}

projectr_simulation_manager_for_type() {
    local type="${1:-pkg}"
    case "$type" in
        pkg|special) printf '%s\n' "${PROJECTR_INSTALL_MANAGER_OVERRIDE:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}" ;;
        pip|pip3|pipx|cargo|gem|npm|yarn|pnpm|bun) detect_pkg_for_tool "$type" ;;
        *) printf '%s\n' "${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}" ;;
    esac
}

projectr_package_simulation() {
    local manager="$1" pkg="$2" type="${3:-pkg}"
    case "$manager" in
        apt|apt-get) apt-get -s install "$pkg" 2>/dev/null | awk '/^Inst /{print "install " $2} /^Remv /{print "remove " $2} /^Conf /{print "configure " $2}' ;;
        dnf|yum) "$manager" repoquery --requires "$pkg" 2>/dev/null | sed 's/^/requires /' || true ;;
        pacman) pacman -Sp --print-format '%n %v %s' "$pkg" 2>/dev/null | sed 's/^/download /' ;;
        brew) brew info --json=v2 "$pkg" >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        apk) apk info -e "$pkg" >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        zypper) zypper --non-interactive info "$pkg" >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        pip|pip3) "$manager" index versions "$pkg" >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        pipx) printf 'install %s\n' "$pkg" ;;
        npm) npm view "$pkg" version >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        yarn) yarn info "$pkg" version >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        pnpm) pnpm view "$pkg" version >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        bun) bun pm view "$pkg" version >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        gem) gem query --remote --exact --name-matches "^${pkg}$" >/dev/null 2>&1 && printf 'install %s\n' "$pkg" ;;
        cargo) cargo search --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg " && printf 'install %s\n' "$pkg" ;;
        none) printf 'manager-missing %s\n' "$type" ;;
        *) printf 'install %s\n' "$pkg" ;;
    esac
}

projectr_dry_run_entries() {
    local json="$1"
    shift
    local entries=("$@")
    local tmp plan_count=0 native_limit="${PROJECTR_DRY_RUN_NATIVE_LIMIT:-20}"
    tmp=$(mktemp) || return 1

    local entry cmd pkg name desc type extra cat status impact conflicts changes manager skip_native=0 tool_id effective_cmd effective_pkg
    [[ ${#entries[@]} -gt $native_limit ]] && skip_native=1
    for entry in "${entries[@]}"; do
        IFS='|' read -r _ cmd pkg name desc type extra cat <<< "$entry"
        status="planned" impact="unknown" conflicts="none"
        manager=$(projectr_simulation_manager_for_type "$type")
        tool_id=$(projectr_tool_id "$cmd")
        effective_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$manager")
        effective_pkg=$(projectr_effective_package "$tool_id" "$pkg" "$manager")
        if command -v "$effective_cmd" >/dev/null 2>&1; then
            status="already-installed"
            changes="none"
            impact="0B"
        elif [[ "$type" == "special" ]]; then
            changes="special-installer:$extra"
            conflicts="manual-review"
        elif [[ "$manager" == "none" ]]; then
            status="blocked"
            changes="missing-manager:$type"
            conflicts="manager-unavailable"
        elif [[ $skip_native -eq 1 ]]; then
            changes="install $effective_pkg (native simulation skipped: ${#entries[@]} item plan exceeds limit ${native_limit})"
        else
            changes=$(projectr_package_simulation "$manager" "$effective_pkg" "$type" | paste -sd ';' -)
            [[ -n "$changes" ]] || changes="install $effective_pkg"
        fi
        printf '%s	%s	%s	%s	%s	%s	%s	%s	%s
' "$name" "$effective_cmd" "$effective_pkg" "$type" "$manager" "$status" "$impact" "$conflicts" "$changes" >> "$tmp"
        plan_count=$((plan_count + 1))
    done

    if [[ $json -eq 1 ]]; then
        awk -F '\t' '
            function esc(s) {
                gsub(/\\/, "\\\\", s)
                gsub(/"/, "\\\"", s)
                return s
            }
            BEGIN { printf "{\"dry_run\":true,\"plan\":[" }
            {
                if (NR > 1) printf ","
                printf "{\"name\":\"%s\",\"cmd\":\"%s\",\"package\":\"%s\",\"type\":\"%s\",\"manager\":\"%s\",\"status\":\"%s\",\"disk_impact\":\"%s\",\"conflicts\":\"%s\",\"changes\":\"%s\"}", esc($1), esc($2), esc($3), esc($4), esc($5), esc($6), esc($7), esc($8), esc($9)
            }
            END { printf "]}\n" }
        ' "$tmp"
    else
        echo -e "${OPTION}[*] ProjectR dry-run simulation plan (no modifications will be performed)${RST}"
        printf '  %-20s | %-12s | %-10s | %-15s\n' "Tool" "Package" "Manager" "Type"
        printf '  %s\n' '─────────────────────────────────────────────────────────────'
        while IFS=$'\t' read -r name cmd pkg type manager status impact conflicts changes; do
            printf '  %-20s | %-12s | %-10s | %-15s\n' "$cmd" "$pkg" "$manager" "$type"
        done < "$tmp"
        printf '  %s\n' '─────────────────────────────────────────────────────────────'
        echo -e "${DIM}[*] No changes were applied. Utilize --json for structured output.${RST}"
    fi
    log_ok "Dry-run generated $plan_count plan item(s)" "dry-run"
    rm -f "$tmp"
    [[ $plan_count -gt 0 ]]
}

projectr_dry_run_install() {
    local json=0 targets=() arg
    for arg in "$@"; do
        case "$arg" in
            --json) json=1 ;;
            --no-color) projectr_disable_color ;;
            --dry-run|install) ;;
            --*) echo -e "${ERROR}[!] Unrecognized dry-run parameter: $arg${RST}" >&2; return 2 ;;
            *) targets+=("$arg") ;;
        esac
    done
    [[ ${#targets[@]} -gt 0 ]] || targets=("all")
    log_info "Starting dry-run install targets=${targets[*]} json=$json" "dry-run"

    local entry target entries=()
    if [[ "${targets[0]}" == "all" ]]; then
        entries=("${TOOLS[@]}")
    else
        for target in "${targets[@]}"; do
            entry=$(projectr_find_tool "$target") || {
                echo -e "${ERROR}[!] Unrecognized tool: $target${RST}" >&2
                log_error "Dry-run requested unknown tool: $target" "dry-run"
                return 1
            }
            entries+=("$entry")
        done
    fi

    projectr_dry_run_entries "$json" "${entries[@]}"
}

projectr_dry_run_profile() {
    local file="${1:-}" json=0 arg entries=() tool entry
    shift || true
    for arg in "$@"; do
        case "$arg" in
            --json) json=1 ;;
            --*) echo -e "${ERROR}[!] Unrecognized profile dry-run parameter: $arg${RST}" >&2; return 2 ;;
        esac
    done
    [[ -n "$file" ]] || { echo -e "${ERROR}[!] The --profile option requires a valid file path.${RST}" >&2; return 1; }
    declare -f projectr_profile_tools >/dev/null 2>&1 || { echo -e "${ERROR}[!] The profile parser library is not initialized.${RST}" >&2; return 1; }
    local -a profile_list=()
    projectr_profile_tools "$file" || return 1
    for tool in "${_projectr_profile_tools[@]}"; do
        entry=$(projectr_find_tool "$tool") || { echo -e "${ERROR}[!] Unrecognized tool entry in profile: $tool${RST}" >&2; return 1; }
        profile_list+=("$entry")
    done
    [[ ${#profile_list[@]} -gt 0 ]] || { echo -e "${ERROR}[!] No valid tool definitions found in $file${RST}" >&2; return 1; }
    projectr_dry_run_entries "$json" "${profile_list[@]}"
}

projectr_dry_run_repair() {
    local json=0 arg entries=() entry cmd record record_tool_id record_name record_package record_manager
    local -a records=()
    for arg in "$@"; do
        case "$arg" in
            --json) json=1 ;;
            --*) echo -e "${ERROR}[!] Unrecognized repair dry-run parameter: $arg${RST}" >&2; return 2 ;;
        esac
    done
    declare -f projectr_state_get_installs >/dev/null 2>&1 || {
        echo -e "${ERROR}[!] State management components are not loaded; unable to safely formulate repair plan.${RST}" >&2
        return 1
    }

    mapfile -t records < <(projectr_state_records)
    for record in "${records[@]}"; do
        IFS=$'	' read -r record_tool_id record_name record_package record_manager <<< "$record"
        entry=$(projectr_state_find_registry_entry "$record_tool_id" "$record_name" "$record_package") || continue
        IFS='|' read -r _ cmd _ _ _ _ _ _ <<< "$entry"
        command -v "$(projectr_effective_cmd "$record_tool_id" "$cmd" "$record_manager")" >/dev/null 2>&1 || entries+=("$entry")
    done

    if [[ ${#entries[@]} -eq 0 ]]; then
        [[ $json -eq 1 ]] && printf '{"dry_run":true,"plan":[]}\n' || echo -e "${OPTION}[✓] Dry-run repair: No missing ProjectR-managed tools were detected.${RST}"
        return 0
    fi
    projectr_dry_run_entries "$json" "${entries[@]}"
}
