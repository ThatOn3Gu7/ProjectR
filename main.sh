#!/bin/bash
# -- Catches any bugs and unbound variables --
set -uo pipefail
# -- Resolve the project root (works regardless of where you call this from) --
# BASH_SOURCE[0] is always the path to THIS file (main.sh), even if it's
# called from another directory or via a symlink.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# -- export for use outside main.sh --
export SCRIPT_DIR
# -- Now source everything using $SCRIPT_DIR as the anchor --
# -- source conf first (flags need colours/display) --
source "$SCRIPT_DIR/lib/data/config.sh"
source "$SCRIPT_DIR/lib/core/colours.sh"
source "$SCRIPT_DIR/lib/core/display.sh"
source "$SCRIPT_DIR/lib/system/detect.sh"
detect_pkg_manager >/dev/null
source "$SCRIPT_DIR/lib/data/tools.sh"
source "$SCRIPT_DIR/lib/features/installer.sh"
source "$SCRIPT_DIR/lib/features/uninstaller.sh"
# -- source flags and parse immediately --
source "$SCRIPT_DIR/lib/flags/flags.sh"
parse_flags "$@"
# -- now source everything else --
source "$SCRIPT_DIR/lib/core/progress_bar.sh"
source "$SCRIPT_DIR/lib/core/logging.sh"
source "$SCRIPT_DIR/lib/core/spinner.sh"
source "$SCRIPT_DIR/lib/core/prompts.sh"
source "$SCRIPT_DIR/lib/system/network.sh"
source "$SCRIPT_DIR/lib/system/checker.sh"
source "$SCRIPT_DIR/lib/system/dependencies.sh"
source "$SCRIPT_DIR/lib/features/presets.sh"
source "$SCRIPT_DIR/lib/features/post_install.sh"
source "$SCRIPT_DIR/lib/features/search_install.sh"
source "$SCRIPT_DIR/lib/features/neovim_setup.sh"
source "$SCRIPT_DIR/lib/features/zsh_setup.sh"
source "$SCRIPT_DIR/lib/features/upgrade.sh"
source "$SCRIPT_DIR/lib/features/update.sh"
source "$SCRIPT_DIR/lib/sub_menus/presets_menu.sh"
source "$SCRIPT_DIR/lib/sub_menus/uninstall_menu.sh"
trap 'graceful_exit' SIGINT
# -- lock file location --
LOCK_FILE="${HOME}/.config/projectr/tmp/project.lock"
# -- Ensure directory exists --
mkdir -p "$(dirname "$LOCK_FILE")" || {
    echo -e "${ERROR}[!] Failed to create lock directory${RST}"
    exit 1
}
# -- Acquire lock (redirect after directory exists) --
exec 9>"$LOCK_FILE"
flock -n 9 || {
    echo -e "${ERROR}WARR:${RST} projectr is already running."
    exit 1
}
# -- Separate log by session --
log START "━━━━━━ Session started at: $(date '+%Y-%m-%d %H:%M') ━━━━━━"
# -- dependencies check -- 
verify_dependencies
# a call for startup internet check
check_startup_connectivity
# -- small helper function for when lolcat isn't around --
rainbow() { command -v lolcat >/dev/null 2>&1 && lolcat || cat; }
# -- Check background daemon for software updates silently --
if [[ -f "$SCRIPT_DIR/lib/system/daemon_checker.sh" ]]; then
    source "$SCRIPT_DIR/lib/system/daemon_checker.sh"
    check_daemon_alerts
fi
# -- main installer menu  --
show_main_menu() {
 clear
  # cool LOGO with colors
  cat <<"EOF" | rainbow

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
  print_box left "[*] Select the pkg/tool you want to install:" 
  echo -e "${RST}" 
  echo -e "${BARR}   ╔═════════════════╗ ${RST}"
  echo -e "${BARR}   ║ ${RST}Available pkgs: ${BARR}║${RST}"
  echo -e "${BARR}   ╚╔════════════════╝═══════════════════╗ ${RST}"
  # Loop through every tool in TOOLS and print a menu line for it
  # printf formats it so all the columns line up neatly
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
    printf "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}%02d${OPTION}] %-12s ${INFO}- %s ${OPTION}(%s)${RST}\n" \
      "$num" "$name" "$desc" "$cat"
  done
  echo -e "${BARR}    ╚════════════════════════════════════╝ ${RST}"

echo ""

echo -e "${BARR}   ╔════════════════╗ ${RST}"
echo -e "${BARR}   ║ ${RST}Other Options: ${BARR}║${RST}"
echo -e "${BARR}   ╚╔═══════════════╝══╗ ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}0${OPTION}] Install ALL ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}s${OPTION}] Search & install by name${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}p${OPTION}] Install by preset${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}i${OPTION}] Inspect installed ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}u${OPTION}] Uninstall tools${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}r${OPTION}] Reset saved preferences${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${ERROR}e${OPTION}] Exits the script${RST}"
echo -e "${BARR}    ╚══════════════════╝ ${RST}"
  echo ""
  echo -ne " ${BG_GREEN}[*] Enter the tool numbers ${RST} ${BOLD_BRIGHT_GREEN}(separate by spaces)${RST} : "
  read -ra selections
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
    0)   clear; install_all; return ;;
    s|S) clear; install_by_name_menu; return ;;
    p|P) preset_menu; return ;;
    i|I) clear; check_all_tools; return ;;
    u|U) clear; uninstall_menu; return ;;
    r|R) config_reset_all; sleep 1; return ;;
    e|E) graceful_exit ;;
  esac

  # Step 2: If it's not a number, reject it
  if ! [[ "$selected" =~ ^[0-9]+$ ]]; then
    echo -e " ${BG_BRIGHT_RED}[!] Invalid option:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $selected ${RST}${OPTION} Please select a valid option${RST}"
    sleep 2
    return
  fi

  # Step 3: Search TOOLS for the matching number and install it
  local found=0
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"

    if [[ "$selected" == "$num" ]]; then
      found=1
      show_install_wait

      # The TYPE field tells us how to install this tool:
      #   pkg     → normal system package manager install
      #   pip     → python language package (uses install_lang)
      #   special → has its own custom function (name stored in 'extra')
      case "$type" in
        pkg)
          install_pkg "$cmd" "$pkg" "$name"
          ;;
        pip)
          # install_lang args: tool_type  pkg_name  display_name  cmd_to_check
          install_lang "pip" "$pkg" "$name" "$cmd"
          ;;
        special)
          # 'extra' holds the function name e.g. install_neovim_full
          "$extra"
          ;;
      esac
      break
    fi
  done

  # If the number wasn't found in TOOLS at all
  if [[ "$found" -eq 0 ]]; then
    echo -e " ${BG_BRIGHT_RED}[!] Invalid option:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $selected ${RST}${OPTION} Please select the right option${RST}"
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
