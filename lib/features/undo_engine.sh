#!/usr/bin/env bash
# -- rollback last session function --
rollback_last_session() {
    local history_file="$SCRIPT_DIR/log/session_history.tmp"
    
    if [[ ! -f "$history_file" || ! -s "$history_file" ]]; then
        echo -e "${OPTION} [!] No recent structural installations found to undo.${RST}"
        return 0
    fi

    echo -e "${ERROR} [!] WARNING: Reversing installations from the last session...${RST}"
    echo ""

    # Read backward using tac (or tail alternative if tac isn't available)
    local reverse_cmd="tac"
    command -v tac >/dev/null 2>&1 || reverse_cmd="tail -r"

    $reverse_cmd "$history_file" | while IFS="|" read -r timestamp cmd pkg; do
        echo -e "${INFO} [*] Rolling back: $cmd ($pkg)...${RST}"
        
        # Accessing your global uninstall_pkg from uninstaller.sh safely without interaction prompt
        export NON_INTERACTIVE=1
        uninstall_pkg "$cmd" "$pkg" "$cmd"
        unset NON_INTERACTIVE
    done

    # Clean up state storage file after complete reversal
    > "$history_file"
    echo -e "${BOLD_GREEN} [✓] Rollback completed successfully.${RST}"
}
