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
            offset=$(( term_width - box_width - 2 ))
            ;;
        left|*)
            offset=0
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
