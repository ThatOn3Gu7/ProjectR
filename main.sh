#!/bin/bash
# -- shows script version - just for fun --
[[ "${1:-}" == "--version" ]] && echo "ProjectR v1.0" && exit 0
# -- Catches any bugs and unbound variables --
set -uo pipefail
# -- source all the other utilitys --
source lib/core/colours.sh
source lib/core/progress_bar.sh
source lib/core/logging.sh
source lib/core/display.sh
source lib/core/spinner.sh
source lib/core/prompts.sh
# -- system logics sourced --
source lib/system/detect.sh 
source lib/system/network.sh
source lib/system/checker.sh
source lib/system/dependencies.sh
# -- master tools list --
source lib/data/tools.sh
# -- function logics sourced --
source lib/features/presets.sh
source lib/features/installer.sh
source lib/features/post_install.sh
source lib/features/neovim_setup.sh
source lib/features/zsh_setup.sh
source lib/features/upgrade.sh
source lib/features/update.sh
# -- sub_menus sourced --
source lib/sub_menus/presets_menu.sh
source lib/sub_menus/uninstall_menu.sh
# PM="$(detect_pkg_manager)"
trap graceful_exit SIGINT
# -- Separate log by session --
echo "━━━━━━ Session: $(date '+%Y-%m-%d %H:%M') ━━━━━━" >> "$LOG_FILE"
# -- dependencies check -- 
check_dependencies_menu
# a call for startup internet check
startup_wifi_check
# -- main installer menu  --
show_main_menu() {
 clear
  rainbow() { command -v lolcat >/dev/null 2>&1 && lolcat || cat; }
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

  echo -e "${OPTION}${BOLD}"
  boxed_text left "[*] Select the pkg/tool you want to install:" 

  echo -e "${BARR}   ╔═════════════════╗ ${RST}"
  echo -e "${BARR}   ║ ${RST}Available pkgs: ${BARR}║${RST}"
  echo -e "${BARR}   ╚╔════════════════╝═══════════════════╗ ${RST}"
  # Loop through every tool in TOOLS and print a menu line for it
  # printf formats it so all the columns line up neatly
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
    printf "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}%02d${OPTION}] %-14s ${INFO}- %s ${OPTION}(%s)${RST}\n" \
      "$num" "$name" "$desc" "$cat"
  done
  echo -e "${BARR}    ╚════════════════════════════════════╝ ${RST}"

echo ""

echo -e "${BARR}   ╔════════════════╗ ${RST}"
echo -e "${BARR}   ║ ${RST}Other Options: ${BARR}║${RST}"
echo -e "${BARR}   ╚╔═══════════════╝══╗ ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}0${OPTION}] Install ALL ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}p${OPTION}] Install by preset${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}i${OPTION}] Inspect installed ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}u${OPTION}] Uninstall tools${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${ERROR}e${OPTION}] Exits the script${RST}"
echo -e "${BARR}    ╚══════════════════╝ ${RST}"
  echo ""
  echo -ne " ${BG_GREEN}[*] Enter the tool numbers ${RST} ${BOLD_BRIGHT_GREEN}(separate by spaces)${RST} : "
  read -a selections
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
    p|P) preset_menu; return ;;
    i|I) clear; check_tool_main; return ;;
    u|U) clear; uninstall_menu; return ;;
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
      be_patient

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
