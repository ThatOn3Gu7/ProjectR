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

# Updates package list based on detected package manager
pkg_update() {
  log START "pkg list update"
   PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    case "$PM" in
        apt)
          if ! sudo apt update >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        dnf)
           if ! sudo dnf makecache >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
           fi
            ;;
        yum)
          if ! sudo yum makecache >/dev/null 2>&1; then
           echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        pacman)
             if ! sudo pacman -Sy --noconfirm; then
              echo -e "${ERROR}  [!] Failed to update package list${RST}"
             fi
            ;;
        zypper)
             if ! sudo zypper refresh >/dev/null 2>&1; then
              echo -e "${ERROR}  [!] Failed to update package list${RST}"
             fi
            ;;
        apk)
          if ! sudo apk update >/dev/null 2>&1; then
           echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        brew)
           if ! brew update >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
           fi
            ;;
    pkg) # Termux
             if ! pkg update >/dev/null 2>&1; then
              echo -e "${ERROR}  [!] Failed to update package list${RST}"
             fi
            ;;
        nix)
          if ! nix-channel --update >/dev/null 2>&1; then
           echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
     flatpak)
           if ! flatpak update --appstream >/dev/null 2>&1; then
             echo -e "${ERROR}  [!] Failed to update package list${RST}"
           fi
            ;;
        snap)
           if ! snap refresh --list >/dev/null 2>&1 || true; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
           fi
            ;;
        winget)
            if ! winget source update >/dev/null 2>&1; then
             echo -e "${ERROR}  [!] Failed to update package list${RST}"
            fi
            ;;
        scoop)
            if ! scoop update >/dev/null 2>&1; then
             echo -e "${ERROR}  [!] Failed to update package list${RST}"
            fi
            ;;
        apt-get)
          if ! sudo apt-get update >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        emerge)
          if ! sudo emerge --sync >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        xbps)
          if ! sudo xbps-install -S >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        guix)
          if ! guix pull >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        eopkg)
          if ! sudo eopkg update-repo >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        urpmi)
          if ! sudo urpmi.update -a >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        slackpkg)
          if ! sudo slackpkg update >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        macports)
          if ! sudo port selfupdate >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        bsd-pkg)
          if ! sudo pkg update >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        pkg_add)
          if ! doas pkg_add -u >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        choco)
          if ! choco outdated >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] Failed to update package list${RST}"
          fi
            ;;
        *)
          echo -e "${ERROR}"
          print_box center " [!] No supported package manager found, So package list not updated"
          echo -e "${RST}"
          stop_spinner ""
            return 1
            ;;
    esac
}
