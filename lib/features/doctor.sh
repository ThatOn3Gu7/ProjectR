#!/bin/bash
projectr_doctor() {
    local failures=0
    echo -e "${OPTION}[*] ProjectR doctor${RST}"
    echo ""
    printf '  %-22s %s\n' Check Result
    printf '  %s\n' '────────────────────────────────────────'

    if [[ -n "${PATH:-}" ]]; then printf '  %-22s %s\n' PATH ok; else printf '  %-22s %s\n' PATH missing; failures=$((failures+1)); fi

    local dep
    for dep in bash awk sed find git; do
        if command -v "$dep" >/dev/null 2>&1; then
            printf '  %-22s %s\n' "$dep" "$(command -v "$dep")"
        else
            printf '  %-22s %s\n' "$dep" missing
            failures=$((failures+1))
        fi
    done

    local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    if [[ -n "$pm" && "$pm" != "unknown" ]]; then
        printf '  %-22s %s\n' package-manager "$pm"
    else
        printf '  %-22s %s\n' package-manager missing
        failures=$((failures+1))
    fi

    if command -v sqlite3 >/dev/null 2>&1; then
        printf '  %-22s %s\n' state-db sqlite
    else
        printf '  %-22s %s\n' state-db 'TSV fallback (install sqlite3 for SQLite state)'
    fi

    if [[ -w "$SCRIPT_DIR/log" || ! -e "$SCRIPT_DIR/log" ]]; then
        printf '  %-22s %s\n' logs writable
    else
        printf '  %-22s %s\n' logs not-writable
        failures=$((failures+1))
    fi

    echo ""
    if [[ $failures -eq 0 ]]; then
        echo -e "${OPTION}[✓] Doctor found no blocking issues.${RST}"
    else
        echo -e "${ERROR}[!] Doctor found $failures issue(s).${RST}"
        return 1
    fi
}
