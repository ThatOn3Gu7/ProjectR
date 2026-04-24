#!/bin/bash

# The follwoing commands are for installing Neovim & NvChad.
install_neovim_full() {
  install_pkg nvim neovim "Neovim: Best code editor"
 
    # Common Neovim config paths
    NVCHAD_PATH="$HOME/.config/nvim"
    LAZYVIM_PATH="$HOME/.config/nvim-lazyvim"
    ASTRONVIM_PATH="$HOME/.config/nvim-astronvim"
    STANDARD_PATH="$HOME/.config/nvim"

   # Check if any config exists
   if ask "  [*] Install a config for NeoVim?"; then
    if [ -d "$STANDARD_PATH" ] || [ -d "$NVCHAD_PATH" ] || [ -d "$LAZYVIM_PATH" ] || [ -d "$ASTRONVIM_PATH" ]; then
        echo -e "${OPT}  [✓] A Neovim config is already installed!"
         sleep 3
        return 0
       else
        check_nvim_config
    fi
   fi
 }
# if called chacks if a nvim config is installed and if not, then gives the user choice to clone it
check_nvim_config() {
 echo -e "${INFO}  [*] Which config would you like to install? ${RST}"
  echo ""
   echo -e "${OPT}   [1] NvChad ${RST}"
   echo -e "${OPT}   [2] LazyVim ${RST}"
   echo -e "${OPT}   [3] AstroNvim ${RST}"
   echo -e "${OPT}   [4] Skip ${RST}"
  echo ""
    echo -ne "${INFO}  [*] Select option (1-4): ${RST}"
   read confing_choice
   case "$confing_choice" in
        1)
           echo -e  "${OPT}  [*] Cloning NvChad...${RST}"
           git clone https://github.com/NvChad/NvChad ~/.config/nvim
           ;;
        2)
           echo -e "${OPT}  [*] Cloning LazyVim starter template...${RST}"
           git clone https://github.com/LazyVim/starter ~/.config/nvim
           rm -rf ~/.config/nvim/.git
           ;;
        3)
           echo -e "${OPT}  [*] Cloning AstroNvim...${RST}"
           git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
           ;;
        4)
           echo -e "${INFO}  [*] Skipping Neovim config installation...${RST}"
           return 1
           ;;
        *)
           echo -e "${ERR}  [!] Invalid option: $REPLY ${RST}"
           ;;
   esac
}
