#!/bin/bash

# Background spinner containment. The spinner is deliberately managed from the
# parent shell so SIGINT/SIGTERM/EXIT can always reap the worker before normal
# shutdown handlers continue.
projectr_spinner_cleanup() {
    if [ -n "${SPINNER_PID:-}" ]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        unset SPINNER_PID
    fi
    printf "\r\033[2K"
    safe_tput cnorm 2>/dev/null || true
}

projectr_spinner_signal() {
    local sig="$1" fallback_status="$2" old_trap="$3"
    projectr_spinner_cleanup
    projectr_spinner_restore_traps
    if [ -n "$old_trap" ]; then
        kill -s "$sig" "$$" 2>/dev/null || exit "$fallback_status"
    else
        exit "$fallback_status"
    fi
}

projectr_spinner_install_traps() {
    [ -z "${PROJECTR_SPINNER_TRAPS_INSTALLED:-}" ] || return 0
    PROJECTR_SPINNER_OLD_EXIT=$(trap -p EXIT || true)
    PROJECTR_SPINNER_OLD_INT=$(trap -p INT || true)
    PROJECTR_SPINNER_OLD_TERM=$(trap -p TERM || true)
    PROJECTR_SPINNER_OLD_HUP=$(trap -p HUP || true)
    PROJECTR_SPINNER_TRAPS_INSTALLED=1

    trap 'projectr_spinner_cleanup; if [ -n "${PROJECTR_SPINNER_OLD_EXIT:-}" ]; then eval "$PROJECTR_SPINNER_OLD_EXIT"; fi' EXIT
    trap 'projectr_spinner_signal INT 130 "${PROJECTR_SPINNER_OLD_INT:-}"' INT
    trap 'projectr_spinner_signal TERM 143 "${PROJECTR_SPINNER_OLD_TERM:-}"' TERM
    trap 'projectr_spinner_signal HUP 129 "${PROJECTR_SPINNER_OLD_HUP:-}"' HUP
}

projectr_spinner_restore_traps() {
    [ -n "${PROJECTR_SPINNER_TRAPS_INSTALLED:-}" ] || return 0

    if [ -n "${PROJECTR_SPINNER_OLD_EXIT:-}" ]; then eval "$PROJECTR_SPINNER_OLD_EXIT"; else trap - EXIT; fi
    if [ -n "${PROJECTR_SPINNER_OLD_INT:-}" ]; then eval "$PROJECTR_SPINNER_OLD_INT"; else trap - INT; fi
    if [ -n "${PROJECTR_SPINNER_OLD_TERM:-}" ]; then eval "$PROJECTR_SPINNER_OLD_TERM"; else trap - TERM; fi
    if [ -n "${PROJECTR_SPINNER_OLD_HUP:-}" ]; then eval "$PROJECTR_SPINNER_OLD_HUP"; else trap - HUP; fi

    unset PROJECTR_SPINNER_TRAPS_INSTALLED \
          PROJECTR_SPINNER_OLD_EXIT PROJECTR_SPINNER_OLD_INT \
          PROJECTR_SPINNER_OLD_TERM PROJECTR_SPINNER_OLD_HUP
}

# Start a spinner in the background
# $1 -> message to display alongside the spinner
start_spinner() {
    local message="$1"
    local spin_chars="|/-\\"
    local i=0

    # Don't start if already running
    if [ -n "${SPINNER_PID:-}" ]; then
        return 0
    fi

    projectr_spinner_install_traps

    # Hide cursor
    safe_tput civis 2>/dev/null || true

    # Run spinner in background
    (
        trap 'exit 0' TERM INT HUP
        while :; do
            printf "\r%s %s" "$message" "${spin_chars:i++%${#spin_chars}:1}"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
    # Brief yield so the subshell reaches its loop before any immediate stop_spinner call
    sleep 0.05 2>/dev/null || true
}

# Stop the spinner
stop_spinner() {
    if [ -z "${SPINNER_PID:-}" ]; then
        printf "\r\033[2K"
        safe_tput cnorm 2>/dev/null || true
        projectr_spinner_restore_traps
        [ -n "${1:-}" ] && echo -e "$1"
        return 0
    fi

    projectr_spinner_cleanup
    projectr_spinner_restore_traps
    [ -n "${1:-}" ] && echo -e "$1"
}
