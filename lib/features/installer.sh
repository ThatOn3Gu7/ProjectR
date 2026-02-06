#!/bin/bash
source $HOME/ProjectR/lib/system/detect.sh
# For post-install summary detection
INSTALLED_PKGS=()
SKIPPED_PKGS=()
FAILED_PKGS=()
# detect_pkg_manager for install and tool check
PM="$(detect_pkg_manager)"
# This function here installs all tools put in it.
install_all() {
    log INSTALL "User chose to install all tools"
   # Checks for Internet before proceeding
    is_internet_up 
   # Update package lists
   echo ""
    start_spinner "  [*] Updateing package list.."
     pkg_update
    stop_spinner "${OPT}${BOLD}  [✓] Package list refreshed..${RST}"
    sleep 0.1
   echo -e "${INFO}"
  if ask "  [!] Upgrade the system?" "n" 5; then
    echo -e "${RST}"
     start_spinner "  [*] Upgrading system..."
      pkg_upgrade
     stop_spinner "${OPT}${BOLD}  [✓] System Upgrade complete..${RST}"
    else
     echo ""
      boxed_text center "  [*] Skipping system upgrade"
    sleep 2
  fi

 clear
  tput civis
  be_patient
   echo -e "${OPT}${BOLD}"
    boxed_text center "[*] Installing all tools"
    echo -e "${RST}"
   
    # ---- APT TOOLS ----
    install_pkg git git "Git: Version control,"
    install_pkg curl curl "Curl: HTTP requests,"
    install_pkg wget wget "Wget: File downloader,"
    install_pkg bat bat "Bat: Better 'cat' alternative,"
    install_pkg htop htop "Htop: Hardware use analyser,"
    install_pkg fish fish "Fish: An advanced Shell,"
    install_pkg ssh openssh "OpenSSH: Server deployment,"
    install_pkg python3 python3 "Python3: A coding language,"
    install_pkg nmap nmap "Nmap: Network scanner,"
    install_pkg cacademo libcaca "Libcaca: AsCii Art Library,"
    install_pkg speedtest-go speedtest-go "Speedtest-Go: Net-speed test,"
    install_pkg cpufetch cpufetch "CPUfetch: Cpu-info,"
    install_pkg neofetch neofetch "Neofetch: System-info,"
    install_pkg ranger ranger "Ranger: A Filamanager,"
    install_pkg nano nano "Nano: Text editor,"
    install_pkg sl sl "Sl: Steam Locomotive,"
    install_pkg ncdu ncdu "Ncdu: disk use analyser,"
    install_neovim_full 
    install_pkg cbonsai cbonsai "Cbonsai: CLI tree generator,"
    install_pkg asciinema asciinema "Asciinema: Terminal-recoder,"
    install_pkg croc croc "Croc: File-sender,"
    install_pkg fzf fzf "Fzf: Fuzzy-Finder,"
    install_pkg zoxide zoxide "Zoxide: A smarter 'cd',"
    install_zsh_full 
    install_pkg duf duf "Duf: File/dir size Checker,"
    install_pkg tty-clock tty-clock "tty-clock: A terminal clock,"
    install_pkg pipes.sh pipes.sh "Pipes.sh: Line-Snake,"
    install_pkg yazi yazi "Yazi: Filamanager,"
    install_pkg lsd lsd "Lsd: Batter 'ls' alternative,"
    install_pkg broot broot "Broot: Filenavigator,"
    install_pkg dust dust "Dust: Better 'du' alternative,"
    install_pkg procs procs "Procs: Morden 'ps',"
    install_pkg tldr tldr "Tldr: Man pages,"
    install_pkg gh gh "Gh: Guthub-Cli"
    # ---- PIP TOOLS ----
    install_pip_package "holehe" "Holehe,"
    install_pip_package "asciiquarium" "Asciiqurium,"
    install_pip_package "wttr" "Wttr.io,"
    install_pkg tmux tmux "Tmux: A multitasker,"
    install_pkg lazygit lazygit "Lazygit: A git TUI,"
    install_pkg ani-cli ani-cli "Ani-cli: A anime streamer"
    # -- post-install-summary
    echo ""
     post_install_summary
    echo -e "${OPT}${BOLD}" 
     boxed_text center "[✓] installation Completed. Press ENTER to continue.."
    echo -e "${RST}"
   read -s
  tput cnorm

}

# For profile preset installation
install_preset() {
    local preset=("$@")

    for entry in "${preset[@]}"; do
        IFS="|" read -r cmd pkg name <<< "$entry"
        install_pkg "$cmd" "$pkg" "$name"
    done
}
# -- main installer function --
install_pkg() {
    local cmd="$1"  # command to check (git, curl, nmap, etc.)
    local pkg="$2"     # package name to install
    local name="$3"    # pretty name for display

    # installing or Skipped massges
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${OPT}${BOLD}  [✓] $name is already installed - Skipping..${RST}"
        SKIPPED_PKGS+=("$name")
        log SKIPPED "$name was already installed (Skipped)"
        sleep 1
    else
       start_spinner "  [*] Installing: $name.."

       # Use the detected package manager to install 
       case $PM in
        apt)
            apt-get update && apt-get install -y "$pkg"
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
            apk add "$pkg"
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
               echo -e "${ERR}${BOLD}  [x] Unsupported package manager: $PM${RST}"
                return 1
                ;;
        esac >/dev/null 2>&1
        # detection for post-install summary
        if [ $? -eq 0 ]; then
          INSTALLED_PKGS+=("$name")
           echo -e "${OPT}${BOLD}"
            stop_spinner "  [✓] $name has installed successfully."
           echo -e "${RST}"
           log INSTALLED "$name installed successfully"
         else
          FAILED_PKGS+=("$name")
           echo -e "${ERR}${BOLD}" 
            stop_spinner "  [x] Failed to install: $name."
           echo -e "${RST}"
           log FAIL "$name failed to install"
        fi
        sleep 2
    fi
}

# Function to inatall pip packages
# Usage: ensure_pip_package <package_name> [pip_package_name]
install_pip_package() {
    local command_name="$1"
    local package_name="${2:-$1}"  # Use second arg if provided, otherwise use command name
    local install_cmd=""

    # Determine which pip to use
    if command -v pip3 &> /dev/null; then
        install_cmd="pip3"
    elif command -v pip &> /dev/null; then
        install_cmd="pip"
    else
       echo -e "${ERR}${BOLD}"
        boxed_text center "  [x] ERR: Neither pip nor pip3 is available.."
      echo -e "${RST}"
       sleep 3
      return 1
    fi
    
    # Check if command already exists
    if command -v "$command_name" &> /dev/null; then
     SKIPPED_PKGS+=("$package_name")
      echo -e "${OPT}${BOLD}  [✓] $package_name is already installed - Skipping ${RST}"
        log SKIPPED "$package_name was already installed (Skipped)"
       sleep 1
      return 0
    fi
    
    # Install the package
    start_spinner "  [*] Installing: $package_name ($install_cmd)..."
    # Error handling
    if ! $install_cmd install --quiet "$command_name"; then
      FAILED_PKGS+=("$package_name")
       echo -e "${ERR}${BOLD}  [x] ERR: Failed to install $package_name..${RST}" >&2
        log FAIL "$package_name failed to installed"
        sleep 3
       return 1
    fi
    # Verify installation
    if command -v "$command_name" &> /dev/null; then
     INSTALLED_PKGS+=("$package_name")
      echo -e "${OPT}${BOLD}"
       stop_spinner "  [✓] Successfully installed: $package_name ($install_cmd).."
      echo -e "${RST}"
       log INSTALLED "$package_name successfully installed"
       sleep 3
      return 0
    else
        echo -e "${ERR}  [!] WARNING: $package_name installed but '$command_name' command not found..${RST}" >&2
        sleep 3
        return 0  # Still return success as package was installed
    fi
}
