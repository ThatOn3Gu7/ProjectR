#!/usr/bin/env bash

# -- the sec uninstall funtion (for pip/pip3) --
uninstall_lang() {
 local pm=$1 # what Lang-specific pkg manager to use
 local pkg=$2 # pkg name to delete
 local name="$3" # pkg name to display
 
  # -- Confirmation --
  if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    if ! ask "  [!] Are you sure? Action cannot be undone!"; then
        echo -e "${INFO}  [→] Skipping: "$name"${RST}"
        return 0
    fi
  fi
 # -- detection --
  if command -v "$pkg" >/dev/null 2>&1; then
    start_spinner "   [*] Removing pkg: "$name" (via $pm).."
   else 
    echo -e "${ERROR}  [!] Package: "$name" not found (on $pm) ${RST}"
    sleep 2
    return
  fi
 # -- uninstall --
 case "$pm" in
     # Language-specific (global packages)
    npm)
        npm uninstall -g "$pkg" >/dev/null 2>&1
        ;;
    yarn)
        yarn global remove "$pkg" >/dev/null 2>&1
        ;;
    pnpm)
        pnpm remove -g "$pkg" >/dev/null 2>&1
        ;;
    bun)
        bun remove -g "$pkg" >/dev/null 2>&1
        ;;
    pip|pip3|pipx)
        $pm uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    pip3)
        pip3 uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    pipx)
        pipx uninstall "$pkg" >/dev/null 2>&1
        ;;
    gem)
        gem uninstall "$pkg" -x >/dev/null 2>&1
        ;;
    cargo)
        cargo uninstall "$pkg" >/dev/null 2>&1
        ;;
    go)
        go clean -i "$pkg" && rm -rf "$(go env GOPATH)/bin/$pkg" >/dev/null 2>&1
        ;;
    composer)
        composer global remove "$pkg" >/dev/null 2>&1
        ;;
       *)
       echo -e "${ERROR} [!] Unsupported language package manager..$pm ${RST}"
       return
       ;;
   esac
 # -- stop spinner --
 echo -e "${OPTION}"
  stop_spinner "   [✓] Removed: "$name" successfully (via $pm)"
 echo -e "${RST}"
}

# -- the uninstall funtion (for apt/etc)--
uninstall_pkg() {
 local cmd="$1"
 local pkg="$2"
 local name="$3"
 # -- detect pkg manager for deletion --
 local PM
 PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

  # -- Confirmation --
  if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    if ! ask "  [!] Are you sure? Action cannot be undone!"; then
        echo -e "${INFO}  [→] Skipping: "$name"${RST}"
        return 0
    fi
  fi
   # -- detection --
   if command -v "$cmd" >/dev/null 2>&1; then
     start_spinner "   [*] Removing pkg: "$name" (via $PM).."
   else
     echo -e "${ERROR}  [!] Package: "$name" not found (on $PM)..${RST}"
     sleep 2
    return
   fi 
   case "$PM" in
    # Android/Termux
    pkg)
        pkg uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    # Linux
    apt|apt-get)
       sudo apt purge -y "$pkg" 2>/dev/null || sudo apt-get purge -y "$pkg" >/dev/null 2>&1
        ;;
    pacman)
        sudo pacman -Rns --noconfirm "$pkg" >/dev/null 2>&1
        ;;
    dnf)
        sudo dnf remove -y "$pkg" >/dev/null 2>&1
        ;;
    yum)
        sudo yum remove -y "$pkg" >/dev/null 2>&1
        ;;
    zypper)
        sudo zypper remove -y "$pkg" >/dev/null 2>&1
        ;;
    apk)
        sudo apk del "$pkg" >/dev/null 2>&1
        ;;
    emerge)
        sudo emerge --unmerge "$pkg" >/dev/null 2>&1
        ;;
    xbps)
        sudo xbps-remove -R "$pkg" >/dev/null 2>&1
        ;;
    nix)
        nix-env --uninstall "$pkg" >/dev/null 2>&1 && nix-collect-garbage -d  >/dev/null 2>&1
        ;;
    guix)
        guix package --remove="$pkg" >/dev/null 2>&1
        ;;
    eopkg)
        sudo eopkg remove "$pkg" >/dev/null 2>&1
        ;;
    urpmi)
        sudo urpme "$pkg" >/dev/null 2>&1
        ;;
    slackpkg)
        sudo slackpkg remove "$pkg" >/dev/null 2>&1
        ;;
    portage)
        sudo emerge --depclean "$pkg" >/dev/null 2>&1
        ;;
    # macOS
    brew)
        brew uninstall --force "$pkg" >/dev/null 2>&1
        ;;
    macports)
        sudo port uninstall "$pkg" >/dev/null 2>&1
        ;;
    # BSD
    BSD-pkg)
        sudo pkg delete -y "$pkg" >/dev/null 2>&1
        ;;
    pkg_add)
        doas pkg_delete "$pkg" >/dev/null 2>&1
        ;;
    # Windows
    winget)
        winget uninstall --silent --accept-package-agreements "$pkg" >/dev/null 2>&1
        ;;
    choco)
        choco uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    scoop)
        scoop uninstall "$pkg" >/dev/null 2>&1
        ;;
    # Container/App formats
    flatpak)
        flatpak uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    snap)
        sudo snap remove "$pkg" >/dev/null 2>&1
        ;;
    appimage)
        echo -e "${OPTION} [*] AppImages have no package manager. Delete the .AppImage file manually. ${RST}"
        echo -e "${OPTION} [*] Try: rm ~/Applications/${pkg}.AppImage ${RST}"
        ;;
     *)
       echo -e "${ERROR} [!] Unsupported package manager..$PM ${RST}"
       return
       ;;
   esac
  stop_spinner "${OPTION}  [✓] Removed: "$name" successfully (via $PM)..${RST}"
}
