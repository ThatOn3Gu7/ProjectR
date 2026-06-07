#!/usr/bin/env bash
# Backwards-compatible wrapper around the v2 scheduler subsystem.

check_daemon_alerts() {
    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        return 0
    fi
    if [[ -f "$SCRIPT_DIR/lib/system/scheduler.sh" ]]; then
        source "$SCRIPT_DIR/lib/system/scheduler.sh"
        projectr_scheduler_show_alert
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$SCRIPT_DIR/lib/system/detect.sh"
    source "$SCRIPT_DIR/lib/system/scheduler.sh"
    if [[ "${1:-}" == "--run-silent" ]]; then
        projectr_scheduler_run_check
    else
        check_daemon_alerts
    fi
fi
