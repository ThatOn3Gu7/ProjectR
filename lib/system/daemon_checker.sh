#!/usr/bin/env bash
# File: lib/system/daemon_checker.sh

check_daemon_alerts() {
    local cache_alert="${HOME}/.config/projectr/.update_alert"
    if [[ -f "$cache_alert" ]]; then
        echo -e "${BOLD_YELLOW} 🔔 [NOTIFICATION] Your background updates daemon notes packages require updating!${RST}"
        echo -e "${DIM}    Run option [System Upgrade] from menus or use your native package manager.${RST}\n"
        rm -f "$cache_alert" # Clear notice after single visualization
    fi
    
    # Auto setup daemon to run weekly via cron if missing
    if ! crontab -l 2>/dev/null | grep -q "daemon_checker.sh"; then
        (crontab -l 2>/dev/null; echo "0 0 * * 0 /bin/bash $SCRIPT_DIR/lib/system/daemon_checker.sh --run-silent") | crontab -
    fi

    # Trigger internal silent runtime execution if flags are passed by cron engine
    if [[ "${1:-}" == "--run-silent" ]]; then
        source "$SCRIPT_DIR/lib/system/detect.sh"
        source "$SCRIPT_DIR/lib/update.sh"
        pkg_update >/dev/null 2>&1
        # If successfully processed changes, touch file
        mkdir -p "$(dirname "$cache_alert")"
        echo "1" > "$cache_alert"
    fi
}
