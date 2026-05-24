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
    pip)
        pip uninstall -y "$pkg" >/dev/null 2>&1
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
        cargo uninstall "$pkg"
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
        pkg uninstall -y "$pkg"
        ;;
    # Linux
    apt|apt-get)
        apt purge -y "$pkg" 2>/dev/null || apt-get purge -y "$pkg"
        ;;
    pacman)
        sudo pacman -Rns --noconfirm "$pkg"
        ;;
    dnf)
        sudo dnf remove -y "$pkg"
        ;;
    yum)
        sudo yum remove -y "$pkg"
        ;;
    zypper)
        sudo zypper remove -y "$pkg"
        ;;
    apk)
        sudo apk del "$pkg"
        ;;
    emerge)
        sudo emerge --unmerge "$pkg"
        ;;
    xbps)
        sudo xbps-remove -R "$pkg"
        ;;
    nix)
        nix-env --uninstall "$pkg" && nix-collect-garbage -d >/dev/null 2>&1
        ;;
    guix)
        guix package --remove="$pkg"
        ;;
    eopkg)
        sudo eopkg remove "$pkg"
        ;;
    urpmi)
        sudo urpme "$pkg"
        ;;
    slackpkg)
        sudo slackpkg remove "$pkg"
        ;;
    portage)
        sudo emerge --depclean "$pkg"
        ;;
    # macOS
    brew)
        brew uninstall --force "$pkg"
        ;;
    macports)
        sudo port uninstall "$pkg"
        ;;
    # BSD
    BSD-pkg)
        sudo pkg delete -y "$pkg"
        ;;
    pkg_add)
        doas pkg_delete "$pkg"
        ;;
    # Windows
    winget)
        winget uninstall --silent --accept-package-agreements "$pkg"
        ;;
    choco)
        choco uninstall -y "$pkg"
        ;;
    scoop)
        scoop uninstall "$pkg"
        ;;
    # Container/App formats
    flatpak)
        flatpak uninstall -y "$pkg"
        ;;
    snap)
        sudo snap remove "$pkg"
        ;;
    appimage)
        echo -e "${OPTION} [*] AppImages have no package manager. Delete the .AppImage file manually. ${RST}"
        echo -e "${OPTION} [*] Try: rm ~/Applications/${pkg}.AppImage ${RST}"
        ;;
     *)
       echo -e "${ERROR} [!] Unsupported package manager..$PM ${RST}"
       return
       ;;
   esac >/dev/null 2>&1
  stop_spinner "${OPTION}  [✓] Removed: "$name" successfully (via $PM)..${RST}"
}
