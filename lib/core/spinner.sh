#!/bin/bash

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

    # Hide cursor
    safe_tput civis 2>/dev/null

    # Run spinner in background
    (
        while :; do
            printf "\r%s %s" "$message" "${spin_chars:i++%${#spin_chars}:1}"
            sleep 0.1
        done
    ) &
     SPINNER_PID=$!
}
# Stop the spinner
stop_spinner() {
    [[ -z "${SPINNER_PID:-}" ]] && { printf "\r\033[2K"; echo -e "$1"; return 0; }
    # Send SIGTERM, then wait with timeout
    kill "$SPINNER_PID" 2>/dev/null
    local waited=0
    while kill -0 "$SPINNER_PID" 2>/dev/null && (( waited < 10 )); do
        sleep 0.05; (( waited++ ))
    done
    wait "$SPINNER_PID" 2>/dev/null
    printf "\r\033[2K"
    safe_tput cnorm 2>/dev/null
    unset SPINNER_PID
    [[ -n "${1:-}" ]] && echo -e "$1"
}