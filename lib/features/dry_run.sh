#!/bin/bash
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
        pkg|special) printf '%s\n' "${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}" ;;
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

    local entry cmd pkg name desc type extra cat status impact conflicts changes manager skip_native=0
    [[ ${#entries[@]} -gt $native_limit ]] && skip_native=1
    for entry in "${entries[@]}"; do
        IFS='|' read -r _ cmd pkg name desc type extra cat <<< "$entry"
        status="planned" impact="unknown" conflicts="none"
        manager=$(projectr_simulation_manager_for_type "$type")
        if command -v "$cmd" >/dev/null 2>&1; then
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
            changes="install $pkg (native simulation skipped: ${#entries[@]} item plan exceeds limit ${native_limit})"
        else
            changes=$(projectr_package_simulation "$manager" "$pkg" "$type" | paste -sd ';' -)
            [[ -n "$changes" ]] || changes="install $pkg"
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$cmd" "$pkg" "$type" "$manager" "$status" "$impact" "$conflicts" "$changes" >> "$tmp"
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
        echo -e "${OPTION}[*] ProjectR dry-run plan (no changes will be made)${RST}"
        printf '  %-18s %-10s %-12s %-18s %-18s %s\n' Tool Type Manager Package Status Changes
        printf '  %s\n' '────────────────────────────────────────────────────────────────────────────────────'
        while IFS=$'\t' read -r name cmd pkg type manager status impact conflicts changes; do
            printf '  %-18s %-10s %-12s %-18s %-18s %s\n' "$name" "$type" "$manager" "$pkg" "$status" "$changes"
        done < "$tmp"
        echo -e "${DIM}[*] No changes were made. Use --json for CI output.${RST}"
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
            --*) echo -e "${ERROR}[!] Unknown dry-run option: $arg${RST}" >&2; return 2 ;;
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
                echo -e "${ERROR}[!] Unknown tool: $target${RST}" >&2
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
            --*) echo -e "${ERROR}[!] Unknown profile dry-run option: $arg${RST}" >&2; return 2 ;;
        esac
    done
    [[ -n "$file" ]] || { echo -e "${ERROR}[!] dry-run --profile requires a file path.${RST}" >&2; return 1; }
    declare -f projectr_profile_tools >/dev/null 2>&1 || { echo -e "${ERROR}[!] Profile parser is not loaded.${RST}" >&2; return 1; }
    while IFS= read -r tool; do
        [[ -n "$tool" ]] || continue
        entry=$(projectr_find_tool "$tool") || { echo -e "${ERROR}[!] Unknown tool in profile: $tool${RST}" >&2; return 1; }
        entries+=("$entry")
    done < <(projectr_profile_tools "$file")
    [[ ${#entries[@]} -gt 0 ]] || { echo -e "${ERROR}[!] No tools found in $file${RST}" >&2; return 1; }
    projectr_dry_run_entries "$json" "${entries[@]}"
}

projectr_dry_run_repair() {
    local json=0 arg entries=() entry cmd record record_name record_package record_manager
    local -a records=()
    for arg in "$@"; do
        case "$arg" in
            --json) json=1 ;;
            --*) echo -e "${ERROR}[!] Unknown repair dry-run option: $arg${RST}" >&2; return 2 ;;
        esac
    done

    if ! declare -f projectr_state_records >/dev/null 2>&1 || ! declare -f projectr_state_find_registry_entry >/dev/null 2>&1; then
        echo -e "${ERROR}[!] State helpers are not loaded; cannot plan repair safely.${RST}" >&2
        return 1
    fi

    mapfile -t records < <(projectr_state_records)
    for record in "${records[@]}"; do
        IFS=$'	' read -r record_name record_package record_manager <<< "$record"
        entry=$(projectr_state_find_registry_entry "$record_name" "$record_package") || continue
        IFS='|' read -r _ cmd _ _ _ _ _ _ <<< "$entry"
        command -v "$cmd" >/dev/null 2>&1 || entries+=("$entry")
    done

    if [[ ${#entries[@]} -eq 0 ]]; then
        [[ $json -eq 1 ]] && printf '{"dry_run":true,"plan":[]}\n' || echo -e "${OPTION}[✓] Dry-run repair: no missing recorded ProjectR-managed tools detected.${RST}"
        return 0
    fi
    projectr_dry_run_entries "$json" "${entries[@]}"
}
