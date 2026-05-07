#!/bin/bash

check_dependency() {
    local cmd="$1"
    local name="$2"
    local pm=$(detect_pkg_manager)
    
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
       echo ""
        echo -e "${ERROR} [✗] $name is NOT installed${RST}"
        
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
check_dependencies_menu() {
    local missing_count=0
    local missing_deps=()
   clear
    echo ""
    echo -e "${OPTION}  [*] Verifying required deps...${RST}"
     sleep 2
     echo ""
    # Define your dependencies here
    # Format: "command:Display Name:Install Hint"
    local dependencies=(
        "lolcat:Lolcat (Required)"
        "git:Git (Required)"
        "curl:cURL (Required)"
    )
    
    # Check each dependency
    for dep in "${dependencies[@]}"; do
        IFS=":" read -r cmd name hint <<< "$dep"
        if ! check_dependency "$cmd" "$name" "$hint"; then
            missing_deps+=("$cmd:$name:$hint")
            ((missing_count++))
        fi
    done
    
    # If nothing missing, return
    if [ $missing_count -eq 0 ]; then
        # echo ""
        echo -e "${OPTION}  [✓] All dependencies satisfied ${RST}"
         sleep 1
         clear
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
    echo -ne " ${BOLD_BRIGHT_MAGENTA}[*] Select option [1-4]: ${RST}" 
    read choice
    
    case $choice in
        1)
            auto_install_dependencies "${missing_deps[@]}"
            ;;
        2)
            show_install_commands "${missing_deps[@]}"
            check_dependencies_menu  # Check again after showing commands
            ;;
        3)
            echo -e "${INFO} [*] Continuing with missing dependencies...${RST}"
            sleep 1
            return 0
            ;;
        4|*)
            graceful_exit
            ;;
    esac
}

# Detect package manager and return appropriate install command
get_install_cmd() {
    local cmd="$1"
    local pm=$(detect_pkg_manager)
    
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
    local pm=$(detect_pkg_manager)
    local failed=()
    
    echo ""
    echo -e "${BOLD_BLUE} [*] Attempting to install missing deps ${RST}"
    
    for dep in "${deps[@]}"; do
        IFS=":" read -r cmd name hint <<< "$dep"
        
        echo -e "${INFO} [*] Installing: $name${RST}"
        
        case "$cmd" in
            lolcat)
                if install_lolcat; then
                    echo -e "${OPTION} [✓] Success${RST}"
                else
                    failed+=("$name")
                fi
                ;;
            git|curl)
                local install_cmd=$(get_install_cmd "$cmd")
                if [ -n "$install_cmd" ]; then
                    start_spinner " [*] Running: $install_cmd"
                    if eval "$install_cmd" >/dev/null 2>&1; then
                        stop_spinner "  [✓] Installed: $cmd"
                    else
                        stop_spinner "  [✗] Failed to install: $cmd"
                        failed+=("$name")
                    fi
                else
                    echo -e "${ERROR}  [✗] No auto-install for: $pm${RST}"
                    failed+=("$name")
                fi
                ;;
            *)
                echo -e "${ERROR}  [✗] Unsupported: $cmd${RST}"
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
    local pm=$(detect_pkg_manager)
    
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
echo -e "${INFO} ├─ Debian/Ubuntu: ${OPTION}sudo apt install lolcat ${RST}"
echo -e "${INFO} ├─ Arch Linux:    ${OPTION}sudo pacman -S lolcat ${RST}"
echo -e "${INFO} ├─ Termux:        ${OPTION}pkg install ruby && gem install lolcat ${RST}"
echo -e "${INFO} ├─ macOS:         ${OPTION}brew install lolcat ${RST}"
echo -e "${INFO} └─ Manual:        ${OPTION}gem install lolcat ${RST}"
            ;;
         git)
echo -e "${INFO} [*] Install git: ${RST}"
echo -e "${INFO}  |"
echo -e "${INFO}  ├─ Debian/Ubuntu: ${OPTION}sudo apt install git ${RST}"
echo -e "${INFO}  ├─ Arch:          ${OPTION}sudo pacman -S git ${RST}"
echo -e "${INFO}  ├─ Termux:        ${OPTION}pkg install git ${RST}"
echo -e "${INFO}  └─ macOS:         ${OPTION}brew install git ${RST}"
           ;;
       curl)
echo -e "${INFO} [*] Install curl: ${RST}"
echo -e "${INFO}  |"
echo -e "${INFO}  ├─ Debian/Ubuntu: ${OPTION}sudo apt install curl ${RST}"
echo -e "${INFO}  ├─ Arch:          ${OPTION}sudo pacman -S curl ${RST}"
echo -e "${INFO}  ├─ Termux:        ${OPTION}pkg install curl ${RST}"
echo -e "${INFO}  └─ macOS:         ${OPTION}brew install curl ${RST}"
            ;;
        *)
            echo -e "${INFO} [*] No hints for:${OPTION} $cmd ${RST}"
            ;;
    esac
}
# Improved show_install_commands
show_install_commands() {
    local deps=("$@")
    local pm=$(detect_pkg_manager)
    
    clear
    echo -e "${BOLD_GREEN}"
    boxed_text center " [*] Installation Instructions "
    echo -e "${RST}"
    
    echo -e "${INFO} [*] 📦 Detected package manager: ${OPTION}$pm${RST}\n"
    
    for dep in "${deps[@]}"; do
        IFS=":" read -r cmd name hint <<< "$dep"
        echo -e "${BOLD_YELLOW} ▶ $name${RST}"
         echo ""
        get_install_hints "$cmd"
        echo ""
    done
    
    echo -e "${INFO}💡 Tip: Run the script again after installing dependencies${RST}\n"
    read -p " [*] Press ENTER to continue..."
}
