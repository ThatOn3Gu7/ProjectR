#!/bin/bash
# shellcheck disable=all
# -- uninstaller menu --
uninstall_menu() {
  PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT=${PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT:-${PROJECTR_TOOL_PAGE_SIZE_DEFAULT:-50}}

  while true; do
  sleep 0.1
    clear
    cat <<"BANNER" | rainbow

 ██████╗ ██████╗ ███╗   ███╗ ██████╗ ██╗   ██╗███████╗    ██╗████████╗
 ██╔══██╗╚════██╗████╗ ████║██╔═══██╗██║   ██║██╔════╝    ██║╚══██╔══╝
 ██████╔╝ █████╔╝██╔████╔██║██║   ██║██║   ██║█████╗ ███╗ ██║   ██║   
 ██╔══██╗ ╚═══██╗██║╚██╔╝██║██║   ██║╚██╗ ██╔╝██╔══╝ ╚══╝ ██║   ██║   
 ██║  ██║██████╔╝██║ ╚═╝ ██║╚██████╔╝ ╚████╔╝ ███████╗    ██║   ██║   
 ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝    ╚═╝   ╚═╝
 
                                              > C0ded by: ThatOn3Gu7

BANNER
    echo -e "${OPTION}"
    print_box left "◇ Available tools for uninstallation:"
    echo -e "${RST}"

    local total_tools=${#TOOLS[@]}
    local visible_count=${PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT:-${PROJECTR_TOOL_PAGE_SIZE_DEFAULT:-50}}
    ((visible_count > total_tools)) && visible_count=$total_tools
    PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT=$visible_count

    local idx entry
    for ((idx = 0; idx < visible_count; idx++)); do
      entry="${TOOLS[$idx]}"
      IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
      printf "   [%03d]${OPTION} %-18s ${INFO}- %s ${OPTION}(%s)${RST}\n" "$num" "$name" "$desc" "$cat"
    done
    echo ""
    if ((PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT < ${#TOOLS[@]})); then
      echo -e "${INFO}   ◇ Showing ${BOLD_WHITE}${visible_count}${INFO}/${BOLD_WHITE}${total_tools}${INFO} tools ${BOLD_WHITE}- ${DIM}type 'l' to load more tools${RST}"
    fi

    echo ""
    echo -e "${OPTION}  [i] Inspect installed tools${RST}"
    echo -e "${INFO}  [b] Back to main menu${RST}"
    echo -e "${ERROR}  [e] Exit script${RST}"
    echo ""
    echo -ne " ${BG_CYAN} ▶ Select tool numbers ${RST} ${OPTION}(separated by spaces)${RST} : "
    read -a choices
    for choice in "${choices[@]}"; do
      # --- Special menu options ---
      case "$choice" in
      l | L)
        PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT=$((${PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT:-${PROJECTR_TOOL_PAGE_SIZE_DEFAULT:-50}} + ${PROJECTR_TOOL_PAGE_STEP:-50}))
        ((PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT > ${#TOOLS[@]})) && PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT=${#TOOLS[@]}
        log_info "Loaded more tools in uninstall menu: visible=$PROJECTR_UNINSTALL_VISIBLE_TOOL_COUNT" "uninstall"
        continue
        ;;
      i | I)
        clear
        check_all_tools
        continue
        ;;
      b | B) return ;;
      e | E) graceful_exit ;;
      esac

      # --- Check it's a number ---
      if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo -e " ${BG_BRIGHT_RED}[ℹ] Invalid selection:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $choice ${RST}${OPTION} Please enter a valid number.${RST}"
        sleep 2
        continue
      fi

      # --- Find the tool and uninstall it ---
      found=0
      for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"

        if [[ "$choice" == "$num" ]]; then
          found=1
          echo -e "${ERROR}"
          projectr_uninstall_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
          break
        fi
      done

      if [[ "$found" -eq 0 ]]; then
        echo -e " ${BG_BRIGHT_RED}[ℹ] Invalid selection:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $choice ${RST}${OPTION} Please make a valid selection.${RST}"
        sleep 2
      fi
    done
    echo ""
    printf "${DIM} [press ENTER]${RST}"
    read -s
    echo
  done
}

