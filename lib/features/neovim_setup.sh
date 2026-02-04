#!/bin/bash

# The follwoing commands are for installing Neovim & NvChad.
install_neovim_full() {
  install_pkg nvim neovim "Neovim: Best code editor,"
  install_pkg npm nodejs "Node.Js: JS Runtime env,"

  # Use the exact path that the LS command just confirmed
  local NV_CONFIG="$HOME/.config/nvim"
  # echo -e "${INFO}${BOLD}"
 if ask "  [*] Install NvChad for NeoVim?" "n" 3; then
  if [ -d "$NV_CONFIG" ]; then
    echo -e "${OPT}${BOLD}  [✓] NvChad conf already exists - Skipping..${RST}"
    sleep 1
  else
    echo ""
     echo -e "${INFO}${BOLD}  [*] Downloading NvChad conf...${RST}"
      mkdir -p "$HOME/.config/"
      git clone https://github.com/NvChad/starter ~/.config/nvim
     echo ""
    echo -e "${OPT}${BOLD}  [✓] NvChad installed successfully.${RST}"
   sleep 2
  fi
 fi
}
