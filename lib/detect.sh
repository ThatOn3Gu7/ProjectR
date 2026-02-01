#!/bin/bash
# Checkes if internet connection is available or not. 
check_internet() {
  ping -c 1 8.8.8.8 >/dev/null 2>&1
}
# This scripts work is to detect which package manager a destro is running on.
# And use detected package manager to exclude the install commands.
detect_pkg_manager() {
    # Check for common package managers
    # Return the first available package manager
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v emerge >/dev/null 2>&1; then
        echo "emerge"
    elif command -v nix-env >/dev/null 2>&1; then
        echo "nix"
    elif command -v flatpak >/dev/null 2>&1; then
        echo "flatpak"
    elif command -v snap >/dev/null 2>&1; then
        echo "snap"
    elif command -v pkg >/dev/null 2>&1; then
        echo "pkg"
    elif command -v winget >/dev/null 2>&1; then
        echo "winget"
    elif command -v scoop >/dev/null 2>&1; then
        echo "scoop"
    else
        echo -e "${ERR}${BOLD}"
        boxed_text center "[x] No reqired package maneger found.."
        echo -e "${RST}"
        return 1
    fi
}

# Check if the package is already installed (cross-platform)
is_pkg_installed() {
    local pkg="$1"
    # local PM="$(detect_pkg_manager)"

    case "$PM" in
        apt)
            dpkg -s "$pkg" >/dev/null 2>&1
            ;;
        dnf|yum|zypper)
            rpm -q "$pkg" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "$pkg" >/dev/null 2>&1
            ;;
        apk)
            apk info -e "$pkg" >/dev/null 2>&1
            ;;
        brew)
            brew list --formula "$pkg" >/dev/null 2>&1
            ;;
        emerge)
            equery list "$pkg" >/dev/null 2>&1
            ;;
        nix)
            nix-env -q "$pkg" >/dev/null 2>&1
            ;;
        flatpak)
            flatpak info "$pkg" >/dev/null 2>&1
            ;;
        snap)
            snap list "$pkg" >/dev/null 2>&1
            ;;
        pkg) # Termux
            dpkg -s "$pkg" >/dev/null 2>&1
            ;;
        winget)
            winget list --id "$pkg" >/dev/null 2>&1
            ;;
        scoop)
            scoop list "$pkg" >/dev/null 2>&1
            ;;
        *)
          echo -e "${ERR}${BOLD}"
           boxed_text center " [!] Could not determine if pkg is already installed.."
          echo -e "${RST}"
          sleep 3
            return 1
            ;;
    esac
}

