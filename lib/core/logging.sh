#!/bin/bash
# -- log dir creation if not created already --
LOG_FILE="log/install.log"
mkdir -p "$(dirname "$LOG_FILE")"

# -- log file cleanup: rotate if over 100KB --
if [ -f "$LOG_FILE" ]; then
    local_size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    [ "$local_size" -gt 102400 ] && mv "$LOG_FILE" "${LOG_FILE}.old"
fi

# Simple log function
log() {
    local level="$1"
    local message="$2"
    printf '[%s] [%s] %s\n' "$(date '+%H:%M:%S')" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true
}