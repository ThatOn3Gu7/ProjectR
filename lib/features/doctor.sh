#!/bin/bash
# shellcheck disable=all

projectr_doctor_json_escape() {
    if declare -f projectr_escape_json >/dev/null 2>&1; then
        projectr_escape_json "${1-}"
        return
    fi
    local value="${1-}"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\t'/\\t}
    value=${value//$'\r'/\\r}
    value=${value//$'\n'/\\n}
    printf '%s' "$value"
}

projectr_doctor_check() {
    local name="$1" status="$2" detail="${3:-}"
    printf '%s\t%s\t%s\n' "$name" "$status" "$detail"
}

projectr_doctor_collect() {
    local tmp="$1" failures=0 dep pm state_db log_status log_detail priv_status priv_detail scheduler_status
    : > "$tmp"

    if [[ -n "${PATH:-}" ]]; then
        projectr_doctor_check PATH ok >> "$tmp"
    else
        projectr_doctor_check PATH missing >> "$tmp"
        failures=$((failures+1))
    fi

    for dep in bash awk sed find git; do
        if command -v "$dep" >/dev/null 2>&1; then
            projectr_doctor_check "$dep" ok "$(command -v "$dep")" >> "$tmp"
        else
            projectr_doctor_check "$dep" missing >> "$tmp"
            failures=$((failures+1))
        fi
    done

    pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    if [[ -n "$pm" && "$pm" != "unknown" ]]; then
        projectr_doctor_check package-manager ok "$pm" >> "$tmp"
    else
        projectr_doctor_check package-manager missing >> "$tmp"
        failures=$((failures+1))
    fi

    if declare -f projectr_privilege_status >/dev/null 2>&1; then
        IFS=$'\t' read -r priv_status priv_detail < <(projectr_privilege_status "$pm")
    else
        priv_status=warn
        priv_detail="privilege abstraction not loaded"
    fi
    projectr_doctor_check privilege "$priv_status" "$priv_detail" >> "$tmp"
    [[ "$priv_status" == "missing" ]] && failures=$((failures+1))

    if command -v sqlite3 >/dev/null 2>&1; then
        state_db="sqlite"
    else
        state_db="TSV fallback (install sqlite3 for SQLite state)"
    fi
    projectr_doctor_check state-db ok "$state_db" >> "$tmp"

    if [[ -w "$SCRIPT_DIR/log" || ! -e "$SCRIPT_DIR/log" ]]; then
        log_status=ok
        log_detail="writable"
    else
        log_status=missing
        log_detail="not-writable"
        failures=$((failures+1))
    fi
    projectr_doctor_check logs "$log_status" "$log_detail" >> "$tmp"

    if declare -f projectr_scheduler_status >/dev/null 2>&1; then
        scheduler_status=$(projectr_scheduler_status | paste -sd ';' -)
        projectr_doctor_check scheduler ok "${scheduler_status:-disabled}" >> "$tmp"
    fi

    return "$failures"
}

projectr_doctor_print_json() {
    local tmp="$1" failures="$2" first=1 name status detail
    printf '{"ok":%s,"failures":%s,"checks":[' "$([[ "$failures" -eq 0 ]] && printf true || printf false)" "$failures"
    while IFS=$'\t' read -r name status detail; do
        [[ -n "$name" ]] || continue
        [[ $first -eq 0 ]] && printf ','
        first=0
        printf '{"name":"%s","status":"%s","detail":"%s"}' \
            "$(projectr_doctor_json_escape "$name")" \
            "$(projectr_doctor_json_escape "$status")" \
            "$(projectr_doctor_json_escape "$detail")"
    done < "$tmp"
    printf ']}\n'
}

projectr_doctor_print_table() {
    local tmp="$1" failures="$2" name status detail result
    echo ""
    echo -e "${OPTION}[*] ProjectR doctor${RST}"
    echo ""
    printf '  %-22s %s\n' Check Result
    printf '  %s\n' '─────────────────────────────'

    while IFS=$'\t' read -r name status detail; do
        [[ -n "$name" ]] || continue
        case "$status" in
            ok) result="${detail:-ok}" ;;
            warn) result="$detail" ;;
            *) result="${detail:-missing}" ;;
        esac
        printf '  %-22s %s\n' "$name" "$result"
    done < "$tmp"

    printf '  %s\n' '─────────────────────────────'
    echo ""
    if [[ $failures -eq 0 ]]; then
        echo -e "${OPTION}[✓] System diagnostics completed. No blocking issues were identified.${RST}"
        echo ""
    else
        echo -e "${ERROR}[!] System diagnostics completed. Identified $failures issue(s).${RST}"
        echo ""
    fi
}

projectr_doctor() {
    local json=0 arg tmp failures
    for arg in "$@"; do
        case "$arg" in
            --json) json=1 ;;
            --no-color) declare -f projectr_disable_color >/dev/null 2>&1 && projectr_disable_color ;;
            *) echo -e "${ERROR}[!] Unknown diagnostic option: $arg${RST}" >&2; return 2 ;;
        esac
    done
    tmp=$(mktemp) || { echo -e "${ERROR}[!] Unable to create temporary file for diagnostic logs.${RST}" >&2; return 1; }
    log_info "Starting doctor checks json=$json" "doctor"
    projectr_doctor_collect "$tmp"
    failures=$?

    if [[ $json -eq 1 ]]; then
        projectr_doctor_print_json "$tmp" "$failures"
    else
        projectr_doctor_print_table "$tmp" "$failures"
    fi
    rm -f "$tmp"

    if [[ $failures -eq 0 ]]; then
        log_ok "Doctor completed with no blocking issues" "doctor"
        return 0
    fi
    log_fail "Doctor found $failures issue(s)" "doctor"
    return 1
}
