#!/bin/bash
# shellcheck disable=all
# -- decide which presets menu to use --
preset_menu() {
    if command -v whiptail >/dev/null 2>&1; then
        whiptail_preset_ui
    else
        _fallback_text_preset_menu
    fi
}

projectr_get_preset_fields() {
    local wanted="$1" item
    for item in "${PRESET_MENU_ITEMS[@]}"; do
        IFS="|" read -r preset_id preset_title preset_desc preset_array <<< "$item"
        if [[ "$wanted" == "$preset_id" ]]; then
            return 0
        fi
    done
    return 1
}

projectr_tool_summary_by_cmd() {
    local wanted="$1" entry num cmd pkg name desc type extra cat
    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        if [[ "$cmd" == "$wanted" ]]; then
            printf '%s|%s|%s' "$name" "$desc" "$cat"
            return 0
        fi
    done
    printf '%s|%s|%s' "$wanted" "Not found in registry" "Unknown"
    return 1
}

projectr_install_preset_id() {
    local selected_id="$1" preset_id preset_title preset_desc preset_array
    if ! projectr_get_preset_fields "$selected_id"; then
        echo -e "  ${BG_RED}[x] Invalid choice:${BOLD_WHITE} '$selected_id',${BOLD_GREEN} Please select the right option.${RST}"
        sleep 3
        return 1
    fi

    local -n preset_ref="$preset_array"
    if prompt_preset_install "$preset_title" "${preset_ref[@]}"; then
        log INSTALL "User chose to install '$preset_title preset'"
        install_preset_by_names "${preset_ref[@]}"
    fi
}

# -- the text based presets menu --
_fallback_text_preset_menu() {
 while true; do
  clear
   log ENTER "User entered sub-menu 'install-presets'"
  cat <<"BANNER" | rainbow
  
                ░█▀█░█▀▄░█▀▀░█▀▀░█▀▀░▀█▀░█▀▀░░░░█▀▀░█░█
                ░█▀▀░█▀▄░█▀▀░▀▀█░█▀▀░░█░░▀▀█░░░░▀▀█░█▀█
                ░▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░░▀░░▀▀▀░▀░░▀▀▀░▀░▀
BANNER
 echo ""
  echo -e "${OPTION} [*] Choose the preset you want to install!${OPTION}"
   echo ""
  local item preset_id preset_title preset_desc preset_array
  for item in "${PRESET_MENU_ITEMS[@]}"; do
      IFS="|" read -r preset_id preset_title preset_desc preset_array <<< "$item"
      printf "${BOLD_WHITE}   [%s] ${BOLD_GREEN}%s${BOLD_YELLOW} -- %s ${RST}\n" \
          "$preset_id" "$preset_title" "$preset_desc"
  done
   echo ""
  echo -e "${ERROR} [b]ack to main menu ${RST}"
   echo ""
  echo -ne "${INFO}  ◇ Choose an option: ${RST}"
   read -r profile_choice
  echo ""
  case "$profile_choice" in
    b|B) 
      log LEFT "User exited sub-menu 'install-presets'"
      return 0
      ;;
    *) projectr_install_preset_id "$profile_choice" ;;
  esac
 done
}

# Function to display preset contents beautifully
preview_preset() {
    local preset_name="$1"
    shift
    local preset_items=("$@")
    local total_tools=${#preset_items[@]}
    
    clear
    echo -e "${BOLD_CYAN}"
    echo "╭────────────────────────────────────────────────────────────────────╮"
    echo "│                     📦 PRESET CONTENTS                             │"
    echo "╰────────────────────────────────────────────────────────────────────╯"
    echo -e "${RST}"
    
    echo -e "${BOLD_GREEN}   ◇ Preset: ${BOLD_WHITE}$preset_name${RST}"
    echo -e "${BOLD_GREEN}   ◇ Total tools: ${BOLD_WHITE}$total_tools${RST}"
    echo ""
    
    echo -e "${BOLD_BLUE}  [*] The following tools will be installed:${RST}"
    echo ""
    
    local count=1 entry tool_name tool_desc tool_cat
    for entry in "${preset_items[@]}"; do
        IFS="|" read -r tool_name tool_desc tool_cat <<< "$(projectr_tool_summary_by_cmd "$entry")"
        printf "  ${BOLD_GREEN}%2d${RST} ${BOLD_WHITE}%-15s${RST} ${OPTION}→${RST} ${INFO}%-35s${RST} ${DIM}[%s]${RST}\n" \
               "$count" "$entry" "$tool_desc" "$tool_cat"
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
    local preset_items=("$@")
    
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
        local menu_args=() item preset_id preset_title preset_desc preset_array
        for item in "${PRESET_MENU_ITEMS[@]}"; do
            IFS="|" read -r preset_id preset_title preset_desc preset_array <<< "$item"
            menu_args+=("$preset_id" "$preset_title - $preset_desc")
        done

        local choices
        choices=$(whiptail --title "ProjectR Presets" \
            --cancel-button "Back to Main" \
            --menu "Select a System Configuration Preset:" 22 85 12 \
            "${menu_args[@]}" 3>&1 1>&2 2>&3)

        if [[ $? -ne 0 ]]; then
            log LEFT "User exited whiptail presets menu"
            return 0
        fi

        projectr_install_preset_id "$choices"
    done
}
