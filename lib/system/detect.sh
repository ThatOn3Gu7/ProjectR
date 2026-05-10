#!/bin/bash

# -- package manager detection --
detect_pkg_manager() {
  # Android (Termux)
  command -v termux-info >/dev/null 2>&1 && [ -d "~/data/data/com.termux" ] && echo "pkg" && return
  # Linux
  command -v apt >/dev/null 2>&1 && echo "apt" && return
  command -v apt-get >/dev/null 2>&1 && echo "apt-get" && return
  command -v pacman >/dev/null 2>&1 && echo "pacman" && return
  command -v dnf >/dev/null 2>&1 && echo "dnf" && return
  command -v yum >/dev/null 2>&1 && echo "yum" && return
  command -v zypper >/dev/null 2>&1 && echo "zypper" && return
  command -v apk >/dev/null 2>&1 && echo "apk" && return
  command -v emerge >/dev/null 2>&1 && echo "emerge" && return
  command -v xbps-install >/dev/null 2>&1 && echo "xbps" && return
  command -v nix >/dev/null 2>&1 && echo "nix" && return
  command -v guix >/dev/null 2>&1 && echo "guix" && return
  command -v eopkg >/dev/null 2>&1 && echo "eopkg" && return
  command -v urpmi >/dev/null 2>&1 && echo "urpmi" && return
  command -v pkgtool >/dev/null 2>&1 && echo "slackpkg" && return
  command -v portage >/dev/null 2>&1 && echo "portage" && return
  
  # macOS
  command -v brew >/dev/null 2>&1 && echo "brew" && return
  command -v port >/dev/null 2>&1 && echo "macports" && return
  
  # BSD
  command -v pkg >/dev/null 2>&1 && echo "pkg" && return  # FreeBSD
  command -v pkg_add >/dev/null 2>&1 && echo "pkg_add" && return  # OpenBSD
  
  # Windows (WSL/Cygwin/Git Bash)
  command -v winget.exe >/dev/null 2>&1 && echo "winget" && return
  command -v choco.exe >/dev/null 2>&1 && echo "choco" && return
  command -v scoop >/dev/null 2>&1 && echo "scoop" && return
  
  # Language-specific
  command -v npm >/dev/null 2>&1 && echo "npm" && return
  command -v yarn >/dev/null 2>&1 && echo "yarn" && return
  command -v pnpm >/dev/null 2>&1 && echo "pnpm" && return
  command -v bun >/dev/null 2>&1 && echo "bun" && return
  command -v pip >/dev/null 2>&1 && echo "pip" && return
  command -v pip3 >/dev/null 2>&1 && echo "pip3" && return
  command -v pipx >/dev/null 2>&1 && echo "pipx" && return
  command -v gem >/dev/null 2>&1 && echo "gem" && return
  command -v cargo >/dev/null 2>&1 && echo "cargo" && return
  command -v go >/dev/null 2>&1 && echo "go" && return
  command -v composer >/dev/null 2>&1 && echo "composer" && return
  
  # Container/App formats
  command -v flatpak >/dev/null 2>&1 && echo "flatpak" && return
  command -v snap >/dev/null 2>&1 && echo "snap" && return
  command -v appimage >/dev/null 2>&1 && echo "appimage" && return
    echo "unknown"
}
# Detect package manager for a specific tool/context
detect_pkg_for_tool() {
    local tool_type="$1"  # "pip", "npm", "gem", "cargo", "system"
    
    case "$tool_type" in
        pip)
            if command -v pip >/dev/null 2>&1; then
                echo "pip"
            elif command -v pip3 >/dev/null 2>&1; then
                echo "pip3"
            elif command -v pipx >/dev/null 2>&1; then
                echo "pipx"
            else
                echo "none"
            fi
            ;;
        npm)
            if command -v npm >/dev/null 2>&1; then
                echo "npm"
            elif command -v yarn >/dev/null 2>&1; then
                echo "yarn"
            else
                echo "none"
            fi
            ;;
        gem)
            command -v gem >/dev/null 2>&1 && echo "gem" || echo "none"
            ;;
        cargo)
            command -v cargo >/dev/null 2>&1 && echo "cargo" || echo "none"
            ;;
        system)
            # Your existing detect_pkg_manager for system packages
            detect_pkg_manager
            ;;
        *)
            detect_pkg_manager
            ;;
    esac
}
