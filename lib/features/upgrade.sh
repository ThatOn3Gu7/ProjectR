#!/bin/bash
# Upgrades system based on detected package manager.
pkg_upgrade() {
  log OK "pkg/system upgraded"
   PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    case "$PM" in
        apt) sudo apt-get upgrade -y >/dev/null 2>&1 ;;
        dnf) sudo dnf upgrade -y >/dev/null 2>&1 ;;
        yum) sudo yum upgrade -y >/dev/null 2>&1 ;;
        pacman) sudo pacman -Su --noconfirm ;;
        brew) brew upgrade >/dev/null 2>&1 ;;
        pkg) pkg upgrade -y >/dev/null 2>&1 ;;
        *)
          echo -e "${ERROR}"
          print_box center "[!] System upgrade not supported for: $PM..${RST}"
          echo -e "${RST}"
            return 1
            ;;
    esac
}

