#!/bin/bash

# -- powerful ask funtion 
ask() {
    local prompt="$1"
    local default="${2:-n}"
    local timeout="${3:-0}"
    local silent="${4:-false}"

    # Silent mode — return default immediately without prompting
    if [[ "$silent" == "true" || "$silent" == "silent" ]]; then
        [[ "$default" == "y" ]] && return 0 || return 1
    fi

    local yn_hint
    [[ "$default" == "y" ]] && yn_hint="[Y/n]" || yn_hint="[y/N]"

    local reply
    # Loop until valid input — no recursion, no stack risk
    while true; do
        if (( timeout > 0 )); then
            printf '%s %s (auto: %s in %ds): ' "$prompt" "$yn_hint" "$default" "$timeout"
            if ! read -t "$timeout" -r reply; then
                echo ""
                echo "  [*] Timed out — using default: $default"
                reply="$default"
            fi
        else
            printf '%s %s: ' "$prompt" "$yn_hint"
            read -r reply
        fi

        reply="${reply:-$default}"
        reply="${reply,,}"   # lowercase (bash 4+)

        case "$reply" in
            y|yes|yeah|yep|ya|ye|true|1) return 0 ;;
            n|no|nope|nah|na|false|0)    return 1 ;;
            *) echo -e "${ERROR:-}  [!] Invalid: '$reply' — please enter y or n.${RST:-}" ;;
        esac
    done
}
