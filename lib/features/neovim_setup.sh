#!/bin/bash

# The follwoing commands are for installing Neovim & NeoVim configs.
install_nvim() {

  install_pkg nvim neovim "Neovim: Best code editor"
  sleep 1

  local saved
  saved=$(config_get "nvim_config_choice")

  if [ "$saved" = "skip" ]; then
      return 0
  fi
  if [ -z "$saved" ]; then
      if ! ask "  [*] Install a config for NeoVim?"; then
          config_set "nvim_config_choice" "skip"
          return 0
      fi
  fi

 # Common Neovim config paths
 local STANDARD_PATH="$HOME/.config/nvim"
 if [ -d "$STANDARD_PATH" ]; then
      echo -e "${OPTION}  [✓] A Neovim config is already installed!"
      sleep 3
      return 0
  else
      get_nvim_config
  fi
 }
# if called chacks if a nvim config is installed and if not, then gives the user choice to clone it
get_nvim_config() {
 echo -e "${INFO}  [*] Which config would you like to install? ${RST}"
  echo ""
   echo -e "${OPTION}   [1] NvChad ${RST}"
   echo -e "${OPTION}   [2] LazyVim ${RST}"
   echo -e "${OPTION}   [3] AstroNvim ${RST}"
   echo -e "${OPTION}   [4] Skip ${RST}"
  echo ""
    echo -ne "${INFO}  [*] Select option (1-4): ${RST}"
   read -r confing_choice
   case "$confing_choice" in
        1)
           echo -e  "${OPTION}  [*] Cloning NvChad...${RST}"
           git clone https://github.com/NvChad/starter ~/.config/nvim
           if ask "  [*] Remove .git folder?" "y"; then
           rm -rf ~/.config/nvim/.git
           else
           echo -e "${BOLD_GREEN}  [*] Skipping...${RST}"
           fi
           ;;
        2)
           echo -e "${OPTION}  [*] Cloning LazyVim starter template...${RST}"
           git clone https://github.com/LazyVim/starter ~/.config/nvim
           if ask "  [*] Remove .git folder?" "y"; then
           rm -rf ~/.config/nvim/.git
           else
           echo -e "${BOLD_GREEN}  [*] Skipping...${RST}"
           fi
           ;;
        3)
           echo -e "${OPTION}  [*] Cloning AstroNvim...${RST}"
           git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
           if ask "  [*] Remove .git folder?" "y"; then
           rm -rf ~/.config/nvim/.git
           else
           echo -e "${BOLD_GREEN}  [*] Skipping...${RST}"
           fi
           ;;
        4)
           echo -e "${INFO}  [*] Skipping Neovim config installation...${RST}"
           return 1
           ;;
        *)
           echo -e "${ERROR}  [!] Invalid option: $confing_choice ${RST}"
           ;;
   esac
}
