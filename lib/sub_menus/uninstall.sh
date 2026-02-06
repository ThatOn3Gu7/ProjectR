#!/bin/bash


source lib/core/colors.sh
source lib/core/logging.sh
source lib/core/display.sh
source lib/core/spinner.sh
source lib/core/prompts.sh

source lib/system/detect.sh
source lib/system/network.sh
source lib/system/checker.sh

if [ -f lib/features/uninstaller.sh ]; then
    source lib/features/uninstaller.sh
fi

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
 echo -e "   [41] ${OPT} Ani-cli${RST}"
 echo ""
 echo -e "${INFO}  [b] Back to main-menu ${RST}"
 echo -e "${ERR}  [e] Exit Script"
  echo -e "${INFO}"
   read -p " [*] Select numbers (space separated): " -a choices
  echo -e "${RST}"
 for choice in "${choices[@]}"; do
   case "$choice" in
   # 1) echo -e "${RST}"
   #   uninstall_pkg git git "Git"  ;;
   2) echo -e "${ERR}"
     uninstall_pkg curl curl "Curl";;
   3) echo -e "${ERR}"
     uninstall_pkg wget wget "Wget";;
   4) echo -e "${ERR}"
     uninstall_pkg bat bat "Bat";;
   5) echo -e "${ERR}"
     uninstall_pkg htop htop "Htop";;
   6) echo -e "${ERR}"
     uninstall_pkg fish fish "Fish";;
   7) echo -e "${ERR}"
     uninstall_pkg ssh openssh "OpenSSH";;
   8) echo -e "${ERR}"
     uninstall_pkg python3 python3 "Python3";;
   9) echo -e "${ERR}"
     uninstall_pkg nmap nmap "Nmap";;
   10) echo -e "${ERR}" 
     uninstall_pkg cacademo libcaca "Libcaca";;
   11) echo -e "${ERR}"
     uninstall_pkg speedtest-go speedtest-go "Speedtest-go" ;;
   12) echo -e "${ERR}"
     uninstall_pkg cpufetch cpufetch "Cpufetch";;
   13) echo -e "${ERR}"
     uninstall_pkg neofetch neofetch "Neofetch";;
   14) echo -e "${ERR}"
     uninstall_pkg ranger ranger "Ranger";;
   15) echo -e "${ERR}"
     uninstall_pkg nano nano "Nano";;
   16) echo -e "${ERR}"
     uninstall_pkg sl sl "Sl";;
   17) echo -e "${ERR}"
     uninstall_pkg ncdu ncdu "Ncdu" ;;
   18) echo -e "${ERR}"
     uninstall_pkg nvim neovim "Neovim";;
   19) echo -e "${ERR}"
     uninstall_pkg cbonsai cbonsai "Cbonsai";;
   20) echo -e "${ERR}"
     uninstall_pkg asciinema asciinema "Asciinema";;
   21) echo -e "${ERR}"
     uninstall_pkg croc croc "Croc";;
   22) echo -e "${ERR}"
     uninstall_pkg fzf fzf "Fzf";;
   23) echo -e "${ERR}"
     uninstall_pkg zoxide zoxide "Zoxide" ;;
   24) echo -e "${ERR}"
     uninstall_pkg zsh zsh "Zsh";;
   25) echo -e "${ERR}"
     uninstall_pkg duf duf "Duf";;
   26) echo -e "${ERR}"
     uninstall_pkg tty-clock tty-clock "Tty-clock";;
   27) echo -e "${ERR}"
     uninstall_pkg pipes.sh pipes.sh "Pipes.sh";;
   28) echo -e "${ERR}"
     uninstall_pkg yazi yazi "Yazi";;
   29) echo -e "${ERR}"
     uninstall_pkg lsd lsd "Lsd";;
   30) echo -e "${ERR}"
     uninstall_pkg broot broot "Broot";;
   31) echo -e "${ERR}"
     uninstall_pkg dust dust "Dust";;
   32) echo -e "${ERR}"
     uninstall_pkg procs procs "Procs";;
   33) echo -e "${ERR}"
     uninstall_pkg tldr tldr "Tldr";;
   34) echo -e "${ERR}"
     uninstall_pkg npm node.js "Node.Js";;
   35) echo -e "${ERR}"
     uninstall_pkg gh gh "Gh";;
   36) echo -e "${ERR}"
     uninstall_pkg holehe "Holehe";;
   37) echo -e "${ERR}"
     uninstall_pip asciiquarium "Asciiqurium";;
   38) echo -e "${ERR}"
     uninstall_pip wttr "Wttr.io";;
   39) echo -e "${ERR}"
     uninstall_pip tmux tmux "Tmux";;
   40) echo -e "${ERR}"
     uninstall_pkg lazygit lazygit "Lazygit";;
   41) echo -e "${ERR}"
     uninstall_pkg ani-cli ani-cli "Ani-cli";;
  b|B) return ;;
  e|E) graceful_exit;;
     *) echo -e "${ERR} [!] Invalid option: $choice ${RST}" ;;
   esac
  done
   echo -e "${OPT}"
    read -p " [*] Press ENTER to continue..."
   echo -e "${RST}"
done
}
