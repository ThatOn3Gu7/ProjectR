#!/bin/bash

source $HOME/ProjectR/lib/utils.sh

# uninstaller menu
uninstall_pkg_menu() {
  while true; do
   clear
 echo -e "${OPTION} [1] Git         ${RST}"
 echo -e "${OPTION} [2] Git         ${RST}"
 echo -e "${OPTION} [3] Curl        ${RST}"
 echo -e "${OPTION} [4] Wget        ${RST}"
 echo -e "${OPTION} [5] Bat         ${RST}"
 echo -e "${OPTION} [6] Htop        ${RST}"
 echo -e "${OPTION} [7] Fish        ${RST}"
 echo -e "${OPTION} [8] OpenSSH     ${RST}"
 echo -e "${OPTION} [9] Python      ${RST}"
 echo -e "${OPTION} [10] Nmap        ${RST}"
 echo -e "${OPTION} [11] Libcaca     ${RST}"
 echo -e "${OPTION} [12] Speedtest-go${RST}"
 echo -e "${OPTION} [13] Cpufetch    ${RST}"
 echo -e "${OPTION} [14] Neofetch    ${RST}"
 echo -e "${OPTION} [15] Ranger      ${RST}"
 echo -e "${OPTION} [16] Nano        ${RST}"
 echo -e "${OPTION} [17] Sl          ${RST}"
 echo -e "${OPTION} [18] Ncdu        ${RST}"
 echo -e "${OPTION} [19] Neovim      ${RST}"
 echo -e "${OPTION} [20] Cbonsai     ${RST}"
 echo -e "${OPTION} [21] Asciinema   ${RST}"
 echo -e "${OPTION} [22] Croc        ${RST}"
 echo -e "${OPTION} [23] Fzf         ${RST}"
 echo -e "${OPTION} [24] Zoxide      ${RST}"
 echo -e "${OPTION} [25] Zsh         ${RST}"
 echo -e "${OPTION} [26] Duf         ${RST}"
 echo -e "${OPTION} [27] tty-clock   ${RST}"
 echo -e "${OPTION} [28] Pipes.sh    ${RST}"
 echo -e "${OPTION} [29] Yazi        ${RST}"
 echo -e "${OPTION} [30] Lsd         ${RST}"
 echo -e "${OPTION} [31] Broot       ${RST}"
 echo -e "${OPTION} [32] Dust        ${RST}"
 echo -e "${OPTION} [33] Procs       ${RST}"
 echo -e "${OPTION} [34] Tldr        ${RST}"
 echo -e "${OPTION} [35] Node.Js     ${RST}"
 echo -e "${OPTION} [36] Gh          ${RST}"
 echo -e "${OPTION} [37] Holehe      ${RST}"
 echo -e "${OPTION} [38] Asciiquarium${RST}"
 echo -e "${OPTION} [39] Wttr        ${RST}"

 echo ""
  read -p "Enter pkg numbers (space separated): " -a selections
     
  for choice in "${selections[@]}"; do
      case "$choice" in
       1)  uninstall_pkg git "Git: Version control" ;;
       2)  uninstall_pkg curl "Curl: HTTP request" ;;
       3)  uninstall_pkg wget "Wget: Command-line downloader" ;;
       4)  uninstall_pkg bat "Bat: A better cat" ;;
       5)  uninstall_pkg htop "Htop: Hardware use Checker" ;;
       6)  uninstall_pkg fish "Fish: A advanced Shell" ;;
       7)  uninstall_pkg openssh "OpenSSH: Server deployment" ;;
       8)  uninstall_pkg python3 "Python3: Coding language" ;;
       9)  uninstall_pkg nmap "Nmap: Network scanner" ;;
       10) uninstall_pkg libcaca "Libcaca: Cool fire" ;;
       11) uninstall_pkg speedtest-go "Speedtest-Go: WI-FI-speed Checker" ;;
       12) uninstall_pkg cpufetch "CPUfetch: Cpu-info" ;;
       13) uninstall_pkg neofetch "Neofetch: System-info" ;;
       14) uninstall_pkg ranger "Ranger: Also a Filamanager" ;;
       15) uninstall_pkg nano "Nano: Text editor" ;;
       16) uninstall_pkg sl "Steam Locomotive" ;;
       17) uninstall_pkg ncdu "Ncdu: du Checker" ;;
       18) uninstall_pkg neovim "NeoVim: Best code editor" ;;
       19) uninstall_pkg cbonsai "Cbonsai: Japanise tree" ;;
       20) uninstall_pkg asciinema "Asciinema: Terminal-recoder" ;;
       21) uninstall_pkg croc "Croc: File-sender" ;;
       22) uninstall_pkg fzf "Fzf: File-finder" ;;
       23) uninstall_pkg zoxide "Zoxide: A better 'cd'" ;;
       24) uninstall_pkg zsh "Z-Shell: Most awesome shell" ;;
       25) uninstall_pkg duf "Duf: File/dir size Checker" ;;
       26) uninstall_pkg tty-clock "tty-clock: A big clock" ;;
       27) uninstall_pkg pipes.sh "Pipes.sh: Snake" ;;
       28) uninstall_pkg yazi "Yazi: Filamanager" ;;
       29) uninstall_pkg lsd "Lsd: 'ls' alternative" ;;
       30) uninstall_pkg broot "Broot: Filenavigator" ;; 
       31) uninstall_pkg dust "Dust: Better version of du" ;;
       32) uninstall_pkg procs "Procs: Morden 'ps'" ;;
       33) uninstall_pkg tldr "Tldr: Man pages" ;;
       34) uninstall_pkg nodejs "Node.Js: JavaScript Runtime environment," ;;
       35) uninstall_pkg gh "Gh: Guthub-Cli" ;;
       # Install commands for pip tools
       36)  holehe "Holehe" ;;
       37)  asciiquarium "Asciiquarium" ;;
       38)  wttr "Wttr" ;;
        0) return ;;
        *) echo -e "${ERROR}${BOLD}"
              boxed_text center "[!] Invalid option: $choice" ;;
       esac
  done 
 done
}      
       
# unin stalls given pkg
uninstall_pkg() {
 local pkg=$1
 local name="$2"
 # start spinner
 start_spinner " [*] Removing pkg: $name..."
  case $PM in
    apt)
        sudo apt remove -y "$pkg" >/dev/null 2>&1
        ;;
    dnf)
        sudo dnf remove -y "$pkg" >/dev/null 2>&1
        ;;
    yum)
        sudo yum remove -y "$pkg" >/dev/null 2>&1
        ;;
    pacman)
        sudo pacman -Rs --noconfirm "$pkg" >/dev/null 2>&1
        ;;
    zypper)
        sudo zypper remove -y "$pkg" >/dev/null 2>&1
        ;;
    brew)
        brew uninstall "$pkg" >/dev/null 2>&1
        ;;
    apk)
        sudo apk del "$pkg" >/dev/null 2>&1
        ;;
    emerge)
        sudo emerge --unmerge "$pkg" >/dev/null 2>&1
        ;;
    nix-env)
        nix-env -e "$pkg" >/dev/null 2>&1
        ;;
    flatpak)
        flatpak uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    snap)
        sudo snap remove "$pkg" >/dev/null 2>&1
        ;;
    pkg)
        pkg uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    chocolatey)
        choco uninstall -y "$pkg" >/dev/null 2>&1
        ;;
    scoop)
        scoop uninstall "$pkg" >/dev/null 2>&1
        ;;
    winget)
        winget uninstall --id "$pkg" >/dev/null 2>&1
        ;;
       *)
         echo -e "${ERROR}${BOLD}"
          boxed_text center "[!] Unsupported package manager.."
         return 1
        ;;
  esac
  # Stop spinner
  stop_spinner ""
}
