#!/bin/bash

# -- source uninstaller --
source lib/features/uninstaller.sh
# -- uninstaller menu --
uninstall_menu() {
  while true; do
    clear
  cat <<"EOF" | lolcat

 ██████╗ ██████╗ ███╗   ███╗ ██████╗ ██╗   ██╗███████╗    ██╗████████╗
 ██╔══██╗╚════██╗████╗ ████║██╔═══██╗██║   ██║██╔════╝    ██║╚══██╔══╝
 ██████╔╝ █████╔╝██╔████╔██║██║   ██║██║   ██║█████╗ ███╗ ██║   ██║   
 ██╔══██╗ ╚═══██╗██║╚██╔╝██║██║   ██║╚██╗ ██╔╝██╔══╝ ╚══╝ ██║   ██║   
 ██║  ██║██████╔╝██║ ╚═╝ ██║╚██████╔╝ ╚████╔╝ ███████╗    ██║   ██║   
 ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝    ╚═╝   ╚═╝
 
                                              > C0ded by: ThatOn3Gu7

EOF
echo -e "${OPTION}"
boxed_text left "[*] Available tools for deletion:"
echo -e "${RST}"

 for entry in "${TOOLS[@]}"; do
      IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
      printf "   [%02d]${OPTION} %-14s ${INFO}- %s${RST}\n" "$num" "$name" "$desc"
    done
    
 echo ""
 echo -e "${OPTION}  [i] Inspect installed ${RST}"
 echo -e "${INFO}  [b] Back to main-menu ${RST}"
 echo -e "${ERROR}  [e] Exit Script${RST}"
  echo ""
  echo -ne " ${BG_CYAN}[*] Select numbers ${RST} ${OPTION}(space separated)${RST} : "
   read -a choices
    for choice in "${choices[@]}"; do
      # --- Special menu options ---
      case "$choice" in
        i|I) clear; check_tool_main; continue ;;
        b|B) return ;;
        e|E) graceful_exit ;;
      esac

      # --- Check it's a number ---
      if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo -e " ${BG_BRIGHT_RED}[!] Invalid option:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $choice ${RST}${OPTION} Please select a valid number${RST}"
        sleep 2
        continue
      fi

      # --- Find the tool and uninstall it ---
       found=0
      for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"

        if [[ "$choice" == "$num" ]]; then
          found=1
          echo -e "${ERROR}"

          # Neovim gets special treatment — offer to remove config too
          if [[ "$num" == "18" ]]; then
            uninstall_pkg "$cmd" "$pkg" "$name"
            if [ -d "$HOME/.config/nvim/" ]; then
              echo -e "${INFO}"
              if ask "   [*] Also remove Neovim config files?"; then
                echo -e "${BOLD_GREEN}   [*] Removing nvim conf.. ${RST}"
                rm -rf ~/.config/nvim/ ~/.local/share/nvim/ ~/.cache/nvim/ ~/.local/state/nvim/
                echo -e "${OPTION}   [✓] Neovim config removed${RST}"
              fi
            fi

          # pip tools use uninstall_pip instead of uninstall_pkg
          elif [[ "$type" == "pip" ]]; then
            uninstall_lang $type "$cmd" "$name"

          # everything else uses uninstall_pkg
          else
            uninstall_pkg "$cmd" "$pkg" "$name"
          fi

          break
        fi
      done

      if [[ "$found" -eq 0 ]]; then
        echo -e " ${BG_BRIGHT_RED}[!] Invalid option:${BG_BRIGHT_YELLOW}${BOLD_BRIGHT_BLACK} $choice ${RST}${OPTION} Please select the right option${RST}"
        sleep 2
      fi
    done

   echo -e "${OPTION}"
    read -p " [*] Press ENTER to continue..."
   echo -e "${RST}"
done
}
