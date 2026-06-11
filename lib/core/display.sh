#!/bin/bash
# shellcheck disable=all

# Strips ANSI escape codes from a string.
_strip_ansi() {
    printf '%s\n' "$1" | sed "s/$(printf '\033')\[[0-9;]*m//g"
}

# Safely calls tput, suppressing errors if unavailable.
safe_tput() { command -v tput >/dev/null 2>&1 && tput "$@" 2>/dev/null; }

# Shows an installation wait message.
show_install_wait() {
    clear
    echo -e "${OPTION}"
    print_box center "[*] Installation may take a while, Please be patient"
    echo -e "${INFO}"
}

# Draws a rounded box with the title embedded in the top border.
# Usage: print_titled_box [--align left|center|right] "TITLE" "line1" "line2" ...
print_titled_box() {
    local align="center"
    if [[ "$1" == "--align" ]]; then
        align="$2"
        shift 2
    fi

    [[ $# -eq 0 ]] && return 1

    local title="$1"
    shift
    local content_lines=("$@")

    local term_width
    term_width=$(safe_tput cols 2>/dev/null || echo 80)
    (( term_width < 1 )) && term_width=80

    local stripped_title
    stripped_title="$(_strip_ansi "$title")"
    local title_len=${#stripped_title}

    local max_len=0
    local stripped_line
    for line in "${content_lines[@]}"; do
        stripped_line="$(_strip_ansi "$line")"
        (( ${#stripped_line} > max_len )) && max_len=${#stripped_line}
    done

    local interior_width=$(( max_len + 2 ))
    (( title_len + 2 > interior_width )) && interior_width=$(( title_len + 2 ))

    local box_width=$(( interior_width + 2 ))

    local margin=2
    local offset=0
    case "$align" in
        center) offset=$(( (term_width - box_width) / 2 )) ;;
        right)  offset=$(( term_width - box_width - margin )) ;;
        left|*) offset=$margin ;;
    esac
    (( offset < 0 )) && offset=0
    local indent
    indent=$(printf '%*s' "$offset")

    local left_dashes right_dashes
    left_dashes=$(( (interior_width - title_len) / 2 ))
    right_dashes=$(( interior_width - title_len - left_dashes ))

    printf "%s╭" "$indent"
    printf '─%.0s' $(seq 1 $left_dashes)
    printf "%s" "$title"
    printf '─%.0s' $(seq 1 $right_dashes)
    printf "╮\n"

    local raw_line stripped_content visible_len pad_right
    for raw_line in "${content_lines[@]}"; do
        stripped_content="$(_strip_ansi "$raw_line")"
        visible_len=${#stripped_content}
        pad_right=$(( interior_width - 1 - visible_len ))
        (( pad_right < 0 )) && pad_right=0
        printf "%s│ %s%*s│\n" "$indent" "$raw_line" "$pad_right" ""
    done

    printf "%s╰" "$indent"
    printf '─%.0s' $(seq 1 $interior_width)
    printf "╯\n"
}

# Draws a simple box with aligned text (supports multi-line strings).
# Usage: print_box left|center|right "text"
print_box() {
    local align="$1"
    shift
    local text="$*"
    local margin=2

    local term_width=""
    if command -v tput >/dev/null 2>&1; then
        term_width=$(tput cols 2>/dev/null)
    fi
    [[ -z "$term_width" || ! "$term_width" =~ ^[0-9]+$ ]] && term_width="$COLUMNS"
    [[ -z "$term_width" || ! "$term_width" =~ ^[0-9]+$ ]] && term_width=80
    (( term_width < 1 )) && term_width=80

    IFS=$'\n' read -rd '' -a lines <<< "$text"

    local max_len=0
    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done

    local padding=2
    local box_width=$(( max_len + padding * 2 ))

    local offset=0
    case "$align" in
        center) offset=$(( (term_width - box_width - 2) / 2 )) ;;
        right)  offset=$(( term_width - box_width - 2 - margin )) ;;
        left|*) offset=$margin ;;
    esac
    (( offset < 0 )) && offset=0

    local indent
    indent=$(printf '%*s' "$offset")

    echo "${indent}┌$(printf '─%.0s' $(seq 1 $box_width))┐"
    for line in "${lines[@]}"; do
        printf "%s│%*s%s%*s│\n" \
            "$indent" \
            "$padding" "" \
            "$line" \
            "$(( box_width - ${#line} - padding ))" ""
    done
    echo "${indent}└$(printf '─%.0s' $(seq 1 $box_width))┘"
}
# Handles clean exit with a farewell message.
graceful_exit() {
    # Only call log if it's actually loaded — it's sourced after display.sh
    if declare -f log >/dev/null 2>&1; then
        log EXIT "━━━━━━ Exited script at: $(date '+%Y-%m-%d %H:%M') ━━━━━━"
    fi
    echo ""
    echo -e "${INFO}"
    print_box center " Thanks for using the script
     See you next time "
    echo -e "${RST}"
    # Only call stop_spinner if loaded — spinner.sh is sourced after display.sh
    if declare -f stop_spinner >/dev/null 2>&1; then
        stop_spinner
    fi
    safe_tput cnorm
    exit 0
}
# Draws a rounded box with a centered title, separator, and left-aligned list items.
# Usage: print_list_box left|center|right "TITLE" "item1" "item2" ...
print_list_box() {
    local align="${1:-center}"
    local title="${2:-}"
    shift 2
    local items=("$@")

    local max_width=0
    local padding=2
    local min_box_width=40
    local margin=2

    for item in "${items[@]}"; do
        local clean_item; clean_item="$(_strip_ansi "$item")"
        (( ${#clean_item} > max_width )) && max_width=${#clean_item}
    done

    local clean_title=""
    if [[ -n "$title" ]]; then
        clean_title="$(_strip_ansi "$title")"
        (( ${#clean_title} > max_width )) && max_width=${#clean_title}
    fi

    local box_width=$(( max_width + padding * 2 ))
    (( box_width < min_box_width )) && box_width=$min_box_width

    local term_width
    term_width=$(safe_tput cols 2>/dev/null || echo 80)

    local offset=0
    case "$align" in
        center) offset=$(( (term_width - box_width - 2) / 2 )) ;;
        right)  offset=$(( term_width - box_width - 2 - margin )) ;;
        left|*) offset=$margin ;;
    esac
    (( offset < 0 )) && offset=0

    local indent=""
    (( offset > 0 )) && indent=$(printf '%*s' $offset)

    echo "${indent}╭$(printf '─%.0s' $(seq 1 $box_width))╮"

    if [[ -n "$title" ]]; then
        local title_pad=$(( (box_width - ${#clean_title}) / 2 ))
        local title_pad_right=$(( box_width - ${#clean_title} - title_pad ))
        printf "%s│%*s%s%*s│\n" "$indent" $title_pad "" "$title" $title_pad_right ""
        (( ${#items[@]} > 0 )) && echo "${indent}├$(printf '─%.0s' $(seq 1 $box_width))┤"
    fi

    for item in "${items[@]}"; do
        local clean_item; clean_item="$(_strip_ansi "$item")"
        local pad=$(( box_width - ${#clean_item} - 2 ))
        (( pad < 0 )) && pad=0
        printf "%s│ %s%*s │\n" "$indent" "$item" "$pad" ""
    done

    echo "${indent}╰$(printf '─%.0s' $(seq 1 $box_width))╯"
}

# Draws a bold box with optional title, subtitle, and content lines.
# Usage: print_header_box left|center|right "TITLE" "SUBTITLE" "line1" "line2" ...
print_header_box() {
    local align="${1:-center}"
    local title="${2:-}"
    local subtitle="${3:-}"
    shift 3
    local lines=("$@")

    local max_width=0
    local padding=2
    local margin=2

    for line in "${lines[@]}"; do
        local clean_line; clean_line="$(_strip_ansi "$line")"
        (( ${#clean_line} > max_width )) && max_width=${#clean_line}
    done

    local clean_title="";    [[ -n "$title" ]]    && clean_title="$(_strip_ansi "$title")"
    local clean_subtitle=""; [[ -n "$subtitle" ]] && clean_subtitle="$(_strip_ansi "$subtitle")"
    (( ${#clean_title}    > max_width )) && max_width=${#clean_title}
    (( ${#clean_subtitle} > max_width )) && max_width=${#clean_subtitle}

    local box_width=$(( max_width + padding * 2 ))

    local term_width
    term_width=$(safe_tput cols 2>/dev/null || echo 80)

    local offset=0
    case "$align" in
        center) offset=$(( (term_width - box_width - 2) / 2 )) ;;
        right)  offset=$(( term_width - box_width - 2 - margin )) ;;
        left|*) offset=$margin ;;
    esac
    (( offset < 0 )) && offset=0

    local indent=""
    (( offset > 0 )) && indent=$(printf '%*s' $offset)

    echo "${indent}┏$(printf '━%.0s' $(seq 1 $box_width))┓"

    if [[ -n "$title" ]]; then
        local pad_right=$(( box_width - ${#clean_title} - padding ))
        printf "%s┃%*s%s%*s┃\n" "$indent" $padding "" "$title" $pad_right ""
        if [[ -n "$subtitle" || ${#lines[@]} -gt 0 ]]; then
            echo "${indent}┣$(printf '━%.0s' $(seq 1 $box_width))┫"
        fi
    fi

    if [[ -n "$subtitle" ]]; then
        local pad_right=$(( box_width - ${#clean_subtitle} - padding ))
        printf "%s┃%*s%s%*s┃\n" "$indent" $padding "" "$subtitle" $pad_right ""
        (( ${#lines[@]} > 0 )) && echo "${indent}┣$(printf '━%.0s' $(seq 1 $box_width))┫"
    fi

    for line in "${lines[@]}"; do
        local clean_line; clean_line="$(_strip_ansi "$line")"
        local pad_right=$(( box_width - ${#clean_line} - padding ))
        printf "%s┃%*s%s%*s┃\n" "$indent" $padding "" "$line" $pad_right ""
    done

    echo "${indent}┗$(printf '━%.0s' $(seq 1 $box_width))┛"
}
