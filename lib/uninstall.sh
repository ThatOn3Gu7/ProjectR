#!/usr/bin/env bash

# -- source the others --
source $HOME/ProjectR/lib/detect.sh
source $HOME/ProjectR/lib/utils.sh

# -- detect pkg manager for deletion --
PM="$(detect_pkg_manager)"

# -- the uninstall funtion (for apt/etc)--
uninstall_pkg() {
 local pkg="$1"
 local name="$2"
  start_spinner "   [*] Removing pkg: $name.."

  case "$PM" in
    pkg) pkg uninstall -y "$pkg" ;;
    apt) apt remove -y "$pkg" ;;
    *)
      echo -e "${ERR} [!] Unsupported package manager..$PM ${RST}"
      return
      ;;
  esac >/dev/null 2>&1

  stop_spinner "   [✓] Removed: $name successfully.."
}
# -- the sec uninstall funtion (for pip/pip3) --
uninstall_pip() {
 local pkg="$1"
 local name="$2"
  start_spinner "   [*] Removing $name (pip)"

  if command -v pip3 >/dev/null 2>&1; then
    pip3 uninstall -y "$pkg"
  else
    pip uninstall -y "$pkg"
  fi >/dev/null 2>&1

  stop_spinner "   [✓] Removed $name pkg successfully (pip)"
}
# -- uninstaller menu --
uninstall_menu() {
  while true; do
    clear
  cat <<"EOF" | lolcat

  ██████╗ ██████╗ ███╗   ███╗ ██████╗ ██╗   ██╗███████╗    ██╗████████╗
  ██╔══██╗╚════██╗████╗ ████║██╔═══██╗██║   ██║██╔════╝    ██║╚══██╔══╝
  ██████╔╝ █████╔╝██╔████╔██║██║   ██║██║   ██║█████╗ ███╗ ██║   ██║   
  ██╔══██╗ ╚═══██╗██║╚██╔╝██║██║   ██║╚██╗ ██╔╝██╔══╝ ╚══╝ ██║   ██║   
  ██║  ██║██████╔╝██║ ╚═╝ ██║╚██████╔╝ ╚████╔╝ ███████╗    ██║   ██║   
  ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝    ╚═╝   ╚═╝
   [--------------------------------------------------------------]
     > Purpose: Made to remove installed tools/utilities.
     > C0ded by: ThatOn3Gu7
     > V3rsion: 1.0 | 2026-02-01
     > Status: [ Ready to purge packages ]
   [--------------------------------------------------------------]

EOF
 echo -e "   [01] ${OPT} Git${RST}"
 echo -e "   [02] ${OPT} Curl${RST}"
 echo -e "   [03] ${OPT} Wget${RST}"
 echo -e "   [04] ${OPT} Bat${RST}"
 echo -e "   [05] ${OPT} Htop${RST}"
 echo -e "   [06] ${OPT} Fish${RST}"
 echo -e "   [07] ${OPT} OpenSSH${RST}"
 echo -e "   [08] ${OPT} Python${RST}"
 echo -e "   [09] ${OPT} Nmap${RST}"
 echo -e "   [10] ${OPT} Libcaca${RST}"
 echo -e "   [11] ${OPT} Speedtest-go${RST}"
 echo -e "   [12] ${OPT} Cpufetch${RST}"
 echo -e "   [13] ${OPT} Neofetch${RST}"
 echo -e "   [14] ${OPT} Ranger${RST}"
 echo -e "   [15] ${OPT} Nano${RST}"
 echo -e "   [16] ${OPT} Sl${RST}"
 echo -e "   [17] ${OPT} Ncdu${RST}"
 echo -e "   [18] ${OPT} Neovim${RST}"
 echo -e "   [19] ${OPT} Cbonsai${RST}"
 echo -e "   [20] ${OPT} Asciinema${RST}"
 echo -e "   [21] ${OPT} Croc${RST}"
 echo -e "   [22] ${OPT} Fzf${RST}"
 echo -e "   [23] ${OPT} Zoxide${RST}"
 echo -e "   [24] ${OPT} Zsh${RST}"
 echo -e "   [25] ${OPT} Duf${RST}"
 echo -e "   [26] ${OPT} Tty-clock${RST}"
 echo -e "   [27] ${OPT} Pipes.sh${RST}"
 echo -e "   [28] ${OPT} Yazi${RST}"
 echo -e "   [29] ${OPT} Lsd${RST}"
 echo -e "   [30] ${OPT} Broot${RST}"
 echo -e "   [31] ${OPT} Dust${RST}"
 echo -e "   [32] ${OPT} Procs${RST}"
 echo -e "   [33] ${OPT} Tldr${RST}"
 echo -e "   [34] ${OPT} Node.Js${RST}"
 echo -e "   [35] ${OPT} Gh${RST}"
 echo -e "   [36] ${OPT} Holehe${RST}"
 echo -e "   [37] ${OPT} Asciiquarium${RST}"
 echo -e "   [38] ${OPT} Wttr${RST}"
 echo -e "   [39] ${OPT} Tmux${RST}"
 echo -e "   [40] ${OPT} Lazygit${RST}"
 echo ""
 echo -e "${INFO}  [b] Back to main-menu ${RST}"
 echo -e "${ERR}  [e] Exit Script"
  echo -e "${INFO}"
   read -p " [*] Select numbers (space separated): " -a choices
  echo -e "${RST}"
 for choice in "${choices[@]}"; do
   case "$choice" in
  01|1) uninstall_pkg git "Git" ;;
  02|2) uninstall_pkg curl "Curl" ;;
  03|3) uninstall_pkg wget "Wget" ;;
  04|4) uninstall_pkg bat "Bat" ;;
  05|5) uninstall_pkg htop "Htop" ;;
  06|6) uninstall_pkg fish "Fish" ;;
  07|7) uninstall_pkg ssh "OpenSSH" ;;
  08|8) uninstall_pkg python3 "Python3" ;;
  09|9) uninstall_pkg nmap "Nmap" ;;
    10) uninstall_pkg cacademo "Libcaca" ;;
    11) uninstall_pkg speedtest-go "Speedtest-Go" ;;
    12) uninstall_pkg cpufetch "CPUfetch" ;;
    13) uninstall_pkg neofetch "Neofetch" ;;
    14) uninstall_pkg ranger "Ranger" ;;
    15) uninstall_pkg nano "Nano" ;;
    16) uninstall_pkg sl "Steam Locomotive," ;;
    17) uninstall_pkg ncdu "Ncdu" ;;
    18) uninstall_pkg nvim "Neovim" ;;
    19) uninstall_pkg cbonsai "Cbonsai" ;;
    20) uninstall_pkg asciinema "Asciinema" ;;
    21) uninstall_pkg croc "Croc" ;;
    22) uninstall_pkg fzf "Fzf" ;;
    23) uninstall_pkg zoxide "Zoxide" ;;
    24) uninstall_pkg zsh "Z shell" ;;
    25) uninstall_pkg duf "Duf" ;;
    26) uninstall_pkg tty-clock "Tty-clock" ;;
    27) uninstall_pkg pipes.sh "Pipes.sh" ;;
    28) uninstall_pkg yazi "Yazi" ;;
    29) uninstall_pkg lsd "Lsd" ;;
    30) uninstall_pkg broot "Broot" ;;
    31) uninstall_pkg dust "Dust" ;;
    32) uninstall_pkg procs "Procs" ;;
    33) uninstall_pkg tldr "Tldr" ;;
    34) uninstall_pkg nodejs "Node.Js" ;;
    35) uninstall_pkg gh "Gh";;
    36) uninstall_pip holehe "Holehe";;
    37) uninstall_pip asciiquarium "Asciiqurium";;
    38) uninstall_pip wttr "Wttr.io";;
    39) uninstall_pkg tmux "Tmux";;
    40) uninstall_pkg lazygit "Lazygit" ;;
     b|B) return ;;
     e|E) graceful_exit;;
     *) echo -e "$WARN [!] Invalid option: $choice$RST" ;;
   esac
  done
   echo ""
    read -p " [*] Press ENTER to continue..."
done
}
