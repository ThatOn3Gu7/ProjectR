#!/bin/bash
# Upgrades system based on detected package manager.
pkg_upgrade() {
  log OK "pkg/system upgraded"
   PM="$(detect_pkg_manager)"
    case "$PM" in
        apt)  apt upgrade -y >/dev/null 2>&1 ;;
        dnf) sudo dnf upgrade -y >/dev/null 2>&1 ;;
        yum) sudo yum upgrade -y >/dev/null 2>&1 ;;
        pacman) pacman -Su --noconfirm ;;
        brew) brew upgrade >/dev/null 2>&1 ;;
        pkg) pkg upgrade -y >/dev/null 2>&1 ;;
        *)
          echo -e "${ERR}${BOLD}"
          boxed_text center "[!] System upgrade not supported for: $PM..${RST}"
          echo -e "${RST}"
            return 1
            ;;
    esac
}

