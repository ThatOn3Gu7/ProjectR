#!/bin/bash

check_dependency() {
    local cmd="$1"
    local name="$2"
    local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
       echo ""
        echo -e "${ERROR} [✗] "$name" is NOT installed${RST}"
        
        # Generate cross-platform hint
        local hint=""
        case "$pm-$cmd" in
            apt-lolcat)     hint="sudo apt install ruby && gem install lolcat" ;;
            apt-curl)       hint="sudo apt install curl" ;;
            apt-git)        hint="sudo apt install git" ;;
            pacman-lolcat)  hint="sudo pacman -S lolcat" ;;
            pacman-curl)    hint="sudo pacman -S curl" ;;
            pacman-git)     hint="sudo pacman -S git" ;;
            pkg-lolcat)     hint="pkg install ruby && gem install lolcat" ;;
            pkg-curl)       hint="pkg install curl" ;;
            pkg-git)        hint="pkg install git" ;;
            brew-lolcat)    hint="brew install lolcat" ;;
            brew-curl)      hint="brew install curl" ;;
            brew-git)       hint="brew install git" ;;
            apk-lolcat)     hint="apk add lolcat" ;;
            apk-curl)       hint="apk add curl" ;;
            apk-git)        hint="apk add git" ;;
            *)              hint="Install $cmd using your package manager" ;;
        esac
        
        echo -e "${INFO} [!] Try: $hint${RST}"
        return 1
    fi
}
# Check multiple dependencies and show menu if missing
verify_dependencies() {
   # ONE-TIME: if user already chose to skip dep check, honour it
    if [ "$(config_get 'skip_dep_check')" = "true" ]; then
        return 0
    fi
    local missing_count=0
    local missing_deps=()
    # Define dependencies here
    # Format: "command:Display Name"
    local dependencies=(
        "lolcat:Lolcat (Required)"
        "git:Git (Required)"
        "curl:cURL (Required)"
    )
    
    # Check each dependency
    for dep in "${dependencies[@]}"; do
        IFS=":" read -r cmd name <<< "$dep"
        if ! check_dependency "$cmd" "$name"; then
            missing_deps+=("$cmd:$name")
            ((missing_count++))
        fi
    done
    
    # If nothing missing, return
    if [ $missing_count -eq 0 ]; then
        return 0
    fi
    
    echo ""
    echo -e "${ERROR} [!] $missing_count dependency(ies) missing!${RST}"
    echo ""
    
    # Tell user what to do
     echo -e " ${BOLD_YELLOW}[*] Options:${RST}"
    echo ""
    echo -e "${OPTION}  [1] Try to auto-install missing dependencies${RST}"
    echo -e "${OPTION}  [2] Show manual installation commands${RST}"
    echo -e "${OPTION}  [3] Continue anyway (not recommended)${RST}"
    echo -e "${ERROR}  [4] Exit script${RST}"
    echo ""
    
    local choice
    echo -ne " ${BRIGHT_MAGENTA}[*] Select option [1-4]: ${RST}" 
    read -r choice
    
    case $choice in
        1)
            auto_install_dependencies "${missing_deps[@]}"
            ;;
        2)
            show_install_commands "${missing_deps[@]}"
            ;;
        3) 
          if ask " [*] Save as Preferences for next time?" "y"; then
           echo -e "${INFO} [*] Continuing with missing dependencies (Saved Preferences)...${RST}"
            config_set "skip_dep_check" "true"
            sleep 1
            return 0
           else
            echo -e "${INFO} [*] Continuing with missing dependencies (Preferences not saved)...${RST}"
            return 0
          fi
            ;;
        4)
            graceful_exit
            ;;
        *)
          echo -e "${BOLD_RED} [!] Imvalid Input:${RST} '$choice'"
         sleep 1
    esac
}

# Detect package manager and return appropriate install command
get_install_cmd() {
    local cmd="$1"
    local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    
    case "$pm" in
        apt)
            echo "apt install -y $cmd"
            ;;
        pacman)
            echo "pacman -S --noconfirm $cmd"
            ;;
        dnf|yum)
            echo "$pm install -y $cmd"
            ;;
        pkg)  # Termux
            echo "pkg install -y $cmd"
            ;;
        brew)
            echo "brew install $cmd"
            ;;
        apk) 
            echo "apk add $cmd"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Improved auto-install with better error handling
auto_install_dependencies() {
    local deps=("$@")
    local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    local failed=()
    
    echo ""
    echo -e "${BOLD_BLUE} [*] Attempting to install missing deps ${RST}"
    
    for dep in "${deps[@]}"; do
        IFS=":" read -r cmd name <<< "$dep"
        
        start_spinner " [*] Installing: "$name".."
        
        case "$cmd" in
            lolcat)
                if install_lolcat >/dev/null 2>&1; then
                    stop_spinner "${OPTION} [✓] Success${RST}"
                else
                    stop_spinner ""
                    failed+=("$name")
                fi
                ;;
          git|curl)
               local install_arr=()
                case "$pm" in
                    apt)    install_arr=(sudo apt-get install -y "$cmd") ;;
                    pacman) install_arr=(sudo pacman -S --noconfirm "$cmd") ;;
                    pkg)    install_arr=(pkg install -y "$cmd") ;;
                    brew)   install_arr=(brew install "$cmd") ;;
                    apk)    install_arr=(sudo apk add "$cmd") ;;
                    *)      echo -e "${ERROR}  [✗] No auto-install for: $pm${RST}"; failed+=("$name"); continue ;;
                esac
                if "${install_arr[@]}" >/dev/null 2>&1; then
                    stop_spinner "${OPTION}  [✓] Installed: $cmd ${RST}"
                else
                    stop_spinner "${ERROR}  [✗] Failed: $cmd ${RST}"
                    failed+=("$name")
                fi
                ;;
            *)
                echo -e "${ERROR}  [✗] Unsupported: $cmd${RST}"
                sleep 2
                failed+=("$name")
                ;;
        esac
        sleep 0.5
    done
    
    # Report results
    if [ ${#failed[@]} -eq 0 ]; then
        echo -e "${OPTION} [✓] Missing dependencies installed! ${RST}"
    else
        echo -e "${ERROR}  [✗] Failed to install: ${failed[*]} ${RST}"
        show_install_commands "${deps[@]}"
    fi
    
    sleep 2
}
# Special function to install lolcat (tricky on different systems)
install_lolcat() {
    local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    
    # Try system package manager first
    case "$pm" in
        apt)
            apt install -y lolcat >/dev/null 2>&1 && return 0
            # Fallback to gem if apt fails
            apt install -y ruby >/dev/null 2>&1 && gem install lolcat 2>/dev/null && return 0
            ;;
        pacman)
            pacman -S --noconfirm lolcat 2>/dev/null && return 0
            ;;
        pkg)
            pkg install -y lolcat >/dev/null 2>&1 && return 0
            # Fallback to gem if pkg fails
            pkg install -y ruby >/dev/null 2>&1 && gem install lolcat 2>/dev/null && return 0
            ;;
        brew)
            brew install lolcat 2>/dev/null && return 0
            ;;
        apk) 
            apk add lolcat >/dev/null 2>&1 && return 0
            ;;
    esac
    
    # Last resort: try gem directly
    if command -v gem >/dev/null 2>&1; then
        gem install lolcat 2>/dev/null && return 0
    fi
    
    return 1
}
# Generate install hints for multiple package managers
get_install_hints() {
    local cmd="$1"
    
    case "$cmd" in
        lolcat)
echo -e "${INFO}[*] Install lolcat on different systems: ${RST}"
echo -e "${INFO} |"
echo -e "${INFO} ├─ Debian/Ubuntu:     ${OPTION}sudo apt install lolcat ${RST}"
echo -e "${INFO} ├─ Arch Linux:        ${OPTION}sudo pacman -S lolcat ${RST}"
echo -e "${INFO} ├─ Fedora/RHEL:       ${OPTION}sudo dnf install lolcat ${RST}"
echo -e "${INFO} ├─ openSUSE:          ${OPTION}sudo zypper install lolcat ${RST}"
echo -e "${INFO} ├─ Alpine Linux:      ${OPTION}sudo apk add lolcat ${RST}"
echo -e "${INFO} ├─ Void Linux:        ${OPTION}sudo xbps-install -S lolcat ${RST}"
echo -e "${INFO} ├─ NixOS:             ${OPTION}nix-shell -p lolcat ${RST}"
echo -e "${INFO} ├─ Gentoo:            ${OPTION}sudo emerge --ask app-misc/lolcat ${RST}"
echo -e "${INFO} ├─ FreeBSD:           ${OPTION}sudo pkg install lolcat ${RST}"
echo -e "${INFO} ├─ NetBSD/pkgsrc:     ${OPTION}sudo pkgin install lolcat ${RST}"
echo -e "${INFO} ├─ macOS (Homebrew):  ${OPTION}brew install lolcat ${RST}"
echo -e "${INFO} ├─ macOS (MacPorts):  ${OPTION}sudo port install lolcat ${RST}"
echo -e "${INFO} ├─ Termux:            ${OPTION}pkg install ruby && gem install lolcat ${RST}"
echo -e "${INFO} ├─ Windows (Choco):   ${OPTION}choco install lolcat ${RST}"
echo -e "${INFO} ├─ Windows (Scoop):   ${OPTION}scoop install lolcat ${RST}"
echo -e "${INFO} ├─ Snap:              ${OPTION}sudo snap install lolcat ${RST}"
echo -e "${INFO} ├─ Flatpak:           ${OPTION}flatpak install flathub com.github.jaseg.lolcat ${RST}"
echo -e "${INFO} ├─ Ruby Gem:          ${OPTION}gem install lolcat ${RST}"
echo -e "${INFO} └─ Source/Git:        ${OPTION}git clone https://github.com/busyloop/lolcat && cd lolcat && gem build lolcat.gemspec && gem install lolcat-*.gem ${RST}"
            ;;
         git)
echo -e "${INFO}[*] Install Git on different systems: ${RST}"
echo -e "${INFO} |"
echo -e "${INFO} ├─ Debian/Ubuntu:     ${OPTION}sudo apt install git ${RST}"
echo -e "${INFO} ├─ Arch Linux:        ${OPTION}sudo pacman -S git ${RST}"
echo -e "${INFO} ├─ Fedora/RHEL:       ${OPTION}sudo dnf install git ${RST}"
echo -e "${INFO} ├─ openSUSE:          ${OPTION}sudo zypper install git ${RST}"
echo -e "${INFO} ├─ Alpine Linux:      ${OPTION}sudo apk add git ${RST}"
echo -e "${INFO} ├─ Void Linux:        ${OPTION}sudo xbps-install -S git ${RST}"
echo -e "${INFO} ├─ NixOS:             ${OPTION}nix-shell -p git ${RST}"
echo -e "${INFO} ├─ Gentoo:            ${OPTION}sudo emerge --ask dev-vcs/git ${RST}"
echo -e "${INFO} ├─ FreeBSD:           ${OPTION}sudo pkg install git ${RST}"
echo -e "${INFO} ├─ NetBSD/pkgsrc:     ${OPTION}sudo pkgin install git ${RST}"
echo -e "${INFO} ├─ macOS (Homebrew):  ${OPTION}brew install git ${RST}"
echo -e "${INFO} ├─ macOS (MacPorts):  ${OPTION}sudo port install git ${RST}"
echo -e "${INFO} ├─ Termux:            ${OPTION}pkg install git ${RST}"
echo -e "${INFO} ├─ Windows (Choco):   ${OPTION}choco install git ${RST}"
echo -e "${INFO} ├─ Windows (Scoop):   ${OPTION}scoop install git ${RST}"
echo -e "${INFO} ├─ Windows (winget):  ${OPTION}winget install Git.Git ${RST}"
echo -e "${INFO} ├─ Snap:              ${OPTION}sudo snap install git ${RST}"
echo -e "${INFO} ├─ Flatpak:           ${OPTION}flatpak install flathub org.gnome.gitlab.albfan.GitCola ${RST}"
echo -e "${INFO} └─ Source:            ${OPTION}git clone https://github.com/git/git.git && cd git && make configure && ./configure --prefix=/usr && make all && sudo make install ${RST}"
           ;;
       curl)
echo -e "${INFO}[*] Install cURL on different systems: ${RST}"
echo -e "${INFO} |"
echo -e "${INFO} ├─ Debian/Ubuntu:     ${OPTION}sudo apt install curl ${RST}"
echo -e "${INFO} ├─ Arch Linux:        ${OPTION}sudo pacman -S curl ${RST}"
echo -e "${INFO} ├─ Fedora/RHEL:       ${OPTION}sudo dnf install curl ${RST}"
echo -e "${INFO} ├─ openSUSE:          ${OPTION}sudo zypper install curl ${RST}"
echo -e "${INFO} ├─ Alpine Linux:      ${OPTION}sudo apk add curl ${RST}"
echo -e "${INFO} ├─ Void Linux:        ${OPTION}sudo xbps-install -S curl ${RST}"
echo -e "${INFO} ├─ NixOS:             ${OPTION}nix-shell -p curl ${RST}"
echo -e "${INFO} ├─ Gentoo:            ${OPTION}sudo emerge --ask net-misc/curl ${RST}"
echo -e "${INFO} ├─ FreeBSD:           ${OPTION}sudo pkg install curl ${RST}"
echo -e "${INFO} ├─ NetBSD/pkgsrc:     ${OPTION}sudo pkgin install curl ${RST}"
echo -e "${INFO} ├─ macOS (Homebrew):  ${OPTION}brew install curl ${RST}"
echo -e "${INFO} ├─ macOS (MacPorts):  ${OPTION}sudo port install curl ${RST}"
echo -e "${INFO} ├─ Termux:            ${OPTION}pkg install curl ${RST}"
echo -e "${INFO} ├─ Windows (Choco):   ${OPTION}choco install curl ${RST}"
echo -e "${INFO} ├─ Windows (Scoop):   ${OPTION}scoop install curl ${RST}"
echo -e "${INFO} ├─ Windows (winget):  ${OPTION}winget install curl.curl ${RST}"
echo -e "${INFO} ├─ Snap:              ${OPTION}sudo snap install curl ${RST}"
echo -e "${INFO} ├─ Flatpak:           ${OPTION}flatpak install flathub org.curl.curl ${RST}"
echo -e "${INFO} └─ Source:            ${OPTION}git clone https://github.com/curl/curl.git && cd curl && ./buildconf && ./configure && make && sudo make install ${RST}"
            ;;
        *)
            echo -e "${INFO} [*] No hints for:${OPTION} $cmd ${RST}"
            ;;
    esac
}
# Improved show_install_commands
show_install_commands() {
    local deps=("$@")
    local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    
    echo -e "${BOLD_GREEN}"
    print_box center " [*] Installation Instructions "
    echo -e "${RST}"
    
    echo -e "${INFO} [*] 📦 Detected package manager: ${OPTION}$pm${RST}\n"
    
    for dep in "${deps[@]}"; do
        IFS=":" read -r cmd name hint <<< "$dep"
        echo -e "${BOLD_YELLOW} ▶ "$name"${RST}"
         echo ""
        get_install_hints "$cmd"
        echo ""
    done
    
    echo -e "${INFO}💡 Tip: Run the script again after installing dependencies${RST}\n"
    echo -e "${BOLD_GREEN}"
    read -p " [*] Press any KEY to exit..."
    clear
  exit 0
}
