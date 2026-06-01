#!/bin/bash
# ask.sh - A production-ready interactive yes/no prompt for Bash.
#
# Usage as a command:
#   ./ask.sh --prompt "Continue?" --yes "Deploy" --cancel "Abort" --default yes --timeout 10
#   if ./ask.sh -p "Delete file?" --yes "Delete" --cancel "Keep" --default no; then ...; fi
#
# Usage as a function:
#   source ./ask.sh
#   if ask --prompt "Continue?" --yes "Yes" --cancel "No"; then ...; fi
#
# Exit codes:
#   0 = yes/confirm selected
#   1 = cancel/no selected
#   2 = usage/configuration error
#   130 = interrupted by Ctrl-C
#
# Designed for Bash 3.2+ and common POSIX-like terminals, including Termux.

# Avoid doing anything when this file is sourced, except defining functions.

ask_rich() {
  # -----------------------------
  # Defaults
  # -----------------------------
  local prompt="Are you sure?"
  local yes_label="Yes"
  local cancel_label="No"
  local default_choice=""       # yes|no|none/empty
  local timeout=""              # positive integer seconds
  local selected="yes"          # yes|no initial cursor position
  local allow_enter_empty=1
  local non_interactive="default" # default|yes|no|fail
  local style="classic"         # classic|plain|minimal|fancy|modern|neon|danger|success
  local align="left"            # left|center|right
  local color="auto"            # auto|always|never
  local icon="?"
  local yes_icon="✓"
  local no_icon="✕"
  local pointer="›"
  local icon_custom=0 yes_icon_custom=0 no_icon_custom=0 pointer_custom=0
  local border=0
  local compact=0
  local quiet=0
  local print_choice=0
  local help_requested=0

  # Internal
  local _arg _next
  local _usage
  _usage='Usage: ask_rich [OPTIONS]

Interactive yes/no prompt with arrows, j/k, h/l, y/n, Enter, Esc/Ctrl-C.

Options:
  -p, --prompt TEXT          Prompt text (default: "Are you sure?")
      --yes TEXT             Label for confirm/yes button (default: "Yes")
      --cancel TEXT          Label for cancel/no button (default: "No")
      --no TEXT              Alias for --cancel
  -d, --default yes|no|none  Choice used on timeout/non-interactive and highlighted initially
  -t, --timeout SECONDS      Auto-select default after SECONDS; requires --default yes/no
      --selected yes|no      Initially selected button (default: default if set, else yes)
      --non-interactive MODE Behavior without a TTY: default, yes, no, fail (default: default)
      --style STYLE          Visual style: classic, plain, minimal, fancy, modern,
                             neon, danger, success (default: classic)
      --align left|center|right
                             Horizontal placement of the prompt block (default: left)
      --color auto|always|never
      --plain                Alias for --style plain --color never
      --fancy                Alias for --style fancy
      --border               Draw a small box around the prompt
      --compact              One-line prompt layout where possible
      --icon TEXT            Prompt icon (default: ?)
      --yes-icon TEXT        Yes icon (default: ✓)
      --no-icon TEXT         No/cancel icon (default: ✕)
      --pointer TEXT         Selection pointer (default: ›)
      --print-choice         Print "yes" or "no" to stdout before returning
  -q, --quiet                Do not print fallback messages in non-interactive mode
  -h, --help                 Show this help

Exit codes: 0 yes, 1 no/cancel, 2 usage/config error, 130 interrupted.

Examples:
  ask -p "Deploy to production?" --yes "Deploy" --cancel "Abort" --default no
  ask -p "Install packages?" --timeout 15 --default yes --border
'

  # -----------------------------
  # Helpers scoped by convention
  # -----------------------------
  ask__err() { printf 'ask: %s\n' "$*" >&2; }
  ask__is_int() { case ${1:-} in ''|*[!0-9]*) return 1;; *) [ "$1" -gt 0 ] 2>/dev/null;; esac; }
  ask__lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
  ask__strip_ansi() { sed 's/\x1b\[[0-9;]*[A-Za-z]//g'; }
  ask__visible_len() { printf '%s' "$1" | ask__strip_ansi | awk '{ print length }'; }
  ask__repeat() { local n=${1:-0} s=${2:- }; local out=""; while [ "$n" -gt 0 ]; do out="$out$s"; n=$((n-1)); done; printf '%s' "$out"; }
  ask__term_cols() {
    local cols
    cols=$(tput cols 2>/dev/null || printf '')
    case $cols in ''|*[!0-9]*) cols=${COLUMNS:-80};; esac
    case $cols in ''|*[!0-9]*) cols=80;; esac
    [ "$cols" -gt 0 ] 2>/dev/null || cols=80
    printf '%s' "$cols"
  }
  ask__align_pad() {
    local width=${1:-0} cols pad
    cols=$(ask__term_cols)
    case $align in
      center) pad=$(( (cols - width) / 2 ));;
      right)  pad=$(( cols - width ));;
      *)      pad=0;;
    esac
    [ "$pad" -gt 0 ] 2>/dev/null || pad=0
    ask__repeat "$pad" ' '
  }

  ask__term_supports_color() {
    [ -t 2 ] || return 1
    [ -n "${NO_COLOR:-}" ] && return 1
    case ${TERM:-dumb} in dumb|unknown|'') return 1;; esac
    if command -v tput >/dev/null 2>&1; then
      local colors
      colors=$(tput colors 2>/dev/null || printf 0)
      [ "${colors:-0}" -ge 8 ] && return 0
    fi
    case ${TERM:-} in *color*|xterm*|screen*|tmux*|rxvt*|linux|vt100) return 0;; esac
    return 1
  }

  ask__supports_utf8() {
    case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in *UTF-8*|*utf8*) return 0;; *) return 1;; esac
  }

  # -----------------------------
  # Parse args
  # -----------------------------
  while [ "$#" -gt 0 ]; do
    _arg=$1
    case $_arg in
      -p|--prompt)
        [ "$#" -ge 2 ] || { ask__err "$_arg requires a value"; return 2; }
        prompt=$2; shift 2;;
      --prompt=*) prompt=${_arg#*=}; shift;;
      --yes)
        [ "$#" -ge 2 ] || { ask__err "--yes requires a value"; return 2; }
        yes_label=$2; shift 2;;
      --yes=*) yes_label=${_arg#*=}; shift;;
      --cancel|--no)
        [ "$#" -ge 2 ] || { ask__err "$_arg requires a value"; return 2; }
        cancel_label=$2; shift 2;;
      --cancel=*|--no=*) cancel_label=${_arg#*=}; shift;;
      -d|--default)
        [ "$#" -ge 2 ] || { ask__err "$_arg requires a value"; return 2; }
        default_choice=$(ask__lower "$2"); shift 2;;
      --default=*) default_choice=$(ask__lower "${_arg#*=}"); shift;;
      -t|--timeout)
        [ "$#" -ge 2 ] || { ask__err "$_arg requires a value"; return 2; }
        timeout=$2; shift 2;;
      --timeout=*) timeout=${_arg#*=}; shift;;
      --selected)
        [ "$#" -ge 2 ] || { ask__err "--selected requires a value"; return 2; }
        selected=$(ask__lower "$2"); shift 2;;
      --selected=*) selected=$(ask__lower "${_arg#*=}"); shift;;
      --non-interactive)
        [ "$#" -ge 2 ] || { ask__err "--non-interactive requires a value"; return 2; }
        non_interactive=$(ask__lower "$2"); shift 2;;
      --non-interactive=*) non_interactive=$(ask__lower "${_arg#*=}"); shift;;
      --style)
        [ "$#" -ge 2 ] || { ask__err "--style requires a value"; return 2; }
        style=$(ask__lower "$2"); shift 2;;
      --style=*) style=$(ask__lower "${_arg#*=}"); shift;;
      --align)
        [ "$#" -ge 2 ] || { ask__err "--align requires a value"; return 2; }
        align=$(ask__lower "$2"); shift 2;;
      --align=*) align=$(ask__lower "${_arg#*=}"); shift;;
      --color)
        [ "$#" -ge 2 ] || { ask__err "--color requires a value"; return 2; }
        color=$(ask__lower "$2"); shift 2;;
      --color=*) color=$(ask__lower "${_arg#*=}"); shift;;
      --plain) style="plain"; color="never"; shift;;
      --fancy) style="fancy"; shift;;
      --border) border=1; shift;;
      --compact) compact=1; shift;;
      --icon)
        [ "$#" -ge 2 ] || { ask__err "--icon requires a value"; return 2; }
        icon=$2; icon_custom=1; shift 2;;
      --icon=*) icon=${_arg#*=}; icon_custom=1; shift;;
      --yes-icon)
        [ "$#" -ge 2 ] || { ask__err "--yes-icon requires a value"; return 2; }
        yes_icon=$2; yes_icon_custom=1; shift 2;;
      --yes-icon=*) yes_icon=${_arg#*=}; yes_icon_custom=1; shift;;
      --no-icon|--cancel-icon)
        [ "$#" -ge 2 ] || { ask__err "$_arg requires a value"; return 2; }
        no_icon=$2; no_icon_custom=1; shift 2;;
      --no-icon=*|--cancel-icon=*) no_icon=${_arg#*=}; no_icon_custom=1; shift;;
      --pointer)
        [ "$#" -ge 2 ] || { ask__err "--pointer requires a value"; return 2; }
        pointer=$2; pointer_custom=1; shift 2;;
      --pointer=*) pointer=${_arg#*=}; pointer_custom=1; shift;;
      --print-choice) print_choice=1; shift;;
      -q|--quiet) quiet=1; shift;;
      -h|--help) help_requested=1; shift;;
      --) shift; break;;
      *) ask__err "unknown option: $_arg"; printf '%s' "$_usage" >&2; return 2;;
    esac
  done

  if [ "$help_requested" -eq 1 ]; then
    printf '%s' "$_usage"
    return 0
  fi

  # -----------------------------
  # Validate config
  # -----------------------------
  case $default_choice in yes|y|true|1) default_choice=yes;; no|n|false|0|cancel) default_choice=no;; none|'') default_choice="";; *) ask__err "--default must be yes, no, or none"; return 2;; esac
  case $selected in yes|y|true|1) selected=yes;; no|n|false|0|cancel) selected=no;; *) ask__err "--selected must be yes or no"; return 2;; esac
  [ -n "$default_choice" ] && selected=$default_choice
  case $non_interactive in default|yes|no|fail) :;; *) ask__err "--non-interactive must be default, yes, no, or fail"; return 2;; esac
  case $style in default|auto|classic) style=classic;; plain|minimal|fancy|modern|neon|danger|success) :;; *) ask__err "--style must be one of: classic, plain, minimal, fancy, modern, neon, danger, success"; return 2;; esac
  case $align in left|center|right) :;; *) ask__err "--align must be left, center, or right"; return 2;; esac
  case $color in auto|always|never) :;; *) ask__err "--color must be auto, always, or never"; return 2;; esac
  if [ -n "$timeout" ]; then
    ask__is_int "$timeout" || { ask__err "--timeout must be a positive integer"; return 2; }
    [ -n "$default_choice" ] || { ask__err "--timeout requires --default yes or --default no"; return 2; }
  fi

  # Plain style is intentionally no-color and ASCII-safe.
  [ "$style" = plain ] && color="never"

  # Color setup. All visual output goes to stderr, so stdout remains clean.
  local use_color=0
  case $color in
    always) use_color=1;;
    never) use_color=0;;
    auto) ask__term_supports_color && use_color=1 || use_color=0;;
  esac

  local C_RESET='' C_BOLD='' C_DIM='' C_BLUE='' C_GREEN='' C_RED='' C_REV='' C_YELLOW='' C_MAGENTA='' C_CYAN='' C_WHITE=''
  if [ "$use_color" -eq 1 ]; then
    C_RESET=$(printf '\033[0m')
    C_BOLD=$(printf '\033[1m')
    C_DIM=$(printf '\033[2m')
    C_BLUE=$(printf '\033[34m')
    C_GREEN=$(printf '\033[32m')
    C_RED=$(printf '\033[31m')
    C_REV=$(printf '\033[7m')
    C_YELLOW=$(printf '\033[33m')
    C_MAGENTA=$(printf '\033[35m')
    C_CYAN=$(printf '\033[36m')
    C_WHITE=$(printf '\033[37m')
  fi

  # Style presets. User-provided icons/pointers still win over the preset.
  local C_ICON="$C_BLUE" C_PROMPT="$C_BOLD" C_YES="$C_GREEN" C_NO="$C_RED" C_HINT="$C_DIM" C_SELECTED="$C_REV"
  case $style in
    plain)
      [ "$icon_custom" -eq 1 ] || icon="?"
      [ "$yes_icon_custom" -eq 1 ] || yes_icon="+"
      [ "$no_icon_custom" -eq 1 ] || no_icon="x"
      [ "$pointer_custom" -eq 1 ] || pointer=">"
      ;;
    minimal)
      compact=1
      [ "$icon_custom" -eq 1 ] || icon="?"
      [ "$yes_icon_custom" -eq 1 ] || yes_icon="yes"
      [ "$no_icon_custom" -eq 1 ] || no_icon="no"
      [ "$pointer_custom" -eq 1 ] || pointer="→"
      C_ICON="$C_DIM"; C_PROMPT="$C_BOLD"; C_YES="$C_GREEN"; C_NO="$C_RED"; C_SELECTED="$C_BOLD"
      ;;
    fancy)
      border=1
      [ "$icon_custom" -eq 1 ] || icon="◆"
      [ "$pointer_custom" -eq 1 ] || pointer="➜"
      C_ICON="$C_YELLOW"; C_PROMPT="$C_BOLD"; C_SELECTED="$C_REV$C_BOLD"
      ;;
    modern)
      [ "$icon_custom" -eq 1 ] || icon="●"
      [ "$pointer_custom" -eq 1 ] || pointer="▸"
      C_ICON="$C_CYAN"; C_PROMPT="$C_BOLD"; C_YES="$C_CYAN"; C_NO="$C_YELLOW"; C_SELECTED="$C_REV$C_BOLD"
      ;;
    neon)
      border=1
      [ "$icon_custom" -eq 1 ] || icon="✦"
      [ "$yes_icon_custom" -eq 1 ] || yes_icon="✧"
      [ "$no_icon_custom" -eq 1 ] || no_icon="✖"
      [ "$pointer_custom" -eq 1 ] || pointer="▶"
      C_ICON="$C_MAGENTA"; C_PROMPT="$C_BOLD$C_CYAN"; C_YES="$C_GREEN"; C_NO="$C_MAGENTA"; C_HINT="$C_DIM$C_CYAN"; C_SELECTED="$C_REV$C_BOLD"
      ;;
    danger)
      border=1
      [ "$icon_custom" -eq 1 ] || icon="!"
      [ "$yes_icon_custom" -eq 1 ] || yes_icon="!"
      [ "$no_icon_custom" -eq 1 ] || no_icon="×"
      [ "$pointer_custom" -eq 1 ] || pointer="»"
      C_ICON="$C_RED"; C_PROMPT="$C_BOLD$C_RED"; C_YES="$C_RED"; C_NO="$C_GREEN"; C_HINT="$C_DIM$C_YELLOW"; C_SELECTED="$C_REV$C_BOLD"
      ;;
    success)
      [ "$icon_custom" -eq 1 ] || icon="✓"
      [ "$yes_icon_custom" -eq 1 ] || yes_icon="✓"
      [ "$no_icon_custom" -eq 1 ] || no_icon="–"
      [ "$pointer_custom" -eq 1 ] || pointer="›"
      C_ICON="$C_GREEN"; C_PROMPT="$C_BOLD$C_GREEN"; C_YES="$C_GREEN"; C_NO="$C_DIM"; C_SELECTED="$C_REV$C_BOLD"
      ;;
  esac

  # ASCII fallback if the terminal is not UTF-8-capable.
  if ! ask__supports_utf8; then
    [ "$icon_custom" -eq 1 ] || icon="?"
    [ "$yes_icon_custom" -eq 1 ] || yes_icon="+"
    [ "$no_icon_custom" -eq 1 ] || no_icon="x"
    [ "$pointer_custom" -eq 1 ] || pointer=">"
  fi

  # -----------------------------
  # Non-interactive fallback
  # -----------------------------
  if ! [ -t 0 ] || ! [ -t 2 ]; then
    local choice rc
    case $non_interactive in
      yes) choice=yes; rc=0;;
      no) choice=no; rc=1;;
      fail) [ "$quiet" -eq 1 ] || ask__err "not running in an interactive terminal"; return 2;;
      default)
        if [ -n "$default_choice" ]; then
          choice=$default_choice
          [ "$choice" = yes ] && rc=0 || rc=1
        else
          [ "$quiet" -eq 1 ] || ask__err "not interactive and no --default provided"
          return 2
        fi;;
    esac
    if [ "$quiet" -ne 1 ]; then
      printf '%s %s [%s]\n' "$icon" "$prompt" "$choice" >&2
    fi
    [ "$print_choice" -eq 1 ] && printf '%s\n' "$choice"
    return "$rc"
  fi

  # -----------------------------
  # Terminal control
  # -----------------------------
  local old_stty=''
  old_stty=$(stty -g 2>/dev/null) || old_stty=''
  # Hide cursor if possible, restore on every exit path.
  printf '\033[?25l' >&2
  # cbreak-ish mode: no echo, one-byte reads, but allow read -t timeout.
  # Disable CR-to-NL translation so Enter arrives as carriage return; otherwise
  # Bash read -n treats newline as a delimiter and stores an empty variable.
  stty -echo -icanon min 0 time 0 -icrnl -inlcr 2>/dev/null || stty -echo -icanon min 0 time 0 2>/dev/null || true

  local cleanup_done=0
  ask__cleanup() {
    [ "$cleanup_done" -eq 1 ] && return 0
    cleanup_done=1
    [ -n "$old_stty" ] && stty "$old_stty" 2>/dev/null || true
    printf '\033[?25h' >&2
  }

  # Note: traps inside functions are global in Bash while active. Restore before return.
  local old_int_trap old_term_trap
  old_int_trap=$(trap -p INT)
  old_term_trap=$(trap -p TERM)
  trap 'ask__cleanup; printf "\n" >&2; trap - INT; return 130 2>/dev/null || exit 130' INT
  trap 'ask__cleanup; printf "\n" >&2; trap - TERM; return 130 2>/dev/null || exit 130' TERM

  local rows=0 last_lines=0 render_mode='' render_maxw=0 render_prefix=''
  ask__render_timer() {
    # Lightweight countdown refresh: redraw only the line containing the timer,
    # leaving the rest of the prompt untouched. Selection changes still use the
    # full renderer because the buttons need to change.
    local remaining=${1:-}
    local timer line1 yes_btn no_btn plain1 len1 pad maxw compact_line compact_plain compact_len prefix

    timer=''
    if [ -n "$remaining" ]; then
      timer=" ${C_DIM}(auto-selects ${default_choice} in ${remaining}s)${C_RESET}"
    elif [ -n "$default_choice" ]; then
      timer=" ${C_DIM}(default: ${default_choice})${C_RESET}"
    fi
    line1="${C_ICON}${icon}${C_RESET} ${C_PROMPT}${prompt}${C_RESET}${timer}"

    # Save cursor, patch only the affected row, then restore cursor. ESC 7/8 is
    # intentionally used for broad terminal support, including Android/Termux.
    printf '\0337' >&2
    case $render_mode in
      border)
        plain1=$(printf '%s' "$line1" | ask__strip_ansi)
        len1=${#plain1}
        maxw=${render_maxw:-$len1}
        [ "$maxw" -gt 0 ] 2>/dev/null || maxw=$len1
        pad=$((maxw - len1)); [ "$pad" -gt 0 ] 2>/dev/null || pad=0
        prefix=$render_prefix
        printf '\033[4A\033[2K\r' >&2
        if [ "$style" = plain ] || ! ask__supports_utf8; then
          printf '%s| %s%s |' "$prefix" "$line1" "$(ask__repeat "$pad" ' ')" >&2
        else
          printf '%s│ %s%s │' "$prefix" "$line1" "$(ask__repeat "$pad" ' ')" >&2
        fi
        ;;
      compact)
        if [ "$selected" = yes ]; then
          yes_btn="${C_SELECTED}${C_YES} ${pointer} ${yes_icon} ${yes_label} ${C_RESET}"
          no_btn=" ${C_NO}${no_icon} ${cancel_label}${C_RESET} "
        else
          yes_btn=" ${C_YES}${yes_icon} ${yes_label}${C_RESET} "
          no_btn="${C_SELECTED}${C_NO} ${pointer} ${no_icon} ${cancel_label} ${C_RESET}"
        fi
        compact_line="$line1  $yes_btn   $no_btn"
        compact_plain=$(printf '%s' "$compact_line" | ask__strip_ansi)
        compact_len=${#compact_plain}
        prefix=$render_prefix
        [ -n "$prefix" ] || prefix=$(ask__align_pad "$compact_len")
        printf '\033[1A\033[2K\r%s%s' "$prefix" "$compact_line" >&2
        ;;
      *)
        prefix=$render_prefix
        [ -n "$prefix" ] || { plain1=$(printf '%s' "$line1" | ask__strip_ansi); prefix=$(ask__align_pad "${#plain1}"); }
        printf '\033[3A\033[2K\r%s%s' "$prefix" "$line1" >&2
        ;;
    esac
    printf '\0338' >&2
  }

  ask__render() {
    local remaining=${1:-}
    local line1 yes_btn no_btn hint timer maxw inner border_line pad

    # Move up and clear previous render.
    if [ "$last_lines" -gt 0 ]; then
      printf '\033[%sA' "$last_lines" >&2
      local i=0
      while [ "$i" -lt "$last_lines" ]; do
        printf '\033[2K\r' >&2
        [ "$i" -lt $((last_lines-1)) ] && printf '\033[1B' >&2
        i=$((i+1))
      done
      printf '\033[%sA' $((last_lines-1)) >&2 2>/dev/null || true
      printf '\r' >&2
    fi

    timer=''
    if [ -n "$remaining" ]; then
      timer=" ${C_DIM}(auto-selects ${default_choice} in ${remaining}s)${C_RESET}"
    elif [ -n "$default_choice" ]; then
      timer=" ${C_DIM}(default: ${default_choice})${C_RESET}"
    fi

    line1="${C_ICON}${icon}${C_RESET} ${C_PROMPT}${prompt}${C_RESET}${timer}"

    if [ "$selected" = yes ]; then
      yes_btn="${C_SELECTED}${C_YES} ${pointer} ${yes_icon} ${yes_label} ${C_RESET}"
      no_btn=" ${C_NO}${no_icon} ${cancel_label}${C_RESET} "
    else
      yes_btn=" ${C_YES}${yes_icon} ${yes_label}${C_RESET} "
      no_btn="${C_SELECTED}${C_NO} ${pointer} ${no_icon} ${cancel_label} ${C_RESET}"
    fi

    hint="${C_HINT}Use ←/→ or ↑/↓, h/l or j/k; Enter to choose; y/n; Esc to cancel.${C_RESET}"

    if [ "$border" -eq 1 ]; then
      local plain1 plain2 plain3 len1 len2 len3
      plain1=$(printf '%s' "$line1" | ask__strip_ansi)
      plain2=$(printf '%s   %s' "$yes_btn" "$no_btn" | ask__strip_ansi)
      plain3=$(printf '%s' "$hint" | ask__strip_ansi)
      len1=${#plain1}; len2=${#plain2}; len3=${#plain3}
      maxw=$len1; [ "$len2" -gt "$maxw" ] && maxw=$len2; [ "$len3" -gt "$maxw" ] && maxw=$len3
      inner=$((maxw + 2))
      local prefix
      prefix=$(ask__align_pad $((maxw + 4)))
      render_mode=border; render_maxw=$maxw; render_prefix=$prefix
      border_line=$(ask__repeat "$inner" '─')
      if [ "$style" = plain ] || ! ask__supports_utf8; then
        border_line=$(ask__repeat "$inner" '-')
        printf '%s+%s+\n' "$prefix" "$border_line" >&2
        printf '%s| %s%s |\n' "$prefix" "$line1" "$(ask__repeat $((maxw-len1)) ' ')" >&2
        printf '%s| %s   %s%s |\n' "$prefix" "$yes_btn" "$no_btn" "$(ask__repeat $((maxw-len2)) ' ')" >&2
        printf '%s| %s%s |\n' "$prefix" "$hint" "$(ask__repeat $((maxw-len3)) ' ')" >&2
        printf '%s+%s+\n' "$prefix" "$border_line" >&2
      else
        printf '%s╭%s╮\n' "$prefix" "$border_line" >&2
        printf '%s│ %s%s │\n' "$prefix" "$line1" "$(ask__repeat $((maxw-len1)) ' ')" >&2
        printf '%s│ %s   %s%s │\n' "$prefix" "$yes_btn" "$no_btn" "$(ask__repeat $((maxw-len2)) ' ')" >&2
        printf '%s│ %s%s │\n' "$prefix" "$hint" "$(ask__repeat $((maxw-len3)) ' ')" >&2
        printf '%s╰%s╯\n' "$prefix" "$border_line" >&2
      fi
      last_lines=5
    elif [ "$compact" -eq 1 ]; then
      local compact_line compact_plain compact_len compact_prefix
      compact_line="$line1  $yes_btn   $no_btn"
      compact_plain=$(printf '%s' "$compact_line" | ask__strip_ansi)
      compact_len=${#compact_plain}
      compact_prefix=$(ask__align_pad "$compact_len")
      render_mode=compact; render_maxw=$compact_len; render_prefix=$compact_prefix
      printf '%s%s\n' "$compact_prefix" "$compact_line" >&2
      last_lines=1
    else
      local buttons_line plain_buttons prefix
      buttons_line="$yes_btn   $no_btn"
      plain1=$(printf '%s' "$line1" | ask__strip_ansi)
      plain_buttons=$(printf '%s' "$buttons_line" | ask__strip_ansi)
      plain3=$(printf '%s' "$hint" | ask__strip_ansi)
      len1=${#plain1}; len2=${#plain_buttons}; len3=${#plain3}
      maxw=$len1; [ "$len2" -gt "$maxw" ] && maxw=$len2; [ "$len3" -gt "$maxw" ] && maxw=$len3
      prefix=$(ask__align_pad "$maxw")
      render_mode=normal; render_maxw=$maxw; render_prefix=$prefix
      printf '%s%s\n%s%s\n%s%s\n' "$prefix" "$line1" "$prefix" "$buttons_line" "$prefix" "$hint" >&2
      last_lines=3
    fi
  }

  local start now elapsed remaining key seq rc choice
  start=$(date +%s 2>/dev/null || printf 0)
  remaining=$timeout
  ask__render "$remaining"

  while :; do
    key=''
    # Use a short read timeout so we can update countdown and remain responsive.
    # If the user presses Enter and the terminal sends NL, Bash read -n treats
    # NL as the line delimiter and returns success with an empty variable. Keep
    # a synthetic newline in that case, while preserving empty-on-timeout.
    if IFS= read -r -s -n 1 -t 0.10 key 2>/dev/null; then
      [ -z "$key" ] && key=$'\n'
    else
      key=''
    fi

    if [ -n "$timeout" ]; then
      now=$(date +%s 2>/dev/null || printf 0)
      elapsed=$((now - start))
      [ "$elapsed" -lt 0 ] && elapsed=0
      local new_remaining=$((timeout - elapsed))
      if [ "$new_remaining" -le 0 ]; then
        selected=$default_choice
        ask__render 0
        choice=$selected
        [ "$choice" = yes ] && rc=0 || rc=1
        break
      fi
      if [ "$new_remaining" != "$remaining" ]; then
        remaining=$new_remaining
        ask__render_timer "$remaining"
      fi
    fi

    [ -z "$key" ] && continue

    case "$key" in
      $'\003') rc=130; printf '\n' >&2; break;; # Ctrl-C
      $'\004') selected=no; rc=1; break;;       # Ctrl-D
      $'\033')
        # Escape sequence or bare Esc. Consume the rest if present.
        seq=''
        IFS= read -r -s -n 1 -t 0.02 seq 2>/dev/null || seq=''
        if [ "$seq" = '[' ]; then
          local seq2=''
          IFS= read -r -s -n 1 -t 0.02 seq2 2>/dev/null || seq2=''
          case "$seq2" in
            A|D) selected=yes; ask__render "$remaining";;  # up/left
            B|C) selected=no; ask__render "$remaining";;   # down/right
          esac
        else
          selected=no; rc=1; break
        fi;;
      '') :;;
      $'\n'|$'\r')
        choice=$selected
        [ "$choice" = yes ] && rc=0 || rc=1
        break;;
      [Yy]) selected=yes; ask__render "$remaining"; choice=yes; rc=0; break;;
      [Nn]) selected=no; ask__render "$remaining"; choice=no; rc=1; break;;
      [HhKk]) selected=yes; ask__render "$remaining";;
      [LlJj]) selected=no; ask__render "$remaining";;
      ' ')
        if [ "$selected" = yes ]; then selected=no; else selected=yes; fi
        ask__render "$remaining";;
      *)
        # Misbehavior-safe: ignore unknown input and keep prompt alive.
        printf '\a' >&2 2>/dev/null || true;;
    esac
  done

  ask__cleanup
  # Ensure the completed prompt does not get overwritten by following output.
  printf '\n' >&2
  trap - INT TERM
  [ -n "$old_int_trap" ] && eval "$old_int_trap"
  [ -n "$old_term_trap" ] && eval "$old_term_trap"

  if [ -z "${choice:-}" ]; then
    choice=$selected
  fi
  if [ "$print_choice" -eq 1 ]; then
    case $rc in
      0) printf 'yes\n';;
      1) printf 'no\n';;
    esac
  fi
  return "$rc"
}

# If executed directly, run ask with CLI args. If sourced, only define ask().
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ask_rich "$@"
  exit $?
fi

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
# Drop this at the bottom of lib/core/prompts.sh
# It's a wrapper that picks the right ask automatically
ask_confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local yes_label="${3:-Yes}"
    local cancel_label="${4:-No}"
    local style="${5:-classic}"
    local timeout="${6:-}"
    local align="${7:-}"

    # Non-interactive: fall back to plain ask()
    if [[ "${NON_INTERACTIVE:-0}" == "1" ]]; then
        ask "$prompt" "$default"
        return $?
    fi

    # No TTY (piped/scripted): same fallback
    if [[ ! -t 0 ]]; then
        ask "$prompt" "$default"
        return $?
    fi

    # Interactive terminal: use the rich version
    ask_rich \
        --prompt "$prompt" \
        --yes "$yes_label" \
        --cancel "$cancel_label" \
        --default "$default" \
        --style "$style" \
        --timeout "$timeout" \
        --align "$align"
    return $?
}
