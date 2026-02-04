#!/bin/bash

# Check for a single dependency
check_dependency() {
    local cmd="$1"
    local name="$2"
    local install_hint="$3"  # Optional: How to install
    
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${OPT}${BOLD} [✓] $name is available${RST}"
        return 0
    else
        echo -e "${ERR}${BOLD} [✗] $name is NOT installed${RST}"
        if [ -n "$install_hint" ]; then
            echo -e "${INFO}      Hint: $install_hint${RST}"
        fi
        return 1
    fi
}

# Check multiple dependencies and show menu if missing
check_dependencies_menu() {
    local missing_count=0
    local missing_deps=()
    
    echo -e "${LOGO}${BOLD}"
    boxed_text center " [*] Dependency Check!"
    echo -e "${RST}"
    
    # Define your dependencies here
    # Format: "command:Display Name:Install Hint"
    local dependencies=(
        "lolcat:lolcat (Colors):Install with 'pkg install ruby && gem install lolcat' or 'apt install lolcat'"
        "git:Git (Optional):'pkg install git' or 'apt install git'"
        "curl:cURL (Optional):'pkg install curl' or 'apt install curl'"
    )
    
    # Check each dependency
    for dep in "${dependencies[@]}"; do
        IFS=":" read -r cmd name hint <<< "$dep"
        if ! check_dependency "$cmd" "$name" "$hint"; then
            missing_deps+=("$cmd:$name:$hint")
            ((missing_count++))
        fi
        sleep 0.1
    done
    
    # If nothing missing, return
    if [ $missing_count -eq 0 ]; then
        echo ""
        echo -e "${OPT}${BOLD} [✓] All dependencies satisfied${RST}"
        sleep 1
        return 0
    fi
    
    echo ""
    echo -e "${ERR}${BOLD} [!] $missing_count dependency(ies) missing!${RST}"
    echo ""
    
    # Ask user what to do
    echo -e "${INFO}${BOLD}"
    boxed_text left "Options:"
    echo -e "${RST}"
    echo -e "${OPT}  [1] Try to auto-install missing dependencies${RST}"
    echo -e "${OPT}  [2] Show installation commands${RST}"
    echo -e "${OPT}  [3] Continue anyway (not recommended)${RST}"
    echo -e "${ERR}  [4] Exit script${RST}"
    echo ""
    
    local choice
    read -p " [*] Select option [1-4]: " choice
    
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

# Try to auto-install missing dependencies
auto_install_dependencies() {
    local deps=("$@")
    local PM="$(detect_pkg_manager)"
    
    echo ""
    echo -e "${INFO}${BOLD} [*] Attempting to install missing dependencies...${RST}"
    
    for dep in "${deps[@]}"; do
        IFS=":" read -r cmd name hint <<< "$dep"
        
        echo -e "${INFO} [*] Installing: $name...${RST}"
        
        case "$cmd" in
            lolcat)
                install_lolcat
                ;;
            git|curl|wget)
                # Use system package manager
                case "$PM" in
                    apt|pkg)
                        start_spinner " [*] Installing $name..."
                        $PM install -y "$cmd" >/dev/null 2>&1
                        if [ $? -eq 0 ]; then
                            stop_spinner "  [✓] Installed: $name"
                        else
                            stop_spinner "  [✗] Failed to install: $name"
                            echo -e "${INFO}  [!] Try: $hint${RST}"
                        fi
                        ;;
                    *)
                        echo -e "${ERR}  [!] Cannot auto-install $name on $PM${RST}"
                        echo -e "${INFO} [!] Try: $hint${RST}"
                        ;;
                esac
                ;;
            *)
                echo -e "${ERR}  [x] Cannot auto-install: $name${RST}"
                echo -e "${INFO} [!] Manual install: $hint${RST}"
                ;;
        esac
        sleep 1
    done
    
    echo ""
    read -p " [*] Press ENTER to continue..."
}

# Special function to install lolcat (tricky on different systems)
install_lolcat() {
    local PM="$(detect_pkg_manager)"
    
    case "$PM" in
        apt)
            start_spinner " [*] Installing lolcat via apt..."
            apt install -y lolcat >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                stop_spinner " [✓] Installed lolcat"
                return 0
            fi
            stop_spinner ""
            ;;
        pkg)  # Termux
            start_spinner " [*] Installing Ruby and lolcat..."
            pkg install -y ruby >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                gem install lolcat >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    stop_spinner " [✓] Installed lolcat"
                    return 0
                fi
            fi
            stop_spinner ""
            ;;
        pacman)
            start_spinner " [*] Installing lolcat..."
            pacman -Sy --noconfirm lolcat >/dev/null 2>&1
            stop_spinner ""
            ;;
    esac
    
    # If auto-install failed
    echo -e "${ERR}  [✗] Could not auto-install lolcat${RST}"
    echo -e "${INFO}  Try manual install:"
    echo -e "${INFO}  - For Termux: pkg install ruby && gem install lolcat"
    echo -e "${INFO}  - For Debian/Ubuntu: apt install lolcat"
    echo -e "${INFO}  - Or install from: https://github.com/busyloop/lolcat${RST}"
    return 1
}

# Show installation commands for missing deps
show_install_commands() {
    local deps=("$@")
    local PM="$(detect_pkg_manager)"
    
    clear
    echo -e "${LOGO}${BOLD}"
    boxed_text center " [*] Installation Instructions"
    echo -e "${RST}"
    
    echo -e "${INFO} [*] Package manager detected: $PM${RST}"
    echo ""
    
    for dep in "${deps[@]}"; do
        IFS=":" read -r cmd name hint <<< "$dep"
        echo -e "${OPT}${BOLD} [*] $name:${RST}"
        echo -e "${INFO} [!] $hint${RST}"
        echo ""
    done
    
    echo -e "${INFO} [*] After installing, restart the script.${RST}"
    echo ""
    read -p " [*] Press ENTER when ready to continue..."
}

# Lightweight check (just lolcat) for startup
check_lolcat() {
    if ! command -v lolcat >/dev/null 2>&1; then
        echo -e "${ERR}${BOLD}"
        boxed_text center " [!] lolcat not found - colors will be limited"
        echo -e "${INFO}${BOLD}"
        boxed_text center " [!] Install with: pkg install ruby && gem install lolcat"
        echo -e "${INFO} [*] Or continue without full colors [Enter]${RST}"
        read
        return 1
    fi
    return 0
}
