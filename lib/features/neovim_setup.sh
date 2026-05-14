#!/bin/bash

# The follwoing commands are for installing Neovim & NeoVim configs.
install_nvim() {
  install_pkg nvim neovim "Neovim: Best code editor"
 
    # Common Neovim config paths
    STANDARD_PATH="$HOME/.config/nvim"

   # Check if any config exists
   if ask "  [*] Install a config for NeoVim?"; then
    if [ -d "$STANDARD_PATH" ]; then
        echo -e "${OPTION}  [✓] A Neovim config is already installed!"
         sleep 3
        return 0
       else
        get_nvim_config
    fi
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
           ;;
        2)
           echo -e "${OPTION}  [*] Cloning LazyVim starter template...${RST}"
           git clone https://github.com/LazyVim/starter ~/.config/nvim
           rm -rf ~/.config/nvim/.git
           ;;
        3)
           echo -e "${OPTION}  [*] Cloning AstroNvim...${RST}"
           git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
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
