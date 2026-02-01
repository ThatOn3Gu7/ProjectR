#!/bin/bash
# For post-install summary detection
INSTALLED_PKGS=()
SKIPPED_PKGS=()
FAILED_PKGS=()
# Source others
source $HOME/ProjectR/lib/detect.sh
source $HOME/ProjectR/lib/utils.sh
source $HOME/ProjectR/lib/presets.sh

# detect_pkg_manager for install and tool check
PM="$(detect_pkg_manager)"

# This function here installs all tools put in it.
install_all() {
    log INSTALL "User chose to install all tools"
   # Checks for Internet before proceeding
    is_internet_up 
    # Update package lists
   echo ""
    start_spinner " [*] Updateing package list.."
     pkg_update
    stop_spinner "${OPT}${BOLD} [✓] Package list refreshed..${RST}"
   echo ""
    sleep 0.1
   echo -e "${INFO}"
  if ask_yes_no " [!] Do you also want to upgrade the system?"; then
    echo -e "${RST}"
     start_spinner " [*] Upgrading system..."
      pkg_upgrade
     stop_spinner "${OPT}${BOLD} [✓] System Upgrade complete..${RST}"
    else
     boxed_text center "[*] Skipping system upgrade"
  fi

 clear
  tput civis
   echo -e "${OPT}$BOLD"
    boxed_text center "[*] Installing all essential tools"
   echo -e "${RST}"
   
    # ---- APT TOOLS ----
    install_pkg git git "Git: Version control," 
    install_pkg curl curl "Curl: File downloader 2," 
    install_pkg wget wget "Wget: File downloader," 
    install_pkg bat bat "Bat: Better then 'cat'," 
    install_pkg htop htop "Htop: Hardware use Checker," 
    install_pkg fish fish "Fish: A advanced Shell," 
    install_pkg ssh openssh "OpenSSH: Server deployment," 
    install_pkg python3 python3 "Python3: Coding language," 
    install_pkg nmap nmap "Nmap: Network scanner," 
    install_pkg cacademo libcaca "Libcaca: Cool fire," 
    install_pkg speedtest-go speedtest-go "Speedtest-Go: WI-FI-speed Checker," 
    install_pkg cpufetch cpufetch "CPUfetch: Cpu-info," 
    install_pkg neofetch neofetch "Neofetch: System-info," 
    install_pkg ranger ranger "Ranger: A Filamanager," 
    install_pkg nano nano "Nano: Text editor," 
    install_pkg sl sl "Sl: Steam Locomotive," 
    install_pkg ncdu ncdu "Ncdu: du Checker," 
    install_neovim_full 
    install_pkg cbonsai cbonsai "Cbonsai: Japanise tree," 
    install_pkg asciinema asciinema "Asciinema: Terminal-recoder," 
    install_pkg croc croc "Croc: File-sender," 
    install_pkg fzf fzf "Fzf: File-finder," 
    install_pkg zoxide zoxide "Zoxide: Smarter cd," 
    install_zsh_full 
    install_pkg duf duf "Duf: File/dir size Checker," 
    install_pkg tty-clock tty-clock "tty-clock: A big clock," 
    install_pkg pipes.sh pipes.sh "Pipes.sh: Line-Snake," 
    install_pkg yazi yazi "Yazi: Filamanager," 
    install_pkg lsd lsd "Lsd: 'ls' alternative," 
    install_pkg broot broot "Broot: Filenavigator," 
    install_pkg dust dust "Dust: Better version of du," 
    install_pkg procs procs "Procs: Morden 'ps'," 
    install_pkg tldr tldr "Tldr: Man pages," 
    install_pkg gh gh "Gh: Guthub-Cli"
    # ---- PIP TOOLS ----
    install_pip_package "holehe" "Holehe,"
    install_pip_package "asciiquarium" "Asciiqurium,"
    install_pip_package "wttr" "Wttr.io,"
    install_pkg tmux tmux "Tmux: A multitasker,"
    # -- post-install-summary
    echo ""
    post_install_summary
    echo -e "${OPT}${BOLD}" 
   boxed_text center "[✓] Install All Completed. Press ENTER to continue.."
    echo -e "${RST}"
    read
  tput cnorm

}

# For profile preset install
install_preset() {
    local preset=("$@")

    for entry in "${preset[@]}"; do
        IFS="|" read -r cmd pkg name <<< "$entry"
        install_pkg "$cmd" "$pkg" "$name"
    done
}

# The follwoing commands are for installing zsh & oh my zsh.
install_zsh_full() {
 install_pkg zsh zsh "Zsh: Most awesome shell,"
   sleep 1
    echo -e "${OPT}${BOLD}"
    if ask_yes_no " [*] Do you want you install oh-my-zsh?"; then
     if [ -d "$HOME/.oh-my-zsh" ]; then
         echo -e "${OPT}${BOLD} [✓] Oh My Zsh already exists. Skipping...${RST}"
          sleep 2
       else 
         echo -e "${OPT}${BOLD} [*] Installing Oh-My-Zsh framework...${RST}"
       KEEP_ZSHRC=yes RUNZSH=no CHSH=no \
         sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
      fi
     fi
    sleep 1 
    echo -e "${OPT}${BOLD}"
     if ask_yes_no " [!] Do you also want to install p10k..?"; then
      if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
       echo -e "${INFO}${BOLD} [✓] Powerlevel10k is already configured - Skipping..${RST}"
       sleep 3
       return 0 
      else  
       echo -e "${OPT}${BOLD} [*] Installing p10k..${RST}"
       git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
       echo ""
       echo -e "${OPT}${BOLD} [✓] Powerlevel10k is now installed, type: p10k configure${RST}"
      fi
     fi
}
# The follwoing commands are for installing Neovim & NvChad.
install_neovim_full() {
  install_pkg nvim neovim "Neovim: Best code editor,"
  install_pkg npm nodejs "Node.Js: JavaScript Runtime environment,"

  # Use the exact path that the LS command just confirmed
  local NV_CONFIG="$HOME/.config/nvim"
  echo -e "${OPT}${BOLD}"
 if ask_yes_no " [*] Do you want to install NvChad for NeoVim?"; then
  if [ -d "$NV_CONFIG" ]; then
    echo -e "${OPT}${BOLD} [✓] NvChad configuration already exists - Skipping..${RST}"
    sleep 1
  else
    echo ""
     echo -e "${INFO}${BOLD} [*] Downloading NvChad starter kit...${RST}"
      mkdir -p "$HOME/.config"
      git clone https://github.com/NvChad/starter ~/.config/nvim
     echo ""
    echo -e "${OPT}${BOLD} [✓] NvChad has been configured successfully.${RST}"
   sleep 2
  fi
 fi
}

# This script is here to identify and use the package manager it finds on the system to install packages
install_pkg() {
    local cmd="$1"  # command to check (git, curl, nmap, etc.)
    local pkg="$2"     # package name to install
    local name="$3"    # pretty name for display

    # Detect package manager
    # PM="$(detect_pkg_manager)"

    # For internet Check-up before continue
    if ! check_internet; then
     echo -e "${ERR}${BOLD}"
      boxed_text center "        It seems that you are not onlile
Please make sure to turn on WI-FI to continue ;)"
      echo -e "${RST}"
      log FAIL "$name not installed (no internet)"
       tput cnorm
      exit 0
    fi
    # installing or Skipped massges
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${OPT}${BOLD} [✓] $name is already installed - Skipping..${RST}"
        SKIPPED_PKGS+=("$name")
        log SKIPPED "$name was already installed (Skipped)"
        sleep 1
    else
        echo -e "${INFO}${BOLD}"
         start_spinner " [*] Installing: $name.."

       # Use the detected package manager to install 
       case $PM in
        apt)
            apt-get update >/dev/null 2>&1 && apt-get install -y "$pkg" >/dev/null 2>&1
            ;;
        dnf|yum)
            sudo $PM install -y "$pkg"
            ;;
        pacman)
            sudo pacman -Sy && pacman -S --noconfirm --needed "$pkg"
            ;;
        zypper)
            sudo zypper refresh && sudo zypper install -y "$pkg"
            ;;
        brew)
            brew install "$pkg"
            ;;
        apk)
            sudo apk add "$pkg"
            ;;
        emerge)
            sudo emerge -av "$pkg"
            ;;
        nix-env)
            nix-env -i "$pkg"
            ;;
        flatpak)
            flatpak install -y flathub "$pkg"
            ;;
        snap)
            sudo snap install "$pkg"
            ;;
        pkg)
            sudo pkg install -y "$pkg"
            ;;
        chocolatey)
            choco install -y "$pkg"
            ;;
        scoop)
            scoop install "$pkg"
            ;;
        winget)
            for pkg in "$pkg"; do
                winget install -e --id "$pkg"
            done
            ;;
            *) stop_spinner
               echo -e "${ERR}${BOLD} [x] Unsupported package manager: $PM${RST}"
                return 1
                ;;
        esac
        # detection for post-install summary
        if [ $? -eq 0 ]; then
          INSTALLED_PKGS+=("$name")
           echo -e "${OPT}${BOLD}"
            stop_spinner " [✓] $name has installed successfully."
           echo -e "${RST}"
           log INSTALLED "$name installed successfully"
         else
          FAILED_PKGS+=("$name")
           echo -e "${ERR}${BOLD}" 
            stop_spinner "[x] Failed to install $name."
           echo -e "${RST}"
           log FAIL "$name failed to install"
        fi
        # echo -e "${OPT}${BOLD} [✓] $name has installed successfully.${RST}"
        sleep 1
    fi
}

# Function to inatall pip packages
# Usage: ensure_pip_package <package_name> [pip_package_name]
install_pip_package() {
    local command_name="$1"
    local package_name="${2:-$1}"  # Use second arg if provided, otherwise use command name
    local install_cmd=""

    # For internet Check-up before continue
    if ! check_internet; then
     echo -e "${ERR}${BOLD}"
      boxed_text center "        It seems that you are not onlile
Please make sure to turn on WI-FI to continue ;)"
      echo -e "${RST}"
      log FAIL "$package_name not installed (no internet)"
       tput cnorm
      exit 0
    fi
    # Determine which pip to use
    if command -v pip3 &> /dev/null; then
        install_cmd="pip3"
    elif command -v pip &> /dev/null; then
        install_cmd="pip"
    else
        echo -e "${ERR}${BOLD}"
        boxed_text center "[x] ERR: Neither pip nor pip3 is available.."
        echo -e "${RST}"
        sleep 3
        return 1
    fi
    
    # Check if command already exists
    if command -v "$command_name" &> /dev/null; then
        echo -e "${OPT}${BOLD} [✓] $package_name is already installed - Skipping ${RST}"
        log SKIPPED "$package_name was already installed (Skipped)"
        sleep 3
        return 0
    fi
    
    # Install the package
    echo -e "${OPT}${BOLD} [*] Installing: $package_name...${RST}"
    if ! $install_cmd install --quiet "$command_name"; then
        echo -e "${ERR}${BOLD} [x] ERR: Failed to install $package_name..${RST}" >&2
        log FAIL "$package_name failed to installed"
        sleep 3
        return 1
    fi
    # Verify installation
    if command -v "$command_name" &> /dev/null; then
        echo -e "${OPT}${BOLD} [✓] Successfully installed $package_name..${RST}"
        log INSTALLED "$package_name successfully installed"
        sleep 3
        return 0
    else
        echo -e "${ERR} [!] WARNING: $package_name installed but '$command_name' command not found..${RST}" >&2
        sleep 3
        return 0  # Still return success as package was installed
    fi
}
