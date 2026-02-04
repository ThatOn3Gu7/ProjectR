#!/bin/bash

# -- log creation --
LOG_FILE="$HOME/ProjectR/log/install.log"

# just a simple log function 
log() {
    local level="$1"
    local message="$2"

    echo "[$(date '+%H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}
