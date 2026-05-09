#!/bin/bash
source lib/system/detect.sh
# detect_pkg_manager for install and tool check
PM="$(detect_pkg_manager)"
# This function here installs all tools put in it.
install_all() {
# For post-install summary detection
INSTALLED_PKGS=()
SKIPPED_PKGS=()
FAILED_PKGS=()
    log INSTALL "User chose to install all tools"
   # Checks for Internet before proceeding
    is_internet_up 
   # Update package lists
   echo ""
   progress_run "Syncing repositories" \
                 "Package lists updated" \
                 pkg_update
    sleep 0.1
   echo -e "${INFO}"
  if ask "  [!] Upgrade the system?" "n" 5; then
    echo -e "${RST}"
     progress_run "Upgrading system" \
                  "System upgrade complete" \
                  pkg_upgrade
    else
     echo ""
      boxed_text center "  [*] Skipping system upgrade"
    sleep 2
  fi

 clear
  tput civis
  be_patient
   echo -e "${OPTION}"
    boxed_text center "[*] Installing all tools"
    echo -e "${RST}"
   
    # ---- APT TOOLS ----
    install_pkg git git "Git: Version control"
    install_pkg curl curl "Curl: HTTP requests"
    install_pkg wget wget "Wget: File downloader"
    install_pkg bat bat "Bat: Better 'cat' alternative"
    install_pkg htop htop "Htop: Hardware use analyser"
    install_pkg fish fish "Fish: An advanced Shell"
    install_pkg ssh openssh "OpenSSH: Server deployment"
    install_pkg python3 python3 "Python3: A coding language"
    install_pkg nmap nmap "Nmap: Network scanner"
    install_pkg cacademo libcaca "Libcaca: AsCii Art Library"
    install_pkg speedtest-go speedtest-go "Speedtest-Go: Net-speed test"
    install_pkg cpufetch cpufetch "CPUfetch: Cpu-info"
    install_pkg neofetch neofetch "Neofetch: System-info"
    install_pkg ranger ranger "Ranger: A File Manager"
    install_pkg nano nano "Nano: Text editor"
    install_pkg sl sl "Sl: Steam Locomotive"
    install_pkg ncdu ncdu "Ncdu: disk use analyser"
    install_neovim_full 
    install_pkg cbonsai cbonsai "Cbonsai: CLI tree generator"
    install_pkg asciinema asciinema "Asciinema: Terminal-recorder"
    install_pkg croc croc "Croc: File-sender"
    install_pkg fzf fzf "Fzf: Fuzzy-Finder"
    install_pkg zoxide zoxide "Zoxide: A smarter 'cd'"
    install_zsh_full 
    install_pkg duf duf "Duf: File/dir size Checker"
    install_pkg tty-clock tty-clock "tty-clock: A terminal clock"
    install_pkg pipes.sh pipes.sh "Pipes.sh: Line-Snake"
    install_pkg yazi yazi "Yazi: A File Manager"
    install_pkg lsd lsd "Lsd: Batter 'ls' alternative"
    install_pkg broot broot "Broot: Filenavigator"
    install_pkg dust dust "Dust: Better 'du' alternative"
    install_pkg procs procs "Procs: Modern 'ps'"
    install_pkg tldr tldr "Tldr: Man pages"
    install_pkg gh gh "Gh: Github-Cli"
    # ---- PIP TOOLS ----
    install_lang "pip" "holehe" "Holehe: E-mail OSINT tool" "holehe"
    install_lang "pip" "asciiquarium" "AACCIQuarium: Animated terminal aquarium" "asciiquarium"
    install_lang "pip" "wttr" "Wttr.io: Console weather service" "wttr"
    install_pkg tmux tmux "Tmux: A multitasker"
    install_pkg lazygit lazygit "Lazygit: A git TUI"
    install_pkg ani-cli ani-cli "Ani-cli: A anime streamer"
    install_pkg code-server code-server "Code-Server: VsCode on android"
    install_lang "pip" "pipx" "Pipx: A isolated Py-app installer" "pipx"
    # -- post-install-summary
    echo ""
     post_install_summary
    echo -e "${OPTION}" 
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
# install_pkg "git" "git" "Git: Version control"
install_pkg() {
    local cmd="$1"  # command to check (git, curl, nmap, etc.)
    local pkg="$2"     # package name to install
    local name="$3"    # pretty name for display

    # installing or Skipped massges
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${OPTION}  [✓] $name is already installed - Skipping..${RST}"
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
            pkg install -y "$pkg"
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
               echo -e "${ERROR}  [x] Unsupported package manager: $PM${RST}"
                return 1
                ;;
        esac >/dev/null 2>&1
        # detection for post-install summary
        if [ $? -eq 0 ]; then
          INSTALLED_PKGS+=("$name")
           echo -e "${OPTION}"
           stop_spinner "  [✓] $name has installed successfully (via $PM)."
           echo -e "${RST}"
           log INSTALLED "$name installed successfully"
         else
          FAILED_PKGS+=("$name")
           echo -e "${ERROR}" 
            stop_spinner "  [x] Failed to install: $name."
           echo -e "${RST}"
           log FAIL "$name failed to install"
        fi
        sleep 2
    fi
}
# Universal language package installer (replaces install_pip)
# install_lang "pip" "holehe" "Holehe" "holehe"
install_lang() {
    local tool_type="$1"  # "pip", "npm", "gem", "cargo"
    local pkg_name="$2"   # package name to install
    local display_name="${3:-$pkg_name}" # package name to display
    local cmd="${4:-$pkg_name}"  # command to check (optional)
    
    # If cmd not specified, use pkg_name as command
    local check_cmd="${cmd:-$pkg_name}"
    
    # Detect the right package manager for this tool type
    local lang_pm=$(detect_pkg_for_tool "$tool_type")
    
    # Check if already installed
    if command -v "$check_cmd" >/dev/null 2>&1; then
        echo -e "${OPTION}  [✓] $display_name is already installed - Skipping..${RST}"
        SKIPPED_PKGS+=("$display_name")
        log SKIPPED "$display_name was already installed"
        sleep 1
        return 0
    fi
    
    # Check if package manager exists
    if [ "$lang_pm" = "none" ]; then
        echo -e "${ERROR}  [✗] $tool_type package manager not found - Cannot install $display_name${RST}"
        FAILED_PKGS+=("$display_name")
        return 1
    fi
    
    start_spinner "  [*] Installing: $display_name (via $lang_pm).."
    
    # Install based on detected language manager
    case "$lang_pm" in
        pip|pip3|pipx)
            $lang_pm install --quiet "$pkg_name" 2>/dev/null
            ;;
        npm)
            npm install -g --quiet "$pkg_name" 2>/dev/null
            ;;
        yarn)
            yarn global add --silent "$pkg_name" 2>/dev/null
            ;;
        gem)
            gem install --silent "$pkg_name" 2>/dev/null
            ;;
        cargo)
            cargo install --quiet "$pkg_name" 2>/dev/null
            ;;
        *)
            stop_spinner
            echo -e "${ERROR}  [✗] Unknown language manager: $lang_pm${RST}"
            FAILED_PKGS+=("$display_name")
            return 1
            ;;
    esac
    
    # Verify installation
    if command -v "$check_cmd" >/dev/null 2>&1; then
        INSTALLED_PKGS+=("$display_name")
        stop_spinner "${OPTION}  [✓] $display_name installed successfully (via $lang_pm)${RST}"
        log INSTALLED "$display_name installed via $lang_pm"
        sleep 1
        return 0
    else
        FAILED_PKGS+=("$display_name")
        stop_spinner "${ERROR}  [✗] Failed to install: $display_name${RST}"
        log FAIL "$display_name installation failed"
        sleep 2
        return 1
    fi
}
