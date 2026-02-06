#!/bin/bash
# -- Small message for installer --
be_patient() {
  clear 
   echo -e "${OPT}${BOLD}"
    boxed_text center "[*] Installation may take a while, Please be patient"
   echo -e "${INFO}${BOLD}"
}

# Print a boxed message centered in the terminal
boxed_text() {
    local align="$1"
    shift
    local text="$*"
    local margin=2

    # Get terminal width
    local term_width
    term_width=$(tput cols)

    # Split text into lines
    IFS=$'\n' read -rd '' -a lines <<< "$text"

    # Find longest line length
    local max_len=0
    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done

    # Box padding
    local padding=2
    local box_width=$(( max_len + padding * 2 ))

    # Calculate alignment offset
    local offset=0
    case "$align" in
        center)
            offset=$(( (term_width - box_width - 2) / 2 ))
            ;;
        right)
            offset=$(( term_width - box_width - 2 - margin ))
            ;;
        left|*)
            offset=$margin
            ;;
    esac

    (( offset < 0 )) && offset=0

    local indent
    indent=$(printf '%*s' "$offset")

    # Top border
    echo "${indent}┌$(printf '─%.0s' $(seq 1 $box_width))┐"

    # Text lines
    for line in "${lines[@]}"; do
        printf "%s│%*s%s%*s│\n" \
            "$indent" \
            "$padding" "" \
            "$line" \
            "$(( box_width - ${#line} - padding ))" ""
    done

    # Bottom border
    echo "${indent}└$(printf '─%.0s' $(seq 1 $box_width))┘"
}

# Prints a message whenever user decides to exit the script.
graceful_exit() {
  log EXIT "Exited script"
   echo ""
    echo -e "${INFO}${BOLD}"
    boxed_text center " Thanks for using the script
     See you next time "
    echo -e "${RST}"
    stop_spinner
    tput cnorm
   exit 0
}

# Boxed list - Perfect for installation summaries
boxed_list() {
    local align="${1:-center}"  # left, center, right
    local title="${2:-}"
    shift 2
    local items=("$@")
    
    local max_width=0
    local padding=2
    local min_box_width=40
    local margin=2  # Minimum space from terminal edge when left/right aligned
    
    # Helper to strip color codes for width calculation
    strip_colors() {
        echo "$1" | sed -E 's/\x1b\[[0-9;]*m//g'
    }
    
    # Find longest item (without color codes)
    for item in "${items[@]}"; do
        local clean_item=$(strip_colors "$item")
        if [ ${#clean_item} -gt $max_width ]; then
            max_width=${#clean_item}
        fi
    done
    
    # Check title length
    if [ -n "$title" ]; then
        local clean_title=$(strip_colors "$title")
        if [ ${#clean_title} -gt $max_width ]; then
            max_width=${#clean_title}
        fi
    fi
    
    # Calculate box width
    local box_width=$((max_width + padding * 2))
    if [ $box_width -lt $min_box_width ]; then
        box_width=$min_box_width
    fi
    
    # Get terminal width for alignment
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)
    
    local offset=0
    case "$align" in
        center)
            offset=$(( (term_width - box_width - 2) / 2 ))
            ;;
        right)
            offset=$(( term_width - box_width - 2 - margin ))
            ;;
        left|*)
            offset=$margin  # Add margin for left alignment
            ;;
    esac
    
    # Ensure offset is not negative
    (( offset < 0 )) && offset=0
    
    local indent=""
    [ $offset -gt 0 ] && indent=$(printf '%*s' $offset)
    
    # Top border
    echo "${indent}╭$(printf '─%.0s' $(seq 1 $box_width))╮"
    
    # Title line (centered within box)
    if [ -n "$title" ]; then
        local title_padding=$(( (box_width - ${#clean_title}) / 2 ))
        printf "%s│%*s%s%*s│\n" \
            "$indent" \
            $title_padding "" \
            "$title" \
            $((box_width - ${#clean_title} - title_padding)) ""
        
        # Separator line under title if we have items
        if [ ${#items[@]} -gt 0 ]; then
            echo "${indent}├$(printf '─%.0s' $(seq 1 $box_width))┤"
        fi
    fi
    
    # Items - left-aligned within box
    for item in "${items[@]}"; do
        local clean_item=$(strip_colors "$item")
        printf "%s│ %-*s │\n" \
            "$indent" \
            $((box_width - 3)) \
            "$item"
    done
    
    # Bottom border
    echo "${indent}╰$(printf '─%.0s' $(seq 1 $box_width))╯"
}

# Boxed text with optional subtitle
boxed_text_full() {
    local align="${1:-center}"  # left, center, right
    local title="${2:-}"
    local subtitle="${3:-}"
    shift 3
    local lines=("$@")
    
    local max_width=0
    local padding=2
    local margin=2
    
    # Find longest line
    for line in "${lines[@]}"; do
        if [ ${#line} -gt $max_width ]; then
            max_width=${#line}
        fi
    done
    [ ${#title} -gt $max_width ] && max_width=${#title}
    [ ${#subtitle} -gt $max_width ] && max_width=${#subtitle}
    
    # Calculate box width
    local box_width=$((max_width + padding * 2))
    
    # Get terminal width and calculate offset
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)
    
    local offset=0
    case "$align" in
        center)
            offset=$(( (term_width - box_width - 2) / 2 ))
            ;;
        right)
            offset=$(( term_width - box_width - 2 - margin ))
            ;;
        left|*)
            offset=$margin
            ;;
    esac
    (( offset < 0 )) && offset=0
    
    local indent=""
    [ $offset -gt 0 ] && indent=$(printf '%*s' $offset)
    
    # Top border
    echo "${indent}┏$(printf '━%.0s' $(seq 1 $box_width))┓"
    
    # Title (if provided)
    if [ -n "$title" ]; then
        printf "%s┃%*s%s%*s┃\n" \
            "$indent" \
            $padding "" \
            "${title}" \
            $((box_width - ${#title} - padding)) ""
        
        # Separator if we have subtitle or content
        if [ -n "$subtitle" ] || [ ${#lines[@]} -gt 0 ]; then
            echo "${indent}┣$(printf '━%.0s' $(seq 1 $box_width))┫"
        fi
    fi
    
    # Subtitle (if provided)
    if [ -n "$subtitle" ]; then
        printf "%s┃%*s%s%*s┃\n" \
            "$indent" \
            $padding "" \
            "${subtitle}" \
            $((box_width - ${#subtitle} - padding)) ""
        
        # Separator if we have content
        if [ ${#lines[@]} -gt 0 ]; then
            echo "${indent}┣$(printf '━%.0s' $(seq 1 $box_width))┫"
        fi
    fi
    
    # Content lines
    for line in "${lines[@]}"; do
        printf "%s┃%*s%s%*s┃\n" \
            "$indent" \
            $padding "" \
            "$line" \
            $((box_width - ${#line} - padding)) ""
    done
    
    # Bottom border
    echo "${indent}┗$(printf '━%.0s' $(seq 1 $box_width))┛"
}
