#!/bin/bash
# -- log creation --
LOG_FILE="log/install.log"
# -- log file cleanup --
[ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 500 ] && mv "$LOG_FILE" "${LOG_FILE}.old"
# just a simple log function 
log() {
    local level="$1"
    local message="$2"

    echo "[$(date '+%H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}
