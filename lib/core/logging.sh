#!/bin/bash
# Add at the top of logging.sh:
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log"
LOG_FILE="$LOG_DIR/install.log"
# -- log dir creation --
mkdir -p "$LOG_DIR"
# -- log file cleanup --
[ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 500 ] && mv "$LOG_FILE" "${LOG_FILE}.old"
# -- log function --
log() {
    local level="$1" message="$2"
    printf '[%s] [%s] %s\n' "$(date '+%H:%M:%S')" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true
}