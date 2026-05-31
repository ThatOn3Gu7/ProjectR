#!/bin/bash
# Rich dry-run planner. It asks native package managers for simulations when possible
# and falls back to a deterministic ProjectR plan when the manager cannot simulate.

projectr_escape_json() {
    sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' <<< "$1"
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

projectr_package_simulation() {
    local manager="$1" pkg="$2"
    case "$manager" in
        apt) apt-get -s install "$pkg" 2>/dev/null | awk '/^Inst /{print "install " $2} /^Remv /{print "remove " $2} /^Conf /{print "configure " $2}' ;;
        dnf|yum) "$manager" repoquery --requires "$pkg" 2>/dev/null | sed 's/^/requires /' || true ;;
        pacman) pacman -Sp --print-format '%n %v %s' "$pkg" 2>/dev/null | sed 's/^/download /' ;;
        brew) brew info --json=v2 "$pkg" 2>/dev/null | awk 'BEGIN{print "install '$pkg'"}' ;;
        *) printf 'install %s\n' "$pkg" ;;
    esac
}

projectr_dry_run_install() {
    local json=0 targets=() arg
    for arg in "$@"; do
        case "$arg" in
            --json) json=1 ;;
            --no-color) projectr_disable_color ;;
            *) targets+=("$arg") ;;
        esac
    done
    [[ ${#targets[@]} -gt 0 ]] || targets=("all")

    local PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    local tmp plan_count=0
    tmp=$(mktemp)

    local entry target entries=()
    if [[ "${targets[0]}" == "all" ]]; then
        entries=("${TOOLS[@]}")
    else
        for target in "${targets[@]}"; do
            entry=$(projectr_find_tool "$target") || {
                echo -e "${ERROR}[!] Unknown tool: $target${RST}" >&2
                rm -f "$tmp"
                return 1
            }
            entries+=("$entry")
        done
    fi

    for entry in "${entries[@]}"; do
        IFS='|' read -r _ cmd pkg name desc type extra cat <<< "$entry"
        local status="planned" impact="unknown" conflicts="none" changes
        if command -v "$cmd" >/dev/null 2>&1; then
            status="already-installed"
            changes="none"
            impact="0B"
        elif [[ "$type" == "special" ]]; then
            changes="special-installer:$extra"
            conflicts="manual-review"
        else
            changes=$(projectr_package_simulation "$PM" "$pkg" | paste -sd ';' -)
            [[ -n "$changes" ]] || changes="install $pkg"
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$cmd" "$pkg" "$type" "$status" "$impact" "$conflicts" "$changes" >> "$tmp"
        plan_count=$((plan_count + 1))
    done

    if [[ $json -eq 1 ]]; then
        printf '{"package_manager":"%s","plan":[' "$(projectr_escape_json "$PM")"
        local first=1
        while IFS=$'\t' read -r name cmd pkg type status impact conflicts changes; do
            [[ $first -eq 0 ]] && printf ','
            first=0
            printf '{"name":"%s","cmd":"%s","package":"%s","type":"%s","status":"%s","disk_impact":"%s","conflicts":"%s","changes":"%s"}' \
                "$(projectr_escape_json "$name")" "$(projectr_escape_json "$cmd")" "$(projectr_escape_json "$pkg")" \
                "$(projectr_escape_json "$type")" "$(projectr_escape_json "$status")" "$(projectr_escape_json "$impact")" \
                "$(projectr_escape_json "$conflicts")" "$(projectr_escape_json "$changes")"
        done < "$tmp"
        printf ']}\n'
    else
        echo -e "${OPTION}[*] ProjectR dry-run plan (${PM})${RST}"
        printf '  %-18s %-10s %-18s %-18s %s\n' Tool Type Package Status Changes
        printf '  %s\n' '────────────────────────────────────────────────────────────────────────'
        while IFS=$'\t' read -r name cmd pkg type status impact conflicts changes; do
            printf '  %-18s %-10s %-18s %-18s %s\n' "$name" "$type" "$pkg" "$status" "$changes"
        done < "$tmp"
        echo -e "${DIM}[*] No changes were made. Use --json for CI output.${RST}"
    fi
    rm -f "$tmp"
    [[ $plan_count -gt 0 ]]
}
