#!/bin/bash
pkg_update() {
    log START "pkg list update started"
    local PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    local max_attempts=3
    local attempt=1
    local success=0

    while (( attempt <= max_attempts )); do
        if (( attempt > 1 )); then
            echo -e "${BOLD_YELLOW}  [!] Retry $attempt/$max_attempts (waiting $((attempt * 2))s)...${RST}"
            sleep $(( attempt * 2 ))
        fi

        case "$PM" in
            apt)     sudo apt-get update >/dev/null 2>&1           && success=1 ;;
            dnf)     sudo dnf makecache >/dev/null 2>&1            && success=1 ;;
            yum)     sudo yum makecache >/dev/null 2>&1            && success=1 ;;
            pacman)  sudo pacman -Sy --noconfirm                   && success=1 ;;
            zypper)  sudo zypper refresh >/dev/null 2>&1           && success=1 ;;
            apk)     sudo apk update >/dev/null 2>&1               && success=1 ;;
            brew)    brew update >/dev/null 2>&1                   && success=1 ;;
            pkg)     pkg update >/dev/null 2>&1                    && success=1 ;;
            nix)     nix-channel --update >/dev/null 2>&1          && success=1 ;;
            flatpak) flatpak update --appstream >/dev/null 2>&1    && success=1 ;;
            snap)    snap refresh --list >/dev/null 2>&1           && success=1 ;;
            winget)  winget source update >/dev/null 2>&1          && success=1 ;;
            scoop)   scoop update >/dev/null 2>&1                  && success=1 ;;
            *)
                echo -e "${ERROR}"
                print_box center " [!] No supported package manager found — skipping update"
                echo -e "${RST}"
                stop_spinner ""
                return 1
                ;;
        esac

        [[ $success -eq 1 ]] && break
        ((attempt++))
    done

    if [[ $success -eq 0 ]]; then
        echo -e "${ERROR}  [!] Failed to update package list after $max_attempts attempts (via $PM)${RST}"
        log FAIL "pkg_update failed after $max_attempts attempts on $PM"
        return 1
    fi

    log OK "pkg list updated successfully via $PM"
}
# Upgrades system based on detected package manager.
pkg_upgrade() {
    log OK "pkg/system upgrade started"
    local PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    local exit_code=0

    case "$PM" in
        apt)     sudo apt-get upgrade -y >/dev/null 2>&1;          exit_code=$? ;;
        dnf)     sudo dnf upgrade -y >/dev/null 2>&1;              exit_code=$? ;;
        yum)     sudo yum upgrade -y >/dev/null 2>&1;              exit_code=$? ;;
        pacman)  sudo pacman -Su --noconfirm;                      exit_code=$? ;;
        brew)    brew upgrade >/dev/null 2>&1;                     exit_code=$? ;;
        pkg)     pkg upgrade -y >/dev/null 2>&1;                   exit_code=$? ;;
        zypper)  sudo zypper update -y >/dev/null 2>&1;            exit_code=$? ;;
        apk)     sudo apk upgrade >/dev/null 2>&1;                 exit_code=$? ;;
        nix)     nix-env -u '*' >/dev/null 2>&1;                   exit_code=$? ;;
        flatpak) flatpak update -y >/dev/null 2>&1;                exit_code=$? ;;
        snap)    sudo snap refresh >/dev/null 2>&1;                exit_code=$? ;;
        winget)  winget upgrade --all --silent >/dev/null 2>&1;    exit_code=$? ;;
        *)
            echo -e "${ERROR}"
            print_box center "[!] System upgrade not supported for: $PM"
            echo -e "${RST}"
            return 1
            ;;
    esac

    if [[ $exit_code -ne 0 ]]; then
        echo -e "${ERROR}  [!] Upgrade failed for: $PM (exit: $exit_code)${RST}"
        log FAIL "pkg_upgrade failed on $PM with exit code $exit_code"
        return 1
    fi

    log OK "pkg/system upgraded successfully via $PM"
}
