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
  if ask "  [!] Upgrade the system?" "n"; then
    echo -e "${RST}"
     progress_run "Upgrading system" \
                  "System upgrade complete" \
                  pkg_upgrade
    else
     echo ""
      print_box center "  [*] Skipping system upgrade"
    sleep 2
  fi

 clear
  safe_tput civis
  show_install_wait
   echo -e "${OPTION}"
    print_box center "[*] Installing all tools"
    echo -e "${RST}"
   
for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"

        case "$type" in
            pkg)
                install_pkg "$cmd" "$pkg" "$name"
                ;;
            pip)
                install_lang "pip" "$pkg" "$name" "$cmd"
                ;;
            special)
                # Call the special install function by name
                "$extra"
                ;;
        esac
    done

    # -- post-install-summary
    echo ""
     post_install_summary
    echo -e "${OPTION}" 
     print_box center "[✓] installation Completed. Press ENTER to continue.."
    echo -e "${RST}"
   read -s
  safe_tput cnorm

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
       start_spinner "  [*] Installing: $name (via $PM).."

       # Use the detected package manager to install 
       case $PM in
        apt)
            apt-get update && apt-get install -y "$pkg"
            ;;
        dnf|yum)
            sudo $PM install -y "$pkg"
            ;;
        pacman)
            sudo pacman -Sy && sudo pacman -S --noconfirm --needed "$pkg"
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
        nix)
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
                winget install -e --id "$pkg"
            ;;
            *) stop_spinner
               echo -e "${ERROR}  [x] Unsupported package manager: $PM${RST}"
                return 1
                ;;
        esac >/dev/null 2>&1
        # detection for post-install summary
        if [ $? -eq 0 ]; then
          INSTALLED_PKGS+=("$name") 
          stop_spinner "${OPTION}  [✓] $name has installed successfully (via $PM). ${RST}"
          log INSTALLED "$name installed successfully (via $PM)"
        else
          FAILED_PKGS+=("$name")
          echo -e
          stop_spinner "${ERROR}  [x] Failed to install: $name. ${RST}"
          log FAIL "$name failed to install (on $PM)"
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
#  install_code_server — special installer for code-server
install_code_server() {
    echo -e "${OPTION}"
    if ask "[*] tur-repo is required to install code-server, install it?" "y"; then
        echo -e "${RST}"
        progress_run "Installing tur-repo" \
                     "Installation successful" \
                     pkg install tur-repo 
        echo ""
        install_pkg code-server code-server "Code-Server: VSCode on Android"
    fi
}
