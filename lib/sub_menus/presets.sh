#!/bin/bash
# -- the presets menu --
preset_menu() {
 while true; do
  clear
   log ENTER "User entered sub-menu 'install-sresets'"
  cat <<"EOF" | lolcat

# Future ASCII art is to be here

EOF

  echo -e "${OPT}${BOLD}"
   boxed_text center "Choose the preset you want to install"
  echo -e "${OPT}"
   boxed_text center "[1] Minimal tools
[2] Developer tools
[3] Fun tools"
  echo -e "${ERR}"
   boxed_text center "[b]ack to main menu"
  echo -e "${RST}"
  echo -ne "${INFO}${BOLD} [*] Choose an option: ${RST}"
   read profile_choice
  echo ""
  case "$profile_choice" in
    1) log INSTALL "User chose to install 'Minimal tools preset'"
      install_preset "${PRESET_MINIMAL[@]}"
      ;;
    2) log INSTALL "User chose to install 'Developer tools preset'"
      install_preset "${PRESET_DEV[@]}"
      ;;
    3) log INSTALL "User chose to install 'Fun tools preset'"
      install_preset "${PRESET_FUN[@]}"
      ;;
    b|B) log LEFT "User exited sub-menu 'install-sresets'"
       return 0
      ;;
    *) echo ""
       echo -e "${ERR}"
      boxed_text center "[x] Invalid choice: '$profile_choice', Please select the right option."
       echo -e "${RST}"
      sleep 3
  esac
 done
}
