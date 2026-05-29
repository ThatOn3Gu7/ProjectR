#!/bin/bash

# Log file path — resolved at source time using SCRIPT_DIR
LOG_FILE="${SCRIPT_DIR:-$(pwd)}/log/install.log"

# _log_init: called once on first log() use to set up the directory and rotation.
# Keeping this in a function means it never runs at source time by accident.
_log_init() {
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"

    if ! mkdir -p "$log_dir" 2>/dev/null; then
        echo "[logging] WARNING: could not create log dir: $log_dir" >&2
        return 1
    fi

    # Rotate if over 100 KB — do it here, not at top level
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
        if (( size > 102400 )); then
            mv "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null || true
        fi
    fi

    # Mark init as done so this only runs once per session
    _LOG_READY=1
}

# Simple log function — safe to call even if display.sh isn't loaded yet
log() {
    local level="$1"
    local message="$2"
    [[ "${_LOG_READY:-0}" != "1" ]] && _log_init
    printf '[%s] [%s] %s\n' "$(date '+%H:%M:%S')" "$level" "$message" \
        >> "$LOG_FILE" 2>/dev/null || true
}
