#!/bin/bash

# -- install neovim & config --
setup_nvim() {

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
      prompt_nvim_config
  fi
 }
# if called chacks if a nvim config is installed and if not, then gives the user choice to clone it
prompt_nvim_config() {
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

# install zsh & oh my zsh.
setup_zsh() {
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
#  install_code_server — special installer for code-server
install_code_server() {
    if [[ "${PRIMARY_PKG_MANAGER:-}" != "pkg" ]]; then
      echo -e "${ERROR}  [!] code-server via tur-repo is only supported on Termux.${RST}"
      return 1
    fi
    echo -e "${OPTION}"
    if ask "[*] tur-repo is required to install code-server, install it?" "y"; then
        echo -e "${RST}"
        progress_run "Installing tur-repo" \
                     "Installation successful" \
                     pkg install tur-repo 
        echo ""
        install_pkg "code-server" "code-server" "Code-Server: VSCode on Android"
    fi
}
