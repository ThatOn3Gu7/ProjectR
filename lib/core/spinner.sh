#!/bin/bash

# Start a spinner in the background
# $1 -> message to display alongside the spinner
start_spinner() {
    local message="$1"
    local spin_chars="|/-\\"
    local i=0

     # Don't start if already running
     if [ -n "$SPINNER_PID" ]; then
         return 0
     fi

    # Hide cursor
    tput civis 2>/dev/null

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
    # This stops the background spinner
    kill "$SPINNER_PID" >/dev/null 2>&1
    wait "$SPINNER_PID" 2>/dev/null

    # Clear the entire line
    printf "\r\033[2K"

    # Show cursor again
    tput cnorm 2>/dev/null
    unset SPINNER_PID
    echo -e "$1"
}
