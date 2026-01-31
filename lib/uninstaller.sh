#!/bin/bash
# ... your existing utils.sh code ...

# ============================================================================
# UNINSTALLER FUNCTIONS
# ============================================================================

# Shows uninstall menu
show_uninstall_menu() {
    clear
    echo -e "${LOGO}${BOLD}"
    cat <<"EOF" | lolcat
      _   _       _           _   _           _   
     | | | |     (_)         | | | |         | |  
     | | | |_ __  _ _ __  ___| |_| | __ _ ___| |_ 
     | | | | '_ \| | '_ \/ __| __| |/ _` / __| __|
     | |_| | | | | | | | \__ \ |_| | (_| \__ \ |_ 
      \___/|_| |_|_|_| |_|___/\__|_|\__,_|___/\__|
                                                  
        ━━━━━━━━━━━━━━ [ REMOVE INSTALLED TOOLS ] ━━━━━━━━━━━━━━
EOF
    echo -e "${RST}"
    
    echo -e "${OPTION}${BOLD}"
    boxed_text left "[*] Select tools to uninstall (space-separated numbers):"
    echo -e "${RST}"
    
    echo -e "${BARRIER}   ╔══════════════════════════════════════════╗${RST}"
    
    # List all tools with installation status
    local tools=(
        "git:Git" "curl:Curl" "wget:Wget" "bat:Bat" "htop:Htop"
        "fish:Fish Shell" "ssh:OpenSSH" "python3:Python 3" "nmap:Nmap"
        "cacademo:Libcaca" "speedtest-go:Speedtest Go" "cpufetch:CPUfetch"
        "neofetch:Neofetch" "ranger:Ranger" "nano:Nano" "sl:Steam Locomotive"
        "ncdu:NCDU" "nvim:Neovim" "cbonsai:Cbonsai" "asciinema:Asciinema"
        "croc:Croc" "fzf:FZF" "zoxide:Zoxide" "zsh:Zsh" "duf:DUF"
        "tty-clock:TTY Clock" "pipes.sh:Pipes.sh" "yazi:Yazi" "lsd:LSD"
        "broot:Broot" "dust:Dust" "procs:Procs" "tldr:TLDR"
        "node:Node.js" "gh:GitHub CLI" "tmux:TMUX"
    )
    
    local index=1
    local installed_tools=()
    
    for tool_info in "${tools[@]}"; do
        IFS=":" read -r cmd name <<< "$tool_info"
        
        # Check if installed
        if command -v "$cmd" >/dev/null 2>&1 || is_pkg_installed "$cmd"; then
            echo -e "${BARRIER}   ║${RST}${ERROR} [${WHITE}$index${ERROR}] ${name}${RST}"
            installed_tools+=("$cmd:$name")
            ((index++))
        fi
    done
    
    echo -e "${BARRIER}   ║${RST}"
    echo -e "${BARRIER}   ║${RST}${OPTION} [${WHITE}a${OPTION}] Uninstall ALL listed tools${RST}"
    echo -e "${BARRIER}   ║${RST}${OPTION} [${WHITE}b${OPTION}] Back to main menu${RST}"
    echo -e "${BARRIER}   ╚══════════════════════════════════════════╝${RST}"
    echo ""
    
    if [ ${#installed_tools[@]} -eq 0 ]; then
        echo -e "${INFO}${BOLD}"
        boxed_text center "No tools found to uninstall!"
        echo -e "${RST}"
        sleep 2
        return 1
    fi
    
    echo -ne "${INFO}${BOLD} [*] Enter selection(s): ${RST}"
    read -r selection
    echo ""
    
    # Handle special cases
    case "$selection" in
        b|B) return 0 ;;
        a|A) 
            echo -e "${ERROR}${BOLD}"
            if ask_yes_no " Uninstall ALL ${#installed_tools[@]} tools? This cannot be undone!"; then
                for tool_info in "${installed_tools[@]}"; do
                    IFS=":" read -r cmd name <<< "$tool_info"
                    uninstall_pkg "$cmd" "$name"
                done
            fi
            return 0
            ;;
    esac
    
    # Process numbered selections
    for sel in $selection; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#installed_tools[@]} ]; then
            local idx=$((sel - 1))
            IFS=":" read -r cmd name <<< "${installed_tools[$idx]}"
            uninstall_pkg "$cmd" "$name"
        else
            echo -e "${ERROR}${BOLD} [x] Invalid selection: $sel${RST}"
            sleep 1
        fi
    done
    
    echo -e "${OPTION}${BOLD}"
    boxed_text center "[✓] Uninstallation complete. Press ENTER..."
    echo -e "${RST}"
    read
}

# Main uninstall function
uninstall_pkg() {
    local cmd="$1"      # Command to check (git, curl, etc.)
    local name="$2"     # Pretty name for display
    
    # Detect package manager
    PM="$(detect_pkg_manager)"
    
    log UNINSTALL "Attempting to uninstall: $name"
    
    # Check if actually installed
    if ! command -v "$cmd" >/dev/null 2>&1 && ! is_pkg_installed "$cmd"; then
        echo -e "${INFO}${BOLD} [→] $name is not installed - Skipping${RST}"
        log SKIP "$name not installed (nothing to remove)"
        return 0
    fi
    
    # Ask for confirmation
    echo -e "${ERROR}${BOLD}"
    if ! ask_yes_no " Uninstall $name?"; then
        echo -e "${INFO}${BOLD} [→] Skipping $name${RST}"
        return 0
    fi
    echo -e "${RST}"
    
    echo -e "${INFO}${BOLD} [*] Removing: $name...${RST}"
    
    # Special handling for tools with configurations
    case "$cmd" in
        nvim)
            # Remove Neovim configs
            if [ -d "$HOME/.config/nvim" ]; then
                echo -e "${INFO} Removing Neovim configuration..."
                rm -rf "$HOME/.config/nvim"
            fi
            ;;
        zsh)
            # Remove Oh My Zsh
            if [ -d "$HOME/.oh-my-zsh" ]; then
                echo -e "${INFO} Removing Oh My Zsh..."
                rm -rf "$HOME/.oh-my-zsh"
            fi
            # Remove powerlevel10k
            if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
                rm -rf "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
            fi
            ;;
    esac
    
    # Determine actual package name
    local pkg_name="$cmd"
    
    # Map commands to package names (for tools where command != package name)
    case "$cmd" in
        ssh) pkg_name="openssh-client" ;;
        python3) pkg_name="python3" ;;
        cacademo) pkg_name="libcaca" ;;
        speedtest-go) pkg_name="speedtest-go" ;;
        tty-clock) pkg_name="tty-clock" ;;
        pipes.sh) pkg_name="pipes.sh" ;;
        node) pkg_name="nodejs" ;;
        nvim) pkg_name="neovim" ;;
    esac
    
    # Uninstall using appropriate package manager
    case "$PM" in
        apt)
            sudo apt remove -y "$pkg_name" 2>/dev/null
            sudo apt autoremove -y 2>/dev/null
            ;;
        dnf|yum)
            sudo $PM remove -y "$pkg_name" 2>/dev/null
            ;;
        pacman)
            sudo pacman -Rs --noconfirm "$pkg_name" 2>/dev/null
            ;;
        brew)
            brew uninstall "$pkg_name" 2>/dev/null
            ;;
        pkg) # Termux
            pkg uninstall -y "$pkg_name" 2>/dev/null
            ;;
        *)
            # Generic fallback - just try to remove
            sudo $PM remove -y "$pkg_name" 2>/dev/null || true
            ;;
    esac
    
    # Check if uninstall was successful
    if ! command -v "$cmd" >/dev/null 2>&1 && ! is_pkg_installed "$cmd"; then
        echo -e "${OPTION}${BOLD} [✓] $name removed successfully${RST}"
        log UNINSTALL "$name removed successfully"
    else
        echo -e "${ERROR}${BOLD} [x] Could not completely remove $name${RST}"
        log WARN "$name partially removed"
    fi
    
    sleep 1
}

# Uninstall pip packages
uninstall_pip_package() {
    local cmd="$1"
    local name="$2"
    
    log UNINSTALL "Attempting to uninstall pip package: $name"
    
    # Check if installed via pip
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${INFO}${BOLD} [→] $name is not installed - Skipping${RST}"
        return 0
    fi
    
    echo -e "${ERROR}${BOLD}"
    if ! ask_yes_no " Uninstall pip package: $name?"; then
        echo -e "${INFO}${BOLD} [→] Skipping $name${RST}"
        return 0
    fi
    echo -e "${RST}"
    
    echo -e "${INFO}${BOLD} [*] Removing pip package: $name...${RST}"
    
    # Determine pip command
    local pip_cmd="pip3"
    if ! command -v pip3 >/dev/null 2>&1; then
        pip_cmd="pip"
    fi
    
    # Uninstall
    if $pip_cmd uninstall -y "$cmd" 2>/dev/null; then
        echo -e "${OPTION}${BOLD} [✓] $name (pip) removed successfully${RST}"
        log UNINSTALL "pip package $name removed"
    else
        echo -e "${ERROR}${BOLD} [x] Failed to remove $name (pip)${RST}"
        log WARN "Failed to remove pip package $name"
    fi
    
    sleep 1
}
