#!/bin/bash
# Upgrades system based on detected package manager.
pkg_upgrade() {
  log OK "pkg/system upgraded"
   PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    case "$PM" in
        apt) sudo apt upgrade -y >/dev/null 2>&1 ;;
        dnf) sudo dnf upgrade -y >/dev/null 2>&1 ;;
        yum) sudo yum upgrade -y >/dev/null 2>&1 ;;
        pacman) sudo pacman -Su --noconfirm ;;
        brew) brew upgrade >/dev/null 2>&1 ;;
        pkg) pkg upgrade -y >/dev/null 2>&1 ;;
        apt-get) sudo apt-get upgrade -y >/dev/null 2>&1 ;;
        zypper)  sudo zypper update -y >/dev/null 2>&1 ;;
        apk)     sudo apk upgrade >/dev/null 2>&1 ;;
        emerge)  sudo emerge -uDN @world >/dev/null 2>&1 ;;
        xbps)    sudo xbps-install -Su >/dev/null 2>&1 ;;
        nix)     nix-env -u >/dev/null 2>&1 ;;
        guix)    guix upgrade >/dev/null 2>&1 ;;
        eopkg)   sudo eopkg upgrade -y >/dev/null 2>&1 ;;
        urpmi)   sudo urpmi --auto-update >/dev/null 2>&1 ;;
        slackpkg) sudo slackpkg upgrade-all >/dev/null 2>&1 ;;
        macports) sudo port upgrade outdated >/dev/null 2>&1 ;;
        bsd-pkg) sudo pkg upgrade -y >/dev/null 2>&1 ;;
        pkg_add) doas pkg_add -u >/dev/null 2>&1 ;;
        winget)  winget upgrade --all --silent >/dev/null 2>&1 ;;
        choco)   choco upgrade all -y >/dev/null 2>&1 ;;
        scoop)   scoop update * >/dev/null 2>&1 ;;
        flatpak) flatpak update -y >/dev/null 2>&1 ;;
        snap)    sudo snap refresh >/dev/null 2>&1 ;;
        *)
          echo -e "${ERROR}"
          print_box center "[!] System upgrade not supported for: $PM..${RST}"
          echo -e "${RST}"
            return 1
            ;;
    esac
}

