#!/bin/bash
# -- deside which presets menu to use --
preset_menu() {
    if command -v whiptail >/dev/null 2>&1; then
        whiptail_preset_ui
    else
        _fallback_text_preset_menu
    fi
}
# -- the text based presets menu --
_fallback_text_preset_menu() {
 while true; do
  clear
   log ENTER "User entered sub-menu 'install-presets'"
  cat <<"EOF" | rainbow
  
                ░█▀█░█▀▄░█▀▀░█▀▀░█▀▀░▀█▀░█▀▀░░░░█▀▀░█░█
                ░█▀▀░█▀▄░█▀▀░▀▀█░█▀▀░░█░░▀▀█░░░░▀▀█░█▀█
                ░▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░░▀░░▀▀▀░▀░░▀▀▀░▀░▀
EOF
 echo ""
  echo -e "${OPTION} [*] Choose the preset you want to install!${OPTION}"
   echo ""
echo -e "${BOLD_WHITE}   [1] ${BOLD_GREEN}Minimal tools ${BOLD_YELLOW}-- For beginners ${RST}"
echo -e "${BOLD_WHITE}   [2] ${BOLD_GREEN}Developer tools ${BOLD_YELLOW}-- For developers ${RST}"
echo -e "${BOLD_WHITE}   [3] ${BOLD_GREEN}Fun tools ${BOLD_YELLOW}-- For fun & games ${RST}"
   echo ""
  echo -e "${ERROR} [b]ack to main menu ${RST}"
   echo ""
  echo -ne "${INFO} [*] Choose an option: ${RST}"
   read -r profile_choice
  echo ""
  case "$profile_choice" in
    1) 
      if prompt_preset_install "Minimal" "${PRESET_MINIMAL_CMDS[@]}"; then
        log INSTALL "User chose to install 'Minimal tools preset'"
        install_preset_by_names "${PRESET_MINIMAL_CMDS[@]}"
      fi
      ;;
    2)
      if prompt_preset_install "Developer" "${PRESET_DEV_CMDS[@]}"; then
        log INSTALL "User chose to install 'Developer tools preset'"
        install_preset_by_names "${PRESET_DEV_CMDS[@]}"
      fi
      ;;
    3)
      if prompt_preset_install "Fun" "${PRESET_FUN_CMDS[@]}"; then
        log INSTALL "User chose to install 'Fun tools preset'"
        install_preset_by_names "${PRESET_FUN_CMDS[@]}"
      fi
      ;;
    b|B) 
      log LEFT "User exited sub-menu 'install-presets'"
      return 0
      ;;
    *) echo ""
       echo -e "  ${BG_RED}[x] Invalid choice:${BOLD_WHITE} '$profile_choice',${BOLD_GREEN} Please select the right option.${RST}"
      sleep 3
  esac
 done
}
# Function to display preset contents beautifully
preview_preset() {
    local preset_name="$1"
    shift
    local preset_items=("$@")  # Store all remaining args as array
    local total_tools=${#preset_items[@]}
    
    clear
    echo -e "${BOLD_CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                     📦 PRESET CONTENTS                           ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${RST}"
    
    echo -e "${BOLD_YELLOW}┌─────────────────────────────────────────────────────────────────┐${RST}"
    echo -e "${BOLD_YELLOW}│${RST} ${BOLD_GREEN}Preset: ${BOLD_WHITE}$preset_name${RST}"
    echo -e "${BOLD_YELLOW}│${RST} ${BOLD_GREEN}Total tools: ${BOLD_WHITE}$total_tools${RST}"
    echo -e "${BOLD_YELLOW}└─────────────────────────────────────────────────────────────────┘${RST}"
    echo ""
    
    echo -e "${BOLD_BLUE}  [*] The following tools will be installed:${RST}"
    echo ""
    
    local count=1
    for entry in "${preset_items[@]}"; do
        IFS="|" read -r cmd pkg description <<< "$entry"
        
        # Format: number, command, description
        printf "  ${BOLD_GREEN}%2d${RST} ${BOLD_WHITE}%-15s${RST} ${OPTION}→${RST} ${INFO}%s${RST}\n" \
               "$count" "$cmd" "$description"
        ((count++))
    done
    
    echo ""
    echo -e "${BOLD_BLUE}  [*] 📊 Summary:${RST} ${BOLD_WHITE}$total_tools ${BOLD_BLUE}tools will be installed${RST}"
    echo ""
}

# Function to show preset and confirm installation
prompt_preset_install() {
    local preset_name="$1"
    shift
    local preset_items=("$@")  # Store all remaining args as array
    
    # Show what will be installed
    preview_preset "$preset_name" "${preset_items[@]}"
    
    # Ask for confirmation
    echo -e "${BOLD_BLUE}  [?] Do you want to install this preset? ${RST}"
    echo ""
    echo -e "${BOLD_GREEN}   [y] Yes${RST} - Install all ${BOLD_WHITE}${#preset_items[@]}${RST} tools ${RST}"
    echo -e "${BOLD_RED}   [n] No${RST}  - Cancel and return to menu ${RST}"
    echo ""
    
    echo -ne "  ${BRIGHT_MAGENTA}[?] Your choice: ${RST}"
    read -n 1 choice
    echo ""
    
    case "$choice" in
        y|Y)
            assert_disk_space
            sleep 1
            echo -e "${OPTION}  [✓] Starting installation of $preset_name preset...${RST}"
            sleep 1
            return 0
            ;;
        *)
            echo -e "${INFO}  [→] Installation cancelled. Returning to menu...${RST}"
            sleep 1
            return 1
            ;;
    esac
}
# -- whiptail based preset_menu --
whiptail_preset_ui() {
    while true; do
        local choices
        choices=$(whiptail --title "ProjectR Presets" \
            --cancel-button "Back to Main" \
            --menu "Select a System Configuration Preset:" 15 65 4 \
            "1" "Minimal Tools System Environment Setup" \
            "2" "Full Professional Developer Workspace" \
            "3" "Fun Interactive Entertainment Tools" 3>&1 1>&2 2>&3)

        if [[ $? -ne 0 ]]; then
            log LEFT "User exited whiptail presets menu"
            return 0
        fi

        case "$choices" in
            1)
                if prompt_preset_install "Minimal" "${PRESET_MINIMAL_CMDS[@]}"; then
                    log INSTALL "User chose Minimal preset (whiptail)"
                    install_preset_by_names "${PRESET_MINIMAL_CMDS[@]}"
                fi
                ;;
            2)
                if prompt_preset_install "Developer" "${PRESET_DEV_CMDS[@]}"; then
                    log INSTALL "User chose Developer preset (whiptail)"
                    install_preset_by_names "${PRESET_DEV_CMDS[@]}"
                fi
                ;;
            3)
                if prompt_preset_install "Fun" "${PRESET_FUN_CMDS[@]}"; then
                    log INSTALL "User chose Fun preset (whiptail)"
                    install_preset_by_names "${PRESET_FUN_CMDS[@]}"
                fi
                ;;
        esac
    done
}
