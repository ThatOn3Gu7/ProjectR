#!/bin/bash
# shellcheck disable=all
# -- Catches any bugs and unbound variables --
set -uo pipefail
# -- Resolve the project root (works regardless of where you call this from) --
# BASH_SOURCE[0] is always the path to THIS file (main.sh), even if it's
# called from another directory or via a symlink.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# -- export for use outside main.sh --
export SCRIPT_DIR
printf -v PROJECTR_ORIGINAL_ARGS '%q ' "$@"
export PROJECTR_ORIGINAL_ARGS="${PROJECTR_ORIGINAL_ARGS% }"

# Fast-path the read-only help/version commands before loading the complete
# installer stack. This keeps common CLI discovery commands responsive on slow
# shells while preserving the full runtime path for every mutating action.
_projectr_fast_cli() {
  [[ $# -gt 0 ]] || return 0
  local arg no_color=0 source_next=0 action=""
  for arg in "$@"; do
    if [[ $source_next -eq 1 ]]; then
      source_next=0
      continue
    fi
    case "$arg" in
    --no-color) no_color=1 ;;
    --quiet) ;;
    --source) source_next=1 ;;
    --source=*) ;;
    *)
      action="$arg"
      break
      ;;
    esac
  done

  case "$action" in
  --version | -v | version)
    source "$SCRIPT_DIR/lib/data/config.sh"
    source "$SCRIPT_DIR/lib/core/colours.sh"
    if [[ $no_color -eq 1 ]]; then
      RST="" OPTION="" BOLD_WHITE=""
    fi
    echo -e "${OPTION}projectr ${BOLD_WHITE}v1.4${RST}"
    exit 0
    ;;
  --help | -h | help)
    source "$SCRIPT_DIR/lib/data/config.sh"
    source "$SCRIPT_DIR/lib/core/colours.sh"
    source "$SCRIPT_DIR/lib/core/cli.sh"
    [[ $no_color -eq 1 ]] && projectr_disable_color
    projectr_cli_help
    exit 0
    ;;
  esac
}
_projectr_fast_cli "$@"

# -- Now source everything using $SCRIPT_DIR as the anchor --
# -- source conf first (flags need colours/display) --
source "$SCRIPT_DIR/lib/data/config.sh"
source "$SCRIPT_DIR/lib/core/colours.sh"
source "$SCRIPT_DIR/lib/core/display.sh"
source "$SCRIPT_DIR/lib/core/logging.sh"
source "$SCRIPT_DIR/lib/core/array_context.sh"
source "$SCRIPT_DIR/lib/core/strict_mode.sh"
source "$SCRIPT_DIR/lib/core/session.sh"
source "$SCRIPT_DIR/lib/system/detect.sh"
source "$SCRIPT_DIR/lib/system/privilege.sh"
source "$SCRIPT_DIR/lib/system/resolver.sh"
source "$SCRIPT_DIR/lib/security/verify.sh"
detect_pkg_manager >/dev/null
source "$SCRIPT_DIR/lib/data/tool_meta.sh"
source "$SCRIPT_DIR/lib/data/tools.sh"
source "$SCRIPT_DIR/lib/features/plugin_loader.sh"
projectr_load_tool_plugins
source "$SCRIPT_DIR/lib/features/snapshot.sh"
source "$SCRIPT_DIR/lib/features/installer.sh"
source "$SCRIPT_DIR/lib/features/uninstaller.sh"
# -- source support libraries before dispatching non-interactive commands --
source "$SCRIPT_DIR/lib/core/progress_bar.sh"
source "$SCRIPT_DIR/lib/core/spinner.sh"
source "$SCRIPT_DIR/lib/core/prompts.sh"
source "$SCRIPT_DIR/lib/system/network.sh"
source "$SCRIPT_DIR/lib/system/checker.sh"
source "$SCRIPT_DIR/lib/system/dependencies.sh"
source "$SCRIPT_DIR/lib/features/presets.sh"
source "$SCRIPT_DIR/lib/features/post_install.sh"
source "$SCRIPT_DIR/lib/features/search_install.sh"
source "$SCRIPT_DIR/lib/features/special_setup.sh"
source "$SCRIPT_DIR/lib/features/sync.sh"
source "$SCRIPT_DIR/lib/features/state.sh"
source "$SCRIPT_DIR/lib/features/dry_run.sh"
source "$SCRIPT_DIR/lib/features/doctor.sh"
source "$SCRIPT_DIR/lib/features/profile_code.sh"
source "$SCRIPT_DIR/lib/features/configurator.sh"
source "$SCRIPT_DIR/lib/features/tool_audit.sh"
source "$SCRIPT_DIR/lib/features/profile_manager.sh"
source "$SCRIPT_DIR/lib/features/undo_engine.sh"
source "$SCRIPT_DIR/lib/system/scheduler.sh"
source "$SCRIPT_DIR/lib/sub_menus/presets_menu.sh"
source "$SCRIPT_DIR/lib/sub_menus/uninstall_menu.sh"
# -- source CLI helpers, then use flags.sh as the single command/flag dispatcher --
source "$SCRIPT_DIR/lib/core/cli.sh"
source "$SCRIPT_DIR/lib/flags/flags.sh"
trap 'graceful_exit' SIGINT SIGTERM SIGHUP
# -- small helper function for when lolcat isn't around --
rainbow() { command -v lolcat >/dev/null 2>&1 && lolcat || cat; }
projectr_runtime_prepare "$@" || exit $?
projectr_scheduler_show_alert
parse_flags "$@"
PROJECTR_VISIBLE_TOOL_COUNT=${PROJECTR_VISIBLE_TOOL_COUNT:-${PROJECTR_TOOL_PAGE_SIZE_DEFAULT:-50}}
# -- main installer menu  --
show_main_menu() {
  clear
  # cool LOGO with colors
  rainbow <<"EOF"

    ██▓███   ██▀███   ▒█████   ▄████▄  ▓█████   ██████     ██▀███  
   ▓██░  ██▒▓██ ▒ ██▒▒██▒  ██▒▒██▀ ▀█  ▓█   ▀ ▒██    ▒    ▓██ ▒ ██▒
   ▓██░ ██▓▒▓██ ░▄█ ▒▒██░  ██▒▒▓█    ▄ ▒███   ░ ▓██▄      ▓██ ░▄█ ▒
   ▒██▄█▓▒ ▒▒██▀▀█▄  ▒██   ██░▒▓▓▄ ▄██▒▒▓█  ▄   ▒   ██▒   ▒██▀▀█▄  
   ▒██▒ ░  ░░██▓ ▒██▒░ ████▓▒░▒ ▓███▀ ░░▒████▒▒██████▒▒   ░██▓ ▒██▒
   ▒▓▒░ ░  ░░ ▒▓ ░▒▓░░ ▒░▒░▒░ ░ ░▒ ▒  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░   ░ ▒▓ ░▒▓░
   ░▒ ░       ░▒ ░ ▒░  ░ ▒ ▒░   ░  ▒    ░ ░  ░░ ░▒  ░ ░     ░▒ ░ ▒░
   ░░         ░░   ░ ░ ░ ░ ▒  ░           ░   ░  ░  ░       ░░   ░ 
               ░         ░ ░  ░ ░         ░  ░      ░        ░     
                              ░                                    
                                           > C0ded by: ThatOn3Gu7
EOF

  echo -e "${OPTION}"
  print_box left "◇ Select the pkg/tool you want to install:"
  echo -e "${RST}"
  echo -e "${BARR}  ┌────────────────────┐ ${RST}"
  echo -e "${BARR}  │${RST} ${BOLD_BRIGHT_GREEN}☰ Available Tool   ${BARR}│ ${RST}"
  echo -e "${BARR}  ├─────────────────────────────────────────────┐${RST}"
  # Loop through the visible page of TOOLS and print a menu line for it.
  # The full registry is large, so the menu starts at 50 tools and can load more.
  local total_tools=${#TOOLS[@]}
  local visible_count=${PROJECTR_VISIBLE_TOOL_COUNT:-${PROJECTR_TOOL_PAGE_SIZE_DEFAULT:-50}}
  ((visible_count > total_tools)) && visible_count=$total_tools
  PROJECTR_VISIBLE_TOOL_COUNT=$visible_count

  local idx entry
  for ((idx = 0; idx < visible_count; idx++)); do
    entry="${TOOLS[$idx]}"
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    printf "${BARR}  │${RST}${OPTION} [${BRIGHT_WHITE}%03d${OPTION}] %-13s ${INFO}- %s ${OPTION}(%s)${RST}\n" \
      "$num" "$name" "$desc" "$cat"
  done
  echo -e "${BARR}  ╰─────────────────────────────────────────────╯${RST}"
  if ((PROJECTR_VISIBLE_TOOL_COUNT < ${#TOOLS[@]})); then
    echo -e "${INFO}    ◇ Showing ${BOLD_WHITE}${visible_count}${INFO}/${BOLD_WHITE}${total_tools}${INFO} tools ${BOLD_WHITE}-${DIM} type 'l' to load more tools${RST}"
  fi
  echo ""

  echo -e "${BARR}  ╭─────────────────────╮${RST}"
  echo -e "${BARR}  │${RST} ${BOLD_BRIGHT_GREEN}⚙  Other Options${RST}    ${BARR}│${RST}"
  echo -e "${BARR}  ├────────────────────────────────╮${RST}"
  echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}s${OPTION}]${RST}  ${BOLD_BRIGHT_GREEN}Search & install by name ${BARR}│${RST}"
  echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}p${OPTION}]${RST}  ${BOLD_BRIGHT_GREEN}Install by preset        ${BARR}│${RST}"
  echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}i${OPTION}]${RST}  ${BOLD_BRIGHT_GREEN}Inspect installed        ${BARR}│${RST}"
  echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}u${OPTION}]${RST}  ${BOLD_BRIGHT_GREEN}Uninstall tools          ${BARR}│${RST}"
  echo -e "${BARR}  │${RST}  ${OPTION}[${BOLD_BRIGHT_WHITE}r${OPTION}]${RST}  ${BOLD_BRIGHT_GREEN}Reset saved preferences  ${BARR}│${RST}"
  echo -e "${BARR}  │${RST}  ${ERROR}[${BOLD_BRIGHT_WHITE}e${ERROR}]${RST}  ${BOLD_BRIGHT_RED}Exit the script          ${BARR}│${RST}"
  echo -e "${BARR}  ╰────────────────────────────────╯${RST}"
  echo ""
  echo ""
  echo -ne " ${BG_GREEN} ◇ Enter the tool numbers ${RST} ${BOLD_BRIGHT_GREEN}(separate by spaces)${RST} : "
  if ! read -ra selections; then
    echo ""
    log_info "Interactive input stream closed; exiting gracefully" "menu"
    graceful_exit
  fi
  echo ""
}

#  handle_selection decides what to do for a given input
#  How it works:
#  1. Check if it's a special option (0, p, i, u, e)
#  2. Check if it's actually a number at all
#  3. Search TOOLS for a matching number and install it
handle_selection() {
  local selected="$1"

  # Step 1: Handle the special non-number options first
  case "$selected" in
  s | S)
    clear
    install_by_name_menu
    return
    ;;
  p | P)
    preset_menu
    return
    ;;
  l | L)
    PROJECTR_VISIBLE_TOOL_COUNT=$((${PROJECTR_VISIBLE_TOOL_COUNT:-${PROJECTR_TOOL_PAGE_SIZE_DEFAULT:-50}} + ${PROJECTR_TOOL_PAGE_STEP:-50}))
    ((PROJECTR_VISIBLE_TOOL_COUNT > ${#TOOLS[@]})) && PROJECTR_VISIBLE_TOOL_COUNT=${#TOOLS[@]}
    log_info "Loaded more tools in main menu: visible=$PROJECTR_VISIBLE_TOOL_COUNT" "menu"
    return
    ;;
  i | I)
    clear
    check_all_tools
    return
    ;;
  u | U)
    clear
    uninstall_menu
    return
    ;;
  r | R)
    config_reset_all
    sleep 1
    return
    ;;
  e | E) graceful_exit ;;
  esac

  # Step 2: If it's not a number, reject it
  if ! [[ "$selected" =~ ^[0-9]+$ ]]; then
    echo -e " ${BG_BRIGHT_RED}[!] Invalid option:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $selected ${RST}${OPTION} Please select a valid option${RST}"
    log_warn "Invalid interactive selection: $selected" "menu"
    sleep 2
    return
  fi

  # Step 3: Search TOOLS for the matching number and install it
  local found_flag=0
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"

    if [[ "$selected" == "$num" ]]; then
      found_flag=1
      show_install_wait

      projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
      break
    fi
  done

  # If the number wasn't found in TOOLS at all
  if [[ "$found_flag" -eq 0 ]]; then
    echo -e " ${BG_BRIGHT_RED}[!] Invalid option:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $selected ${RST}${OPTION} Please select the right option${RST}"
    log_warn "Interactive numeric selection not found in tool registry: $selected" "menu"
    sleep 2
  fi
}

#  Main loop — keeps showing the menu until the user exits
while true; do
  show_main_menu
  for selected in "${selections[@]}"; do
    handle_selection "$selected"
  done
done
