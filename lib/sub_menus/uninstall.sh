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
  cat <<"EOF" #| lolcat

  ██████╗ ██████╗ ███╗   ███╗ ██████╗ ██╗   ██╗███████╗    ██╗████████╗
  ██╔══██╗╚════██╗████╗ ████║██╔═══██╗██║   ██║██╔════╝    ██║╚══██╔══╝
  ██████╔╝ █████╔╝██╔████╔██║██║   ██║██║   ██║█████╗ ███╗ ██║   ██║   
  ██╔══██╗ ╚═══██╗██║╚██╔╝██║██║   ██║╚██╗ ██╔╝██╔══╝ ╚══╝ ██║   ██║   
  ██║  ██║██████╔╝██║ ╚═╝ ██║╚██████╔╝ ╚████╔╝ ███████╗    ██║   ██║   
  ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝    ╚═╝   ╚═╝
   [--------------------------------------------------------------]
     > Purpose: Made to remove installed tools/utilities.
     > C0ded by: ThatOn3Gu7
     > V3rsion: 1.1 | 2026-02-10
     > Status: [ Ready to purge packages ]
   [--------------------------------------------------------------]

EOF
echo -e "${OPTION}"
boxed_text left "[*] Available tools for deletion:"
echo -e "${RST}"
 echo -e "   [01]${OPTION} Git          ${INFO}- Version control  ${RST}"
 echo -e "   [02]${OPTION} Curl         ${INFO}- HTTP requests  ${RST}"
 echo -e "   [03]${OPTION} Wget         ${INFO}- File downloads  ${RST}"
 echo -e "   [04]${OPTION} Bat          ${INFO}- 'cat' with syntax highlighting  ${RST}"
 echo -e "   [05]${OPTION} Htop         ${INFO}- Process viewer  ${RST}"
 echo -e "   [06]${OPTION} Fish         ${INFO}- Friendly shell  ${RST}"
 echo -e "   [07]${OPTION} OpenSSH      ${INFO}- SSH access  ${RST}"
 echo -e "   [08]${OPTION} Python       ${INFO}- Programming language  ${RST}"
 echo -e "   [09]${OPTION} Nmap         ${INFO}- Network scanning  ${RST}"
 echo -e "   [10]${OPTION} Libcaca      ${INFO}- A fire effect  ${RST}"
 echo -e "   [11]${OPTION} Speedtest-go ${INFO}- Internet speed-test  ${RST}"
 echo -e "   [12]${OPTION} Cpufetch     ${INFO}- CPU information  ${RST}"
 echo -e "   [13]${OPTION} Neofetch     ${INFO}- System information  ${RST}"
 echo -e "   [14]${OPTION} Ranger       ${INFO}- Terminal file manager  ${RST}"
 echo -e "   [15]${OPTION} Nano         ${INFO}- Text editor  ${RST}"
 echo -e "   [16]${OPTION} Sl           ${INFO}- Steam Locomotive  ${RST}"
 echo -e "   [17]${OPTION} Ncdu         ${INFO}- NCurses disk usage analyzer  ${RST}"
 echo -e "   [18]${OPTION} Neovim       ${INFO}- Best code editor  ${RST}"
 echo -e "   [19]${OPTION} Cbonsai      ${INFO}- Japanise bonsai tree  ${RST}"
 echo -e "   [20]${OPTION} Asciinema    ${INFO}- Terminal recording tool  ${RST}"
 echo -e "   [21]${OPTION} Croc         ${INFO}- File transferring tool  ${RST}"
 echo -e "   [22]${OPTION} Fzf          ${INFO}- File finder  ${RST}"
 echo -e "   [23]${OPTION} Zoxide       ${INFO}- Smarter cd command  ${RST}"
 echo -e "   [24]${OPTION} Zsh          ${INFO}- Best shell ever  ${RST}"
 echo -e "   [25]${OPTION} Duf          ${INFO}- Disk Usage/Free utility  ${RST}"
 echo -e "   [26]${OPTION} Tty-clock    ${INFO}- A terminal clock  ${RST}"
 echo -e "   [27]${OPTION} Pipes.sh     ${INFO}- A cool tool for Fun ${RST}"
 echo -e "   [28]${OPTION} Yazi         ${INFO}- Amazing filemanager for terminal  ${RST}"
 echo -e "   [29]${OPTION} Lsd          ${INFO}- An 'ls' alternative with icons/colors  ${RST}"
 echo -e "   [30]${OPTION} Broot        ${INFO}- Navigate directories with overviews  ${RST}"
 echo -e "   [31]${OPTION} Dust         ${INFO}- More intuitive version of du  ${RST}"
 echo -e "   [32]${OPTION} Procs        ${INFO}- Modern replacement for 'ps'  ${RST}"
 echo -e "   [33]${OPTION} Tldr         ${INFO}- Simplified, community-driven man pages  ${RST}"
 echo -e "   [34]${OPTION} Node.Js      ${INFO}- JavaScript Runtime environment  ${RST}"
 echo -e "   [35]${OPTION} Gh           ${INFO}- A github-cli client  ${RST}"
 echo -e "   [36]${OPTION} Holehe       ${INFO}- Email OSINT scanner  ${RST}"
 echo -e "   [37]${OPTION} Asciiquarium ${INFO}- View of the sea  ${RST}"
 echo -e "   [38]${OPTION} Wttr         ${INFO}- A weather tool  ${RST}"
 echo -e "   [39]${OPTION} Tmux         ${INFO}- A multitasker tool  ${RST}"
 echo -e "   [40]${OPTION} Lazygit      ${INFO}- An TUI for git  ${RST}"
 echo -e "   [41]${OPTION} Ani-cli      ${INFO}- A terminal anime streaming tool  ${RST}"
 echo -e "   [42]${OPTION} Code-Server  ${INFO}- VsCode on android  ${RST}"
 echo -e "   [43]${OPTION} Pipx         ${INFO}- A python-cli tool installer  ${RST}"
 echo ""
 echo -e "${OPTION}  [i] Inspect installed ${RST}"
 echo -e "${INFO}  [b] Back to main-menu ${RST}"
 echo -e "${ERROR}  [e] Exit Script"
  echo -e "${INFO}"
   read -p " [*] Select numbers (space separated): " -a choices
  echo -e "${RST}"
 for choice in "${choices[@]}"; do
   case "$choice" in
   # 1) echo -e "${RST}"
   #   uninstall_pkg git git "Git"  ;;
   2) echo -e "${ERROR}"
     uninstall_pkg curl curl "Curl";;
   3) echo -e "${ERROR}"
     uninstall_pkg wget wget "Wget";;
   4) echo -e "${ERROR}"
     uninstall_pkg bat bat "Bat";;
   5) echo -e "${ERROR}"
     uninstall_pkg htop htop "Htop";;
   6) echo -e "${ERROR}"
     uninstall_pkg fish fish "Fish";;
   7) echo -e "${ERROR}"
     uninstall_pkg ssh openssh "OpenSSH";;
   8) echo -e "${ERROR}"
     uninstall_pkg python3 python3 "Python3";;
   9) echo -e "${ERROR}"
     uninstall_pkg nmap nmap "Nmap";;
   10) echo -e "${ERROR}" 
     uninstall_pkg cacademo libcaca "Libcaca";;
   11) echo -e "${ERROR}"
     uninstall_pkg speedtest-go speedtest-go "Speedtest-go" ;;
   12) echo -e "${ERROR}"
     uninstall_pkg cpufetch cpufetch "Cpufetch";;
   13) echo -e "${ERROR}"
     uninstall_pkg neofetch neofetch "Neofetch";;
   14) echo -e "${ERROR}"
     uninstall_pkg ranger ranger "Ranger";;
   15) echo -e "${ERROR}"
     uninstall_pkg nano nano "Nano";;
   16) echo -e "${ERROR}"
     uninstall_pkg sl sl "Sl";;
   17) echo -e "${ERROR}"
     uninstall_pkg ncdu ncdu "Ncdu" ;;
   18) echo -e "${ERROR}"
     uninstall_pkg nvim neovim "Neovim"
      if [ -d $HOME/.config/nvim/ ]; then
       echo -e "${INFO}"
       if ask "[*] Also remove any nvim config (if used)" "y" 5; then
        echo -e "${RST}"
        rm -rf ~/.config/nvim/ ~/.local/share/nvim/ ~/.cache/nvim/
      else
         return 0
       fi
      fi
     ;;
   19) echo -e "${ERROR}"
     uninstall_pkg cbonsai cbonsai "Cbonsai";;
   20) echo -e "${ERROR}"
     uninstall_pkg asciinema asciinema "Asciinema";;
   21) echo -e "${ERROR}"
     uninstall_pkg croc croc "Croc";;
   22) echo -e "${ERROR}"
     uninstall_pkg fzf fzf "Fzf";;
   23) echo -e "${ERROR}"
     uninstall_pkg zoxide zoxide "Zoxide" ;;
   24) echo -e "${ERROR}"
     uninstall_pkg zsh zsh "Zsh";;
   25) echo -e "${ERROR}"
     uninstall_pkg duf duf "Duf";;
   26) echo -e "${ERROR}"
     uninstall_pkg tty-clock tty-clock "Tty-clock";;
   27) echo -e "${ERROR}"
     uninstall_pkg pipes.sh pipes.sh "Pipes.sh";;
   28) echo -e "${ERROR}"
     uninstall_pkg yazi yazi "Yazi";;
   29) echo -e "${ERROR}"
     uninstall_pkg lsd lsd "Lsd";;
   30) echo -e "${ERROR}"
     uninstall_pkg broot broot "Broot";;
   31) echo -e "${ERROR}"
     uninstall_pkg dust dust "Dust";;
   32) echo -e "${ERROR}"
     uninstall_pkg procs procs "Procs";;
   33) echo -e "${ERROR}"
     uninstall_pkg tldr tldr "Tldr";;
   34) echo -e "${ERROR}"
     uninstall_pkg npm node.js "Node.Js";;
   35) echo -e "${ERROR}"
     uninstall_pkg gh gh "Gh";;
   36) echo -e "${ERROR}"
     uninstall_pip holehe "Holehe";;
   37) echo -e "${ERROR}"
     uninstall_pip asciiquarium "Asciiqurium";;
   38) echo -e "${ERROR}"
     uninstall_pip wttr "Wttr.io";;
   39) echo -e "${ERROR}"
     uninstall_pkg tmux tmux "Tmux";;
   40) echo -e "${ERROR}"
     uninstall_pkg lazygit lazygit "Lazygit";;
   41) echo -e "${ERROR}"
     uninstall_pkg ani-cli ani-cli "Ani-cli";;
   42) echo -e "${ERROR}"
     uninstall_pkg code-server code-server "Code-Server";;
   43) echo -e "${ERROR}"
    uninstall_pip pipx pipx "Pipx" ;;
  i|I) clear
    check_tool_main ;;
  b|B) return ;;
  e|E) graceful_exit;;
     *) echo -e "${ERROR} [!] Invalid option: $choice ${RST}" ;;
   esac
  done
   echo -e "${OPTION}"
    read -p " [*] Press ENTER to continue..."
   echo -e "${RST}"
done
}
