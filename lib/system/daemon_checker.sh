#!/usr/bin/env bash
check_daemon_alerts() {
    # Guard: cannot do anything useful without SCRIPT_DIR
    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        return 0
    fi

    local cache_alert="${HOME}/.config/projectr/.update_alert"

    if [[ -f "$cache_alert" ]]; then
        echo -e "${BOLD_YELLOW} 🔔 [NOTIFICATION] Background daemon: packages need updating!${RST}"
        echo -e "${DIM}    Run [System Upgrade] from the menu or use your package manager.${RST}\n"
        rm -f "$cache_alert"
    fi

    # Only register the cron job if crontab is actually available
    if command -v crontab >/dev/null 2>&1; then
      local cron_line="0 0 * * 0 /bin/bash $SCRIPT_DIR/lib/system/daemon_checker.sh --run-silent"
      (
           crontab -l 2>/dev/null | grep -v "daemon_checker.sh"
           echo "$cron_line"
       ) | crontab - 2>/dev/null || \
           echo -e "${BOLD_YELLOW} [!] Could not register background update cron job.${RST}"
    fi

    # Cron-triggered silent run
    if [[ "${1:-}" == "--run-silent" ]]; then
        local detect_script="$SCRIPT_DIR/lib/system/detect.sh"
        local update_script="$SCRIPT_DIR/lib/update.sh"

        if [[ ! -f "$detect_script" || ! -f "$update_script" ]]; then
            exit 1
        fi
        source "$detect_script" || exit 1
        source "$update_script" || exit 1
        mkdir -p "$(dirname "$cache_alert")"

        # Only write the alert if pkg_update actually succeeds
        if pkg_update >/dev/null 2>&1; then
            echo "1" > "$cache_alert"
        fi
    fi
}
