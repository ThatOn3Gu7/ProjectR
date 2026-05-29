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
# Checks for a nvim config and gives the user the choice to clone one
prompt_nvim_config() {

    if ! command -v git >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] git is not installed — cannot clone a Neovim config.${RST}"
        return 1
    fi

    echo -e "${INFO}  [*] Which config would you like to install? ${RST}"
    echo ""
    echo -e "${OPTION}   [1] NvChad ${RST}"
    echo -e "${OPTION}   [2] LazyVim ${RST}"
    echo -e "${OPTION}   [3] AstroNvim ${RST}"
    echo -e "${OPTION}   [4] Skip ${RST}"
    echo ""
    echo -ne "${INFO}  [*] Select option (1-4): ${RST}"
    read -r config_choice

    local repo url
    case "$config_choice" in
        1) repo="NvChad";    url="https://github.com/NvChad/starter" ;;
        2) repo="LazyVim";   url="https://github.com/LazyVim/starter" ;;
        3) repo="AstroNvim"; url="https://github.com/AstroNvim/template" ;;
        4)
            echo -e "${INFO}  [*] Skipping Neovim config installation...${RST}"
            return 0
            ;;
        *)
            echo -e "${ERROR}  [!] Invalid option: '$config_choice'${RST}"
            return 1
            ;;
    esac

    echo -e "${OPTION}  [*] Cloning $repo...${RST}"

    if ! git clone --depth 1 "$url" ~/.config/nvim 2>&1; then
        echo -e "${ERROR}  [!] Failed to clone $repo — check your internet connection.${RST}"
        log FAIL "git clone failed for $repo ($url)"
        return 1
    fi

    echo -e "${OPTION}  [✓] $repo cloned successfully.${RST}"
    log INSTALL "$repo Neovim config cloned"

    if ask "  [*] Remove .git folder?" "y"; then
        rm -rf ~/.config/nvim/.git
        echo -e "${OPTION}  [✓] .git folder removed.${RST}"
    fi
}
# The following commands are for installing zsh & oh-my-zsh.
setup_zsh() {
    install_pkg zsh zsh "Zsh: Extended shell with powerful features"
    sleep 1

    if ! ask "  [*] Install oh-my-zsh?" "y"; then
        return 0
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${OPTION}  [✓] Oh-My-Zsh already exists. Skipping...${RST}"
        sleep 2
    else
        if ! command -v curl >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] curl is not installed — cannot download oh-my-zsh.${RST}"
            return 1
        fi

        echo -e "${INFO}  [*] Installing Oh-My-Zsh framework...${RST}"
        echo -e "${ERROR}  [*] The shell will change after this — the script will exit.${RST}"
        echo -e "${INFO}  [*] Clone plugins manually afterwards for full ohmyzsh features.${RST}"
        echo ""

        # Download to a temp file first — never pipe curl directly into sh
        local omz_installer
        omz_installer=$(mktemp)
        if ! curl -fsSL \
                https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
                -o "$omz_installer" 2>/dev/null || [[ ! -s "$omz_installer" ]]; then
            echo -e "${ERROR}  [!] Failed to download oh-my-zsh installer.${RST}"
            rm -f "$omz_installer"
            return 1
        fi

        KEEP_ZSHRC=yes sh "$omz_installer"
        rm -f "$omz_installer"
    fi

    sleep 1

    if ! ask "  [*] Also install Powerlevel10k?" "y"; then
        return 0
    fi

    if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        echo -e "${OPTION}  [✓] Powerlevel10k already installed — skipping.${RST}"
        sleep 3
        return 0
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] git is not installed — cannot clone Powerlevel10k.${RST}"
        return 1
    fi

    echo -e "${INFO}  [*] Cloning Powerlevel10k...${RST}"
    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] Failed to clone Powerlevel10k — check your connection.${RST}"
        log FAIL "git clone failed for Powerlevel10k"
        return 1
    fi

    echo ""
    echo -e "${OPTION} [✓] Powerlevel10k installed. Run: p10k configure${RST}"
    log INSTALL "Powerlevel10k cloned successfully"
}
#  install_code_server — special installer for code-server
install_code_server() {
    if [[ "${PRIMARY_PKG_MANAGER:-}" != "pkg" ]]; then
        echo -e "${ERROR}  [!] code-server via tur-repo is only supported on Termux.${RST}"
        return 1
    fi
    echo -e "${OPTION}"
    if ask "[*] tur-repo is required for code-server. Install it?" "y"; then
        echo -e "${RST}"
        if ! progress_run "Installing tur-repo" \
                          "tur-repo ready" \
                          pkg install -y tur-repo; then
            echo -e "${ERROR}  [!] tur-repo failed to install — aborting code-server.${RST}"
            log FAIL "tur-repo install failed; code-server aborted"
            return 1
        fi
        echo ""
        install_pkg "code-server" "code-server" "Code-Server: VSCode on Android"
    else
        echo -e "${INFO}  [→] Skipping code-server installation.${RST}"
    fi
}
