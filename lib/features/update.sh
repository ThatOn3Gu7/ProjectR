#!/bin/bash
# Updates package list based on detected package manager
pkg_update() {
  log OK "pkg list updated"
   PM="$(detect_pkg_manager)"
    case "$PM" in
        apt)
             apt update -y >/dev/null 2>&1
            ;;
        dnf)
            sudo dnf makecache >/dev/null 2>&1
            ;;
        yum)
            sudo yum makecache >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -Sy --noconfirm
            ;;
        zypper)
            sudo zypper refresh >/dev/null 2>&1
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            ;;
        brew)
            brew update >/dev/null 2>&1
            ;;
        pkg) # Termux
            pkg update -y >/dev/null 2>&1
            ;;
        nix)
            nix-channel --update >/dev/null 2>&1
            ;;
        flatpak)
            flatpak update --appstream >/dev/null 2>&1
            ;;
        snap)
            snap refresh --list >/dev/null 2>&1 || true
            ;;
        winget)
            winget source update >/dev/null 2>&1
            ;;
        scoop)
            scoop update >/dev/null 2>&1
            ;;
        *)
          echo -e "${ERR}${BOLD}"
          boxed_text center " [!] No supported package manager found, So package list not updated"
          echo -e "${RST}"
          stop_spinner
            return 1
            ;;
    esac
}
