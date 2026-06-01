#!/usr/bin/env bash
# -- rollback last session function --
rollback_last_session() {
    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        echo -e "${ERROR} [✗] SCRIPT_DIR is not set — cannot locate session history.${RST}"
        return 1
    fi

    local history_file="$SCRIPT_DIR/log/session_history.tmp"

    if [[ ! -f "$history_file" || ! -s "$history_file" ]]; then
        echo -e "${OPTION} [!] No recent installations found to undo.${RST}"
        return 0
    fi

    if ! declare -f uninstall_pkg >/dev/null 2>&1; then
        echo -e "${ERROR} [✗] uninstall_pkg is not loaded — source uninstaller.sh first.${RST}"
        return 1
    fi
    if ! declare -f uninstall_lang >/dev/null 2>&1; then
        echo -e "${ERROR} [✗] uninstall_lang is not loaded — source uninstaller.sh first.${RST}"
        return 1
    fi

    echo -e "${ERROR} [!] WARNING: Reversing last session's installations...${RST}"
    echo ""

    # Safe reverse — no eval
    local reversed
    if command -v tac >/dev/null 2>&1; then
        reversed=$(tac "$history_file")
    else
        reversed=$(awk '{lines[NR]=$0} END{for(i=NR;i>=1;i--) print lines[i]}' "$history_file")
    fi

    local rolled=0 failed=0
    while IFS="|" read -r timestamp cmd pkg method; do
        if [[ -z "$cmd" || -z "$pkg" ]]; then
            echo -e "${BOLD_YELLOW} [!] Skipping malformed history entry.${RST}"
            continue
        fi

        method="${method:-pkg}"
        echo -e "${INFO} [*] Rolling back: $cmd ($pkg) installed via $method...${RST}"

        export NON_INTERACTIVE=1
        local ok=0
        case "$method" in
            pip|pip3|pipx|npm|yarn|gem|cargo)
                uninstall_lang "$method" "$pkg" "$cmd" && ok=1
                ;;
            *)
                uninstall_pkg "$cmd" "$pkg" "$cmd" && ok=1
                ;;
        esac
        unset NON_INTERACTIVE

        if [[ $ok -eq 1 ]]; then
            ((rolled++))
        else
            ((failed++))
            echo -e "${ERROR} [!] Failed to roll back: $cmd${RST}"
        fi
    done <<< "$reversed"

    > "$history_file"
    echo ""
    echo -e "${BOLD_GREEN} [✓] Rollback complete: ${rolled} removed, ${failed} failed.${RST}"
    [[ $failed -gt 0 ]] && return 1 || return 0
}
