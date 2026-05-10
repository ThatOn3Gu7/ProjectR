#!/usr/bin/env bash
# -- detect pkg manager for deletion --
PM="$(detect_pkg_manager)"

# -- the sec uninstall funtion (for pip/pip3) --
uninstall_lang() {
 local pm=$1 # what Lang-specific pkg manager to use
 local pkg=$2 # pkg name to delete
 local name="$3" # pkg name to display
 

  # -- Confirmation --
  # Use if statement directly - NO $(ask ...)
   if ! ask "  [!] Are you sure? Action cannot be undone!"; then
      echo -e "${INFO}  [→] Skipping: $name ${RST}"
      return 
   fi
 # -- detection --
  if command -v "$pkg" >/dev/null 2>&1; then
    start_spinner "   [*] Removing pkg: $name (via $pm).."
   else 
    echo -e "${ERROR}  [!] Package: $name not found (on $pm) ${RST}"
    sleep 2
    return
  fi
 # -- uninstall --
 case "$pm" in
     # Language-specific (global packages)
    npm)
        npm uninstall -g "$pkg"
        ;;
    yarn)
        yarn global remove "$pkg"
        ;;
    pnpm)
        pnpm remove -g "$pkg"
        ;;
    bun)
        bun remove -g "$pkg"
        ;;
    pip)
        pip uninstall -y "$pkg"
        ;;
    pip3)
        pip3 uninstall -y "$pkg"
        ;;
    pipx)
        pipx uninstall "$pkg"
        ;;
    gem)
        gem uninstall "$pkg" -x
        ;;
    cargo)
        cargo uninstall "$pkg"
        ;;
    go)
        go clean -i "$pkg" && rm -rf "$(go env GOPATH)/bin/$pkg"
        ;;
    composer)
        composer global remove "$pkg"
        ;;
       *)
       echo -e "${ERROR} [!] Unsupported language package manager..$pm ${RST}"
       return
       ;;
   esac >/dev/null 2>&1
 # -- stop spinner --
 echo -e "${OPTION}"
  stop_spinner "   [✓] Removed: $name successfully (via $pm)"
 echo -e "${RST}"
}

# -- the uninstall funtion (for apt/etc)--
uninstall_pkg() {
 local cmd="$1"
 local pkg="$2"
 local name="$3"

  # -- Confirmation --
   if ! ask "  [!] Are you sure? Action cannot be undone!"; then
      echo -e "${INFO}  [→] Skipping: $name${RST}"
      return 0
   fi
   # -- detection --
   if command -v "$cmd" >/dev/null 2>&1; then
     start_spinner "   [*] Removing pkg: $name (via $PM).."
   else
     echo -e "${ERROR}  [!] Package: $name not found (on $PM)..${RST}"
     sleep 2
    return
   fi 
   case "$PM" in
    # Android/Termux
    pkg)
        pkg uninstall "$pkg"
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
        nix remove "$pkg" && nix-collect-garbage -d
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
    pkg)
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
  echo -e "${OPTION}"
  stop_spinner "   [✓] Removed: $name successfully (via $PM).."
  echo -e "${RST}"
}
