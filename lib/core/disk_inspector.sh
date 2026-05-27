#!/usr/bin/env bash

assert_disk_space() {
    # Extract structural free space metrics relative to the home path installation scope block target
    local available_space
    available_space=$(df -m "$HOME" | awk 'NR==2 {print $4}') # Result in Megabytes

    # Require 2500 Megabytes minimum margin default limit ceiling metric allocation parameter
    if (( available_space < 2500 )); then
        echo -e "${BOLD_YELLOW} ⚠️ [DISK WARNING] Low disk space threshold caught! Available: ${available_space}MB.${RST}"
        if ! ask "    Do you wish to bypass structural warnings and proceed with processing?" "n"; then
            echo -e "${ERROR} [✗] Halting processing steps due to storage safety parameters.${RST}"
            exit 1
        fi
    fi
}

