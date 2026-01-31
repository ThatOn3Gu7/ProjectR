#!/bin/bash
source $HOME/ProjectR/lib/detect.sh
source $HOME/ProjectR/lib/install.sh
source $HOME/ProjectR/lib/utils.sh
source $HOME/ProjectR/lib/presets.sh
source $HOME/ProjectR/lib/uninstall.sh
PM="$(detect_pkg_manager)"
trap graceful_exit SIGINT
log START "Script started"
# source /data/data/com.termux/files/home/project/lib/detect.sh
# source /data/data/com.termux/files/home/project/lib/install.sh
# source /data/data/com.termux/files/home/project/lib/utils.sh
# # ---  COLORS AND STYLING ---
# Define colors for a dark terminal environment (Termux/Hack look)
LOGO="\e[96m"    # Bright Cyan (For Logo/Headers)
INFO="\e[93m"    # Bright Yellow/Gold (For infor text/prompts)
OPTION="\e[92m"  # Bright Green (For menu options)
ERROR="\e[91m"   # Bright Red (For errors)
BARRIER="\e[95m" # Bright Magenta (For visual dividers/barriers)
RST="\e[0m"      # Reset/No Color (Crucial for prompt fix)
BOLD="\e[1m"     # Bold text
WHITE="\e[97m"  # Bright White Text

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

  echo -e "${OPTION}${BOLD}"
  boxed_text left "[*] Select the pkg/tool you want to install:" 

  echo -e "${BARRIER}   ╔═════════════╗ ${RST}"
  echo -e "${BARRIER}   ║ ${RST}dpkg tools: ${BARRIER}║${RST}"
  echo -e "${BARRIER}   ╚╔════════════╝═════════════════════════╗ ${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}1${OPTION}]  Git           ${INFO}- Version control ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}2${OPTION}]  Curl          ${INFO}- HTTP requests ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}3${OPTION}]  Wget          ${INFO}- File downloads ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}4${OPTION}]  Bat           ${INFO}- 'cat' with syntax highlighting ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}5${OPTION}]  Htop          ${INFO}- Process viewer ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}6${OPTION}]  Fish          ${INFO}- Friendly shell ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}7${OPTION}]  OpenSSH       ${INFO}- SSH access ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}8${OPTION}]  Python        ${INFO}- Programming language ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}9${OPTION}]  Nmap          ${INFO}- Network scanning ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}10${OPTION}] Libcaca       ${INFO}- A fire effect ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}11${OPTION}] Speedtest-go  ${INFO}- Internet speed-test ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}12${OPTION}] Cpufetch      ${INFO}- CPU information ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}13${OPTION}] Neofetch      ${INFO}- System information ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}14${OPTION}] Ranger        ${INFO}- Terminal file manager ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}15${OPTION}] Nano          ${INFO}- Text editor ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}16${OPTION}] Sl            ${INFO}- Steam Locomotive ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}17${OPTION}] Ncdu          ${INFO}- NCurses disk usage analyzer ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}18${OPTION}] Neovim        ${INFO}- Best code editor ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}19${OPTION}] Cbonsai       ${INFO}- Japanise bonsai tree ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}20${OPTION}] Asciinema     ${INFO}- Terminal recording tool ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}21${OPTION}] Croc          ${INFO}- File transferring tool ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}22${OPTION}] Fzf           ${INFO}- File finder ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}23${OPTION}] Zoxide        ${INFO}- Smarter cd command ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}24${OPTION}] Zsh           ${INFO}- Best shell ever ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}25${OPTION}] Duf           ${INFO}- Disk Usage/Free utility ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}26${OPTION}] tty-clock     ${INFO}- A terminal clock ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}27${OPTION}] Pipes.sh      ${INFO}- A cool tool for ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}28${OPTION}] Yazi          ${INFO}- Amazing filemanager for terminal ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}29${OPTION}] Lsd           ${INFO}- An 'ls' alternative with icons/colors ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}30${OPTION}] Broot         ${INFO}- Navigate directories with overviews ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}31${OPTION}] Dust          ${INFO}- More intuitive version of du ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}32${OPTION}] Procs         ${INFO}- Modern replacement for 'ps' ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}33${OPTION}] Tldr          ${INFO}- Simplified, community-driven man pages ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}34${OPTION}] Node.Js       ${INFO}- JavaScript Runtime environment ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}35${OPTION}] Gh            ${INFO}- A github-cli client ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}36${OPTION}] Holehe        ${INFO}- Email OSINT scanner ${OPTION}(OSINT)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}37${OPTION}] Asciiquarium  ${INFO}- View of the sea ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}38${OPTION}] Wttr          ${INFO}- A weather tool ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [${WHITE}39${OPTION}] Tmux          ${INFO}- A multitasker tool ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ╚═════════════════════════════════════╝ ${RST}"

echo ""
echo -e "${BARRIER}   ╔══════════════════╗ ${RST}"
echo -e "${BARRIER}   ║${RST}${OPTION} [${WHITE}0${OPTION}] Install ALL tools${RST}"
echo -e "${BARRIER}   ║${RST}${OPTION} [${WHITE}p${OPTION}] Install by preset${RST}"
echo -e "${BARRIER}   ║${RST}${OPTION} [${WHITE}i${OPTION}] Inspect installed tools${RST}"
echo -e "${BARRIER}   ║${RST}${OPTION} [${WHITE}u${OPTION}] Uninstall tools${RST}"
echo -e "${BARRIER}   ║${RST}${OPTION} [${ERROR}e${OPTION}] Exits the script${RST}"
echo -e "${BARRIER}   ╚══════════════════╝ ${RST}"
  echo -e "${OPTION}${BOLD}"
  read -p " [*] Enter the tool numbers (separate by spaces): " -a selections
  echo ""
}

profile_menu() {
 while true; do
  clear
   log ENTER "User entered sub-menu 'install-sresets'"
  echo -e "${OPTION}${BOLD}"
   boxed_text center "Choose the preset you want to install"
  echo -e "${OPTION}"
   boxed_text center "[1] Minimal tools
[2] Developer tools
[3] Fun tools"
  echo -e "${ERROR}"
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
       echo -e "${ERROR}"
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
    uninstall_pkg_menu 
    ;;
  e|E)
    graceful_exit
    ;;
  *) 
    echo -e "${ERROR}${BOLD}"
    boxed_text center "[x] Invalid input: '$selections'. Please select the right option."
    echo -e "${RST}"
    sleep 2
    continue # This restarts the loop immediately
    ;;
  esac
 done
done
