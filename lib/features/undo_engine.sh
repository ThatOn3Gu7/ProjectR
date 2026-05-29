#!/usr/bin/env bash
# -- rollback last session function --
rollback_last_session() {
    # Guard: SCRIPT_DIR must be set
    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        echo -e "${ERROR} [✗] SCRIPT_DIR is not set — cannot locate session history.${RST}"
        return 1
    fi

    local history_file="$SCRIPT_DIR/log/session_history.tmp"

    if [[ ! -f "$history_file" || ! -s "$history_file" ]]; then
        echo -e "${OPTION} [!] No recent installations found to undo.${RST}"
        return 0
    fi

    # Guard: uninstall_pkg must be loaded
    if ! declare -f uninstall_pkg >/dev/null 2>&1; then
        echo -e "${ERROR} [✗] uninstall_pkg is not loaded — source uninstaller.sh first.${RST}"
        return 1
    fi

    echo -e "${ERROR} [!] WARNING: Reversing last session's installations...${RST}"
    echo ""

    # Three-tier fallback for reversing line order
    local reverse_cmd
    if command -v tac >/dev/null 2>&1; then
        reverse_cmd="tac"
    elif tail -r /dev/null >/dev/null 2>&1; then
        reverse_cmd="tail -r"
    else
        reverse_cmd="awk '{lines[NR]=\$0} END{for(i=NR;i>=1;i--) print lines[i]}'"
    fi

    local rolled=0 failed=0
    while IFS="|" read -r timestamp cmd pkg; do
        if [[ -z "$cmd" || -z "$pkg" ]]; then
            echo -e "${BOLD_YELLOW} [!] Skipping malformed history entry.${RST}"
            continue
        fi
        echo -e "${INFO} [*] Rolling back: $cmd ($pkg)...${RST}"
        export NON_INTERACTIVE=1
        if uninstall_pkg "$cmd" "$pkg" "$cmd"; then
            ((rolled++))
        else
            ((failed++))
            echo -e "${ERROR} [!] Failed to roll back: $cmd${RST}"
        fi
        unset NON_INTERACTIVE
    done < <(eval "$reverse_cmd \"$history_file\"")

    > "$history_file"
    echo ""
    echo -e "${BOLD_GREEN} [✓] Rollback complete: ${rolled} removed, ${failed} failed.${RST}"
    [[ $failed -gt 0 ]] && return 1 || return 0
}
