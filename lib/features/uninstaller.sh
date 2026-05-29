#!/usr/bin/env bash

# -- the uninstall function (for pip/npm/gem/etc) --
uninstall_lang() {
    local pm="$1"
    local pkg="$2"
    local name="$3"

    if [[ -z "$pm" || -z "$pkg" || -z "$name" ]]; then
        echo -e "${ERROR}  [!] uninstall_lang: missing arguments.${RST}"
        return 1
    fi

    if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
        if ! ask "  [?] Remove $name? (can be reinstalled later)" "n"; then
            echo -e "${INFO}  [→] Skipping: $name${RST}"
            return 0
        fi
    fi

    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] Package: $name not found (via $pm)${RST}"
        sleep 2
        return 1
    fi

    start_spinner "   [*] Removing: $name (via $pm).."

    case "$pm" in
        npm)           npm uninstall -g "$pkg" >/dev/null 2>&1 ;;
        yarn)          yarn global remove "$pkg" >/dev/null 2>&1 ;;
        pnpm)          pnpm remove -g "$pkg" >/dev/null 2>&1 ;;
        bun)           bun remove -g "$pkg" >/dev/null 2>&1 ;;
        pip|pip3|pipx) $pm uninstall -y "$pkg" >/dev/null 2>&1 ;;
        gem)           gem uninstall "$pkg" -x >/dev/null 2>&1 ;;
        cargo)         cargo uninstall "$pkg" >/dev/null 2>&1 ;;
        go)            go clean -i "$pkg" >/dev/null 2>&1 && rm -rf "$(go env GOPATH)/bin/$pkg" 2>/dev/null ;;
        composer)      composer global remove "$pkg" >/dev/null 2>&1 ;;
        *)
            stop_spinner
            echo -e "${ERROR} [!] Unsupported language package manager: $pm${RST}"
            return 1
            ;;
    esac

    local exit_code=$?

    # Post-removal verification
    if command -v "$pkg" >/dev/null 2>&1; then
        stop_spinner "${ERROR}  [!] $name still found after removal — may need manual cleanup.${RST}"
        log FAIL "$name (lang): binary still present after $pm removal"
        return 1
    fi

    if [[ $exit_code -eq 0 ]]; then
        stop_spinner "${OPTION}  [✓] Removed: $name successfully (via $pm)${RST}"
        log OK "$name removed successfully via $pm"
    else
        stop_spinner "${ERROR}  [!] $name removal reported errors (exit: $exit_code).${RST}"
        log FAIL "$name uninstall exited $exit_code on $pm"
        return 1
    fi
}
# -- the uninstall function (for apt/etc) --
uninstall_pkg() {
    local cmd="$1"
    local pkg="$2"
    local name="$3"
    local PM
    PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

    if [[ -z "$cmd" || -z "$pkg" || -z "$name" ]]; then
        echo -e "${ERROR}  [!] uninstall_pkg: missing arguments.${RST}"
        return 1
    fi

    if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
        if ! ask "  [?] Remove $name? (can be reinstalled later)" "n"; then
            echo -e "${INFO}  [→] Skipping: $name${RST}"
            return 0
        fi
    fi

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] Package: $name not found (on $PM)..${RST}"
        sleep 2
        return 1
    fi

    start_spinner "   [*] Removing pkg: $name (via $PM).."

    case "$PM" in
        pkg)         pkg uninstall -y "$pkg" >/dev/null 2>&1 ;;
        apt|apt-get) sudo apt purge -y "$pkg" >/dev/null 2>&1 || sudo apt-get purge -y "$pkg" >/dev/null 2>&1 ;;
        pacman)      sudo pacman -Rns --noconfirm "$pkg" >/dev/null 2>&1 ;;
        dnf)         sudo dnf remove -y "$pkg" >/dev/null 2>&1 ;;
        yum)         sudo yum remove -y "$pkg" >/dev/null 2>&1 ;;
        zypper)      sudo zypper remove -y "$pkg" >/dev/null 2>&1 ;;
        apk)         sudo apk del "$pkg" >/dev/null 2>&1 ;;
        emerge)      sudo emerge --unmerge "$pkg" >/dev/null 2>&1 ;;
        xbps)        sudo xbps-remove -R "$pkg" >/dev/null 2>&1 ;;
        nix)         nix-env --uninstall "$pkg" >/dev/null 2>&1 && nix-collect-garbage -d >/dev/null 2>&1 ;;
        guix)        guix package --remove="$pkg" >/dev/null 2>&1 ;;
        eopkg)       sudo eopkg remove "$pkg" >/dev/null 2>&1 ;;
        urpmi)       sudo urpme "$pkg" >/dev/null 2>&1 ;;
        slackpkg)    sudo slackpkg remove "$pkg" >/dev/null 2>&1 ;;
        portage)     sudo emerge --depclean "$pkg" >/dev/null 2>&1 ;;
        brew)        brew uninstall --force "$pkg" >/dev/null 2>&1 ;;
        macports)    sudo port uninstall "$pkg" >/dev/null 2>&1 ;;
        BSD-pkg)     sudo pkg delete -y "$pkg" >/dev/null 2>&1 ;;
        pkg_add)     doas pkg_delete "$pkg" >/dev/null 2>&1 ;;
        winget)      winget uninstall --silent --accept-package-agreements "$pkg" >/dev/null 2>&1 ;;
        choco)       choco uninstall -y "$pkg" >/dev/null 2>&1 ;;
        scoop)       scoop uninstall "$pkg" >/dev/null 2>&1 ;;
        flatpak)     flatpak uninstall -y "$pkg" >/dev/null 2>&1 ;;
        snap)        sudo snap remove "$pkg" >/dev/null 2>&1 ;;
        appimage)
            stop_spinner
            echo -e "${OPTION} [*] AppImages must be deleted manually.${RST}"
            echo -e "${OPTION} [*] Try: rm ~/Applications/${pkg}.AppImage${RST}"
            return 0
            ;;
        *)
            stop_spinner
            echo -e "${ERROR} [!] Unsupported package manager: $PM${RST}"
            return 1
            ;;
    esac

    local exit_code=$?

    # Post-removal verification: binary should be gone now
    if command -v "$cmd" >/dev/null 2>&1; then
        stop_spinner "${ERROR}  [!] $name still present after removal — may need manual cleanup.${RST}"
        log FAIL "$name: binary still present after $PM removal"
        return 1
    fi

    if [[ $exit_code -eq 0 ]]; then
        stop_spinner "${OPTION}  [✓] Removed: $name successfully (via $PM).${RST}"
        log OK "$name removed successfully via $PM"
    else
        stop_spinner "${ERROR}  [!] $name removal reported errors (exit: $exit_code).${RST}"
        log FAIL "$name uninstall exited $exit_code on $PM"
        return 1
    fi
}
