#!/usr/bin/env bash
source $HOME/ProjectR/lib/detect.sh
source $HOME/ProjectR/lib/utils.sh

# ===============================
# DETECT PACKAGE MANAGER
# ===============================
# detect_pm() {
#   if command -v pkg >/dev/null 2>&1; then
#     PM="pkg"
#   elif command -v apt >/dev/null 2>&1; then
#     PM="apt"
#   else
#     PM="unknown"
#   fi
# }
PM="$(detect_pkg_manager)"
# ===============================
# UNINSTALL FUNCTIONS
# ===============================
uninstall_pkg() {
  pkg="$1"
  name="$2"

  start_spinner " [*] Removing pkg: $name.."

  case "$PM" in
    pkg) pkg uninstall -y "$pkg" ;;
    apt) apt remove -y "$pkg" ;;
    *)
      echo -e "${ERROR} [!] Unsupported package manager..${RST}"
      return
      ;;
  esac >/dev/null 2>&1

  stop_spinner " [✓] Removed $name pkg successfully.."
}

uninstall_pip() {
  pkg="$1"
  name="$2"

  start_spinner "Removing $name (pip)"

  if command -v pip3 >/dev/null 2>&1; then
    pip3 uninstall -y "$pkg"
  else
    pip uninstall -y "$pkg"
  fi >/dev/null 2>&1

  stop_spinner
}

# ===============================
# UNINSTALL MENU
# ===============================
uninstall_menu() {
  while true; do
    clear
  cat <<"EOF" | lolcat

              _       _________ _        _______ _________ _______  _        _        _______  _______ 
    |\     /|( (    /|\__   __/( (    /|(  ____ \\__   __/(  ___  )( \      ( \      (  ____ \(  ____ )
    | )   ( ||  \  ( |   ) (   |  \  ( || (    \/   ) (   | (   ) || (      | (      | (    \/| (    )|
    | |   | ||   \ | |   | |   |   \ | || (_____    | |   | (___) || |      | |      | (__    | (____)|
    | |   | || (\ \) |   | |   | (\ \) |(_____  )   | |   |  ___  || |      | |      |  __)   |     __)
    | |   | || | \   |   | |   | | \   |      ) |   | |   | (   ) || |      | |      | (      | (\ (   
    | (___) || )  \  |___) (___| )  \  |/\____) |   | |   | )   ( || (____/\| (____/\| (____/\| ) \ \__
    (_______)|/    )_)\_______/|/    )_)\_______)   )_(   |/     \|(_______/(_______/(_______/|/   \__/
                                                                                                   

EOF

    echo "  [1] Git"
    echo "  [2] Curl"
    echo "  [3] Wget"
    echo "  [4] Bat"
    echo "  [5] Htop"
    echo "  [6] Fish"
    echo "  [7] OpenSSH"
    echo "  [8] Neovim"
    echo "  [9] Nmap"

    echo ""
    echo "  [20] Holehe (pip)"
    echo "  [21] Asciiquarium (pip)"
    echo "  [22] Wttr (pip)"

    echo ""
    echo "  [0] Back"
    echo ""

    read -p "Select numbers (space separated): " -a choices

    for choice in "${choices[@]}"; do
      case "$choice" in
        1) uninstall_pkg git "Git" ;;
        2) uninstall_pkg curl "Curl" ;;
        3) uninstall_pkg wget "Wget" ;;
        4) uninstall_pkg bat "Bat" ;;
        5) uninstall_pkg htop "Htop" ;;
        6) uninstall_pkg fish "Fish" ;;
        7) uninstall_pkg openssh "OpenSSH" ;;
        8) uninstall_pkg neovim "Neovim" ;;
        9) uninstall_pkg nmap "Nmap" ;;

        20) uninstall_pip holehe "Holehe" ;;
        21) uninstall_pip asciiquarium "Asciiquarium" ;;
        22) uninstall_pip wttr "Wttr" ;;

        0) return ;;
        *) echo -e "$WARN Invalid option: $choice$RST" ;;
      esac
    done

    echo ""
    read -p "Press Enter to continue..."
  done
}
