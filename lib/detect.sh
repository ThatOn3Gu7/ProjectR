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
        echo -e "${ERROR}${BOLD}"
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
          echo -e "${ERROR}${BOLD}"
           boxed_text center " [!] Could not determine if pkg is already installed.."
          echo -e "${RST}"
          sleep 3
            return 1
            ;;
    esac
}


# Function to ensure pip packages are installed
# Usage: ensure_pip_package <package_name> [pip_package_name]
install_pip_package() {
    local command_name="$1"
    local package_name="${2:-$1}"  # Use second arg if provided, otherwise use command name
    local install_cmd=""

    # For internet Check-up before continue
    if ! check_internet; then
     echo -e "${ERROR}${BOLD}"
      boxed_text center "        It seems that you are not onlile
Please make sure to turn on WI-FI to continue ;)"
      echo -e "${RST}"
      log FAIL "$package_name not installed (no internet)"
      exit 0
    fi
    # Determine which pip to use
    if command -v pip3 &> /dev/null; then
        install_cmd="pip3"
    elif command -v pip &> /dev/null; then
        install_cmd="pip"
    else
        echo -e "${ERROR}${BOLD}"
        boxed_text center "[x] ERROR: Neither pip nor pip3 is available.."
        echo -e "${RST}"
        sleep 3
        return 1
    fi
    
    # Check if command already exists
    if command -v "$command_name" &> /dev/null; then
        echo -e "${OPTION}${BOLD} [✓] $package_name is already installed - Skipping ${RST}"
        log SKIPPED "$package_name was already installed (Skipped)"
        sleep 3
        return 0
    fi
    
    # Install the package
    echo -e "${OPTION}${BOLD} [*] Installing: $package_name...${RST}"
    if ! $install_cmd install --quiet "$command_name"; then
        echo -e "${ERROR}${BOLD} [x] ERROR: Failed to install $package_name..${RST}" >&2
        log FAIL "$package_name failed to installed"
        sleep 3
        return 1
    fi
    # Verify installation
    if command -v "$command_name" &> /dev/null; then
        echo -e "${OPTION}${BOLD} [✓] Successfully installed $package_name..${RST}"
        log INSTALLED "$package_name successfully installed"
        sleep 3
        return 0
    else
        echo -e "${ERROR} [!] WARNING: $package_name installed but '$command_name' command not found..${RST}" >&2
        sleep 3
        return 0  # Still return success as package was installed
    fi
}





