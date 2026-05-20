#!/bin/bash

# The follwoing commands are for installing zsh & oh my zsh.
install_zsh_full() {
 install_pkg zsh zsh "Zsh: Extended shell with powerful features"
   sleep 1
   # echo -e "${INFO}"
    if ask "  [*] Install oh-my-zsh?" "y"; then
     if [ -d "$HOME/.oh-my-zsh" ]; then
       echo -e "${OPTION}  [✓] Oh-My-Zsh already exists. Skipping...${RST}"
         sleep 2
       else 
         echo -e "${INFO}  [*] Installing Oh-My-Zsh framework...${RST}"
         echo ""
         echo -e "${ERROR}  [*] The script will auto-exit after this because of Shell change..${RST}"
         echo -e "${INFO}  [*] Make sure to clone some useful plugins to make full use of ohmyzsh.."
         echo ""
       KEEP_ZSHRC=yes \
         sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 
     fi
    fi
    sleep 1 
    # echo -e "${INFO}"
     if ask "  [*] Also clone Powerlevel10k..?" "y"; then
      if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
       echo -e "${OPTION}  [✓] Powerlevel10k is already configured - Skipping..${RST}"
       sleep 3
       return 0 
      else  
       echo -e "${INFO}  [*] Installing: p10k..${RST}"
       git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" >/dev/null 2>&1
       echo ""
       echo -e "${OPTION} [✓] Powerlevel10k is now installed, type: p10k configure${RST}"
      fi
     fi
}
