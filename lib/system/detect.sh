#!/bin/bash

# -- package manager detection --
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
