#!/usr/bin/env bash
# shellcheck disable=all

rollback_last_session() {
    local transaction_id action action_id tool_id name package manager install_type command_name status rollback_status

    if ! declare -f projectr_state_last_transaction_id >/dev/null 2>&1; then
        echo -e "${ERROR} [✗] State tracking is not loaded — cannot locate rollback actions.${RST}"
        return 1
    fi

    transaction_id=$(projectr_state_last_transaction_id)
    if [[ -z "$transaction_id" ]]; then
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

    echo -e "${ERROR} [!] WARNING: Reversing last session's installations for transaction ${transaction_id}...${RST}"
    echo ""

    local rolled=0 failed=0
    while IFS=$'\t' read -r action_id tool_id name package manager install_type command_name status rollback_status; do
        [[ -n "$action_id" ]] || continue
        [[ "$status" == "installed" ]] || continue
        [[ "$rollback_status" == "done" ]] && continue

        echo -e "${INFO} [*] Rolling back: $name ($package) installed via $manager...${RST}"
        export NON_INTERACTIVE=1
        export PROJECTR_UNINSTALL_MANAGER_OVERRIDE="$manager"
        local ok=0
        case "$install_type" in
            pip|pip3|pipx|npm|yarn|pnpm|bun|gem|cargo|go|composer)
                uninstall_lang "$manager" "$package" "$name" "$command_name" && ok=1
                ;;
            *)
                uninstall_pkg "$command_name" "$package" "$name" && ok=1
                ;;
        esac
        unset NON_INTERACTIVE PROJECTR_UNINSTALL_MANAGER_OVERRIDE

        if [[ $ok -eq 1 ]]; then
            ((rolled++))
            projectr_state_mark_action_status "$action_id" 'done' || true
        else
            ((failed++))
            projectr_state_mark_action_status "$action_id" 'failed' || true
            echo -e "${ERROR} [!] Failed to roll back: $name${RST}"
        fi
    done < <(projectr_state_transaction_actions "$transaction_id")

    echo ""
    echo -e "${BOLD_GREEN} [✓] Rollback complete: ${rolled} removed, ${failed} failed.${RST}"
    [[ $failed -gt 0 ]] && return 1 || return 0
}
