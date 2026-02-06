#!/bin/bash
# Add to detect.sh or create new file: lib/system/packages_map.sh

declare -A PKG_MAP

# Initialize package mapping based on detected package manager
init_pkg_map() {
    local PM="$1"
    
    # Clear any existing map
    PKG_MAP=()
    
    case "$PM" in
        apt|pkg)  # Debian/Ubuntu/Termux
            PKG_MAP=(
                [git]="git"
                [python3]="python3"
                [python]="python3"  # Alias
                [node]="nodejs"
                [npm]="nodejs"
                [nvim]="neovim"
                [neovim]="neovim"
                [vim]="vim"
                [zsh]="zsh"
                [fish]="fish"
                [tmux]="tmux"
                [htop]="htop"
                [curl]="curl"
                [wget]="wget"
                [bat]="bat"
                [ssh]="openssh-client"
                [sl]="sl"
                [cacademo]="libcaca"
                [cacafire]="libcaca"
                [tty-clock]="tty-clock"
                [pipes.sh]="pipes.sh"
                [speedtest-go]="speedtest-go"
                [cpufetch]="cpufetch"
                [neofetch]="neofetch"
                [ranger]="ranger"
                [ncdu]="ncdu"
                [cbonsai]="cbonsai"
                [asciinema]="asciinema"
                [croc]="croc"
                [fzf]="fzf"
                [zoxide]="zoxide"
                [duf]="duf"
                [yazi]="yazi"
                [lsd]="lsd"
                [broot]="broot"
                [dust]="dust"
                [procs]="procs"
                [tldr]="tldr"
                [gh]="gh"
                [lazygit]="lazygit"
            )
            ;;
        pacman)  # Arch/Manjaro
            PKG_MAP=(
                [git]="git"
                [python3]="python"
                [python]="python"
                [node]="nodejs"
                [npm]="nodejs"
                [nvim]="neovim"
                [neovim]="neovim"
                [ssh]="openssh"
                [cacademo]="libcaca"
                # Arch specific names...
            )
            ;;
        dnf|yum)  # Fedora/RHEL/CentOS
            PKG_MAP=(
                [git]="git"
                [python3]="python3"
                [python]="python3"
                [node]="nodejs"
                [npm]="nodejs"
                [nvim]="neovim"
                [neovim]="neovim"
                # Fedora specific names...
            )
            ;;
        brew)  # macOS
            PKG_MAP=(
                [git]="git"
                [python3]="python"
                [python]="python"
                [node]="node"
                [npm]="node"
                [nvim]="neovim"
                [neovim]="neovim"
                # Homebrew specific names...
            )
            ;;
        *)
            # Default fallback (use command name as package name)
            PKG_MAP=()
            ;;
    esac
}

# Get package name for a command
get_package_name() {
    local cmd="$1"
    
    # If mapping exists, use it
    if [ -n "${PKG_MAP[$cmd]}" ]; then
        echo "${PKG_MAP[$cmd]}"
        return 0
    fi
    
    # Fallback: use command name as package name
    echo "$cmd"
    return 1
}
