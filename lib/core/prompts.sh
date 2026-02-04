#!/bin/bash

# -- powerful ask funtion 
ask() {
    # Ultimate y/n prompt with defaults, silent mode, and timeout
    # Usage: ask "Your question" [default] [timeout] [silent]
    # Examples:
    #   ask "Continue?"                    # [y/N] prompt
    #   ask "Continue?" "y"               # Defaults to yes [Y/n]
    #   ask "Continue?" "n" 10           # Times out in 10 seconds
    #   ask "Continue?" "y" 0 "silent"   # Auto-accepts for scripts
    
    local prompt="$1"
    local default="${2:-n}"           # Default to 'n' if not provided
    local timeout="${3:-0}"           # 0 = no timeout
    local silent="${4:-false}"        # Silent mode for scripts
    
    local reply=""
    local result=""  # NEW: Store result internally
    
    local default_upper="$(echo "$default" | tr '[:lower:]' '[:upper:]')"
    local other_option="$( ([ "$default" = "y" ] && echo "n") || echo "y")"
    local other_upper="$(echo "$other_option" | tr '[:upper:]' '[:upper:]')"
    
    # Format prompt with default highlighted
    if [ "$default" = "y" ]; then
        local prompt_text="$prompt [$default_upper/$other_option]"
    else
        local prompt_text="$prompt [$other_option/$default_upper]"
    fi
    
    # Silent mode - just return default without asking
    if [ "$silent" = "true" ] || [ "$silent" = "silent" ]; then
        result="$default"
        # Set result but don't echo it
    else
        # Timeout handling
        if [ "$timeout" -gt 0 ]; then
            echo -n "$prompt_text (Auto-accept '$default' in ${timeout}s): "
            # Use read with timeout
            if read -t "$timeout" -r reply; then
                # User responded
                reply="$(echo "$reply" | tr '[:upper:]' '[:lower:]')"
            else
                # Timeout reached
                echo ""
                echo "  [*] Timeout - using default: $default"
                reply="$default"
            fi
        else
            # Normal prompt
            echo -n "$prompt_text: "
            read -r reply
            reply="$(echo "$reply" | tr '[:upper:]' '[:lower:]')"
        fi
        
        # If empty reply, use default
        if [ -z "$reply" ]; then
            reply="$default"
        fi
        
        # Validate input
        case "$reply" in
            y|yes|yeah|yep|ya|ye|true|1)
                result="y"
                ;;
            n|no|nope|nah|na|false|0)
                result="n"
                ;;
            *)
                # Invalid input, show error and retry
                echo -e "${ERR}  [!] Invalid choice: '$reply'. Please enter y or n.${RST}"
                # Recursive call with same parameters
                ask "$prompt" "$default" "$timeout" "$silent"
                return $?
                ;;
        esac
    fi
    
    # Now handle the result - TWO OPTIONS:
    
    # OPTION A: Return via echo (for $(ask ...) capture)
    # Uncomment this if you want to capture with $(ask ...)
    # echo "$result"
    
    # OPTION B: Return via exit code (for if ask ...; then)
    if [ "$result" = "y" ]; then
        return 0  # Yes = success exit code
    else
        return 1  # No = failure exit code
    fi
}
