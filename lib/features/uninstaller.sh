#!/usr/bin/env bash
# -- detect pkg manager for deletion --
PM="$(detect_pkg_manager)"

# -- the sec uninstall funtion (for pip/pip3) --
uninstall_pip() {
 local pkg=$1
 local name="$2"

  # -- Confirmation --
  # Use if statement directly - NO $(ask ...)
   if ! ask "  [!] Are you sure?" "n" 4; then
      echo -e "${INFO}  [→] Skipping: $name${RST}"
      return 
   fi
 # -- detection --
  if command -v "$pkg" >/dev/null 2>&1; then
    start_spinner "   [*] Removing pkg: $name (pip).."
   else 
    echo -e "${ERR}  [!] Package: $pkg not found (pip) ${RST}"
    sleep 2
    return
  fi
 # -- uninstall --
 if command -v pip3 >/dev/null 2>&1; then
    pip3 uninstall -y "$pkg"
  else
    pip uninstall -y "$pkg"
 fi >/dev/null 2>&1
 # -- stop spinner --
 echo -e "${OPT}"
  stop_spinner "   [✓] Removed $name successfully (pip)"
 echo -e "${RST}"
}

# -- the uninstall funtion (for apt/etc)--
uninstall_pkg() {
 local cmd="$1"
 local pkg="$2"
 local name="$3"

  # -- Confirmation --
  # Use if statement directly - NO $(ask ...)
   if ! ask "  [!] Are you sure?" "n" 4; then
      echo -e "${INFO}  [→] Skipping: $name${RST}"
      return 0
   fi
   # -- detection --
   if command -v "$cmd" >/dev/null 2>&1; then
     start_spinner "   [*] Removing pkg: $name.."
   else
     echo -e "${ERR}  [!] Package: $name not found..${RST}"
     sleep 2
    return
   fi 
   case "$PM" in
     pkg) pkg uninstall -y "$pkg" ;;
     apt) apt remove -y "$pkg" ;;
     *)
       echo -e "${ERR} [!] Unsupported package manager..$PM ${RST}"
       return
       ;;
   esac >/dev/null 2>&1
  echo -e "${OPT}"
   stop_spinner "   [✓] Removed: $name successfully.."
  echo -e "${RST}"
}
