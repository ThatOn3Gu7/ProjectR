#!/bin/bash
# Updates package list based on detected package manager
pkg_update() {
  log START "pkg list update"
   PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    case "$PM" in
        apt)
          if ! sudo apt-get update >/dev/null 2>&1; then
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
        *)
          echo -e "${ERROR}"
          print_box center " [!] No supported package manager found, So package list not updated"
          echo -e "${RST}"
          stop_spinner ""
            return 1
            ;;
    esac
}
