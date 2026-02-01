#!/bin/bash
source $HOME/ProjectR/lib/detect.sh
source $HOME/ProjectR/lib/install.sh
source $HOME/ProjectR/lib/utils.sh
source $HOME/ProjectR/lib/presets.sh
source $HOME/ProjectR/lib/uninstall.sh
# PM="$(detect_pkg_manager)"
trap graceful_exit SIGINT
log START "Script started"
# source /data/data/com.termux/files/home/project/lib/detect.sh
# source /data/data/com.termux/files/home/project/lib/install.sh
# source /data/data/com.termux/files/home/project/lib/utils.sh
# # ---  COLORS AND STYLING ---
# Define colors for a dark terminal environment (Termux/Hack look)
LOGO="\e[96m"    # Bright Cyan (For Logo/Headers)
INFO="\e[93m"    # Bright Yellow/Gold (For infor text/prompts)
OPT="\e[92m"  # Bright Green (For menu options)
ERR="\e[91m"   # Bright Red (For errors)
BARR="\e[95m" # Bright Magenta (For visual dividers/barriers)
RST="\e[0m"      # Reset/No Color (Crucial for prompt fix)
BOLD="\e[1m"     # Bold text
WHI="\e[97m"  # Bright White Text

# a call for startup internet check
startup_wifi_check

# --- SETUP ESSENTIAL TOOLS INSTALLATION MENU ---
show_main_menu() {
 clear
  # cool LOGO
  cat <<"EOF" | lolcat

      _       ___   __   __   ___     _              _   _     ___
     | |     | __|  \ \ / /  | __|   | |      ___   | | | |   | _ \
     | |__   | _|    \ V /   | _|    | |__   |___|  | |_| |   |  _/
     |____|  |___|   _\_/_   |___|   |____|  _____   \___/   _|_|_
   _|"""""|_|"""""|_| """"|_|"""""|_|"""""|_|     |_|"""""|_| """ |
   "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'

        ━━━━━━━━━━━━━━ [ SETUP ESSENTIAL TOOLS ] ━━━━━━━━━━━━━━
EOF

  echo -e "${OPT}${BOLD}"
  boxed_text left "[*] Select the pkg/tool you want to install:" 

  echo -e "${BARR}   ╔═════════════╗ ${RST}"
  echo -e "${BARR}   ║ ${RST}dpkg tools: ${BARR}║${RST}"
  echo -e "${BARR}   ╚╔════════════╝═════════════════════════╗ ${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}1${OPT}]  Git           ${INFO}- Version control ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}2${OPT}]  Curl          ${INFO}- HTTP requests ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}3${OPT}]  Wget          ${INFO}- File downloads ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}4${OPT}]  Bat           ${INFO}- 'cat' with syntax highlighting ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}5${OPT}]  Htop          ${INFO}- Process viewer ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}6${OPT}]  Fish          ${INFO}- Friendly shell ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}7${OPT}]  OpenSSH       ${INFO}- SSH access ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}8${OPT}]  Python        ${INFO}- Programming language ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}9${OPT}]  Nmap          ${INFO}- Network scanning ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}10${OPT}] Libcaca       ${INFO}- A fire effect ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}11${OPT}] Speedtest-go  ${INFO}- Internet speed-test ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}12${OPT}] Cpufetch      ${INFO}- CPU information ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}13${OPT}] Neofetch      ${INFO}- System information ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}14${OPT}] Ranger        ${INFO}- Terminal file manager ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}15${OPT}] Nano          ${INFO}- Text editor ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}16${OPT}] Sl            ${INFO}- Steam Locomotive ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}17${OPT}] Ncdu          ${INFO}- NCurses disk usage analyzer ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}18${OPT}] Neovim        ${INFO}- Best code editor ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}19${OPT}] Cbonsai       ${INFO}- Japanise bonsai tree ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}20${OPT}] Asciinema     ${INFO}- Terminal recording tool ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}21${OPT}] Croc          ${INFO}- File transferring tool ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}22${OPT}] Fzf           ${INFO}- File finder ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}23${OPT}] Zoxide        ${INFO}- Smarter cd command ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}24${OPT}] Zsh           ${INFO}- Best shell ever ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}25${OPT}] Duf           ${INFO}- Disk Usage/Free utility ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}26${OPT}] tty-clock     ${INFO}- A terminal clock ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}27${OPT}] Pipes.sh      ${INFO}- A cool tool for ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}28${OPT}] Yazi          ${INFO}- Amazing filemanager for terminal ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}29${OPT}] Lsd           ${INFO}- An 'ls' alternative with icons/colors ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}30${OPT}] Broot         ${INFO}- Navigate directories with overviews ${OPT}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}31${OPT}] Dust          ${INFO}- More intuitive version of du ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}32${OPT}] Procs         ${INFO}- Modern replacement for 'ps' ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}33${OPT}] Tldr          ${INFO}- Simplified, community-driven man pages ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}34${OPT}] Node.Js       ${INFO}- JavaScript Runtime environment ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}35${OPT}] Gh            ${INFO}- A github-cli client ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}36${OPT}] Holehe        ${INFO}- Email OSINT scanner ${OPT}(OSINT)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}37${OPT}] Asciiquarium  ${INFO}- View of the sea ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}38${OPT}] Wttr          ${INFO}- A weather tool ${OPT}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPT} [${WHI}39${OPT}] Tmux          ${INFO}- A multitasker tool ${OPT}(Dev)${RST}"
  echo -e "${BARR}    ╚═════════════════════════════════════╝ ${RST}"

echo ""
echo -e "${BARR}   ╔══════════════════╗ ${RST}"
echo -e "${BARR}   ║${RST}${OPT} [${WHI}0${OPT}] Install ALL tools${RST}"
echo -e "${BARR}   ║${RST}${OPT} [${WHI}p${OPT}] Install by preset${RST}"
echo -e "${BARR}   ║${RST}${OPT} [${WHI}i${OPT}] Inspect installed tools${RST}"
echo -e "${BARR}   ║${RST}${OPT} [${WHI}u${OPT}] Uninstall tools${RST}"
echo -e "${BARR}   ║${RST}${OPT} [${ERR}e${OPT}] Exits the script${RST}"
echo -e "${BARR}   ╚══════════════════╝ ${RST}"
  echo -e "${OPT}${BOLD}"
  read -p " [*] Enter the tool numbers (separate by spaces): " -a selections
  echo ""
}

profile_menu() {
 while true; do
  clear
   log ENTER "User entered sub-menu 'install-sresets'"
  echo -e "${OPT}${BOLD}"
   boxed_text center "Choose the preset you want to install"
  echo -e "${OPT}"
   boxed_text center "[1] Minimal tools
[2] Developer tools
[3] Fun tools"
  echo -e "${ERR}"
   boxed_text center "[b]ack to main menu"
  echo -e "${RST}"
  echo -ne "${INFO}${BOLD} [*] Choose an option: ${RST}"
   read profile_choice
  echo ""
  case "$profile_choice" in
    1) log INSTALL "User chose to install 'Minimal tools preset'"
      install_preset "${PRESET_MINIMAL[@]}"
      ;;
    2) log INSTALL "User chose to install 'Developer tools preset'"
      install_preset "${PRESET_DEV[@]}"
      ;;
    3) log INSTALL "User chose to install 'Fun tools preset'"
      install_preset "${PRESET_FUN[@]}"
      ;;
    b|B) log LEFT "User exited sub-menu 'install-sresets'"
       return 0
      ;;
    *) echo ""
       echo -e "${ERR}"
      boxed_text center "[x] Invalid choice: '$profile_choice', Please select the right option."
       echo -e "${RST}"
      sleep 3
  esac
 done
}

while true; do
 show_main_menu
  for selected in "${selections[@]}"; do
   case $selected in
  # Install commands for apt tools.
  1)  install_pkg git git "Git: Version control," ;;
  2)  install_pkg curl curl "Curl: HTTP request" ;;
  3)  install_pkg wget wget "Wget: Command-line downloader" ;;
  4)  install_pkg bat bat "Bat: A better cat" ;;
  5)  install_pkg htop htop "Htop: Hardware use Checker" ;;
  6)  install_pkg fish fish "Fish: A advanced Shell" ;;
  7)  install_pkg ssh openssh "OpenSSH: Server deployment" ;;
  8)  install_pkg python3 python3 "Python3: Coding language" ;;
  9)  install_pkg nmap nmap "Nmap: Network scanner" ;;
  10) install_pkg cacademo libcaca "Libcaca: Cool fire" ;;
  11) install_pkg speedtest-go speedtest-go "Speedtest-Go: WI-FI-speed Checker " ;;
  12) install_pkg cpufetch cpufetch "CPUfetch: Cpu-info" ;;
  13) install_pkg neofetch neofetch "Neofetch: System-info" ;;
  14) install_pkg ranger ranger "Ranger: Also a Filamanager" ;;
  15) install_pkg nano nano "Nano: Text editor" ;;
  16) install_pkg sl sl "Steam Locomotive" ;;
  17) install_pkg ncdu ncdu "Ncdu: du Checker" ;;
  18) install_neovim_full ;;
  19) install_pkg cbonsai cbonsai "Cbonsai: Japanise tree" ;;
  20) install_pkg asciinema asciinema "Asciinema: Terminal-recoder" ;;
  21) install_pkg croc croc "Croc: File-sender" ;;
  22) install_pkg fzf fzf "Fzf: File-finder" ;;
  23) install_pkg zoxide zoxide "Zoxide: A better 'cd'" ;;
  24) install_zsh_full ;;
  25) install_pkg duf duf "Duf: File/dir size Checker" ;;
  26) install_pkg tty-clock tty-clock "tty-clock: A big clock" ;;
  27) install_pkg pipes.sh pipes.sh "Pipes.sh: Snake" ;;
  28) install_pkg yazi yazi "Yazi: Filamanager" ;;
  29) install_pkg lsd lsd "Lsd: 'ls' alternative" ;;
  30) install_pkg broot broot "Broot: Filenavigator" ;; 
  31) install_pkg dust dust "Dust: Better version of du" ;;
  32) install_pkg procs procs "Procs: Morden 'ps'" ;;
  33) install_pkg tldr tldr "Tldr: Man pages" ;;
  34) install_pkg npm nodejs "Node.Js: JS Runtime env," ;;
  35) install_pkg gh gh "Gh: Guthub-Cli" ;;
  # Install commands for pip tools
  36) install_pip_package "holehe" "Holehe" ;;
  37) install_pip_package "asciiquarium" "Asciiquarium" ;;
  38) install_pip_package "wttr" "Wttr" ;;
  39) install_pkg tmux tmux "Tmux: A multitasker" ;;

  0) clear
    install_all
    ;;
  p|P)
    profile_menu
    ;;
  i|I) clear
    check_tool_main
    ;;
  u|U) clear
    uninstall_menu
    ;;
  e|E)
    graceful_exit
    ;;
  *) 
    echo -e "${ERR}${BOLD}"
    boxed_text center "[x] Invalid input: '$selections'. Please select the right option."
    echo -e "${RST}"
    sleep 2
    continue # This restarts the loop immediately
    ;;
  esac
 done
done
