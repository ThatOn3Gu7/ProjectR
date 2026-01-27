#!/bin/bash
source $HOME/ProjectR/lib/detect.sh
source $HOME/ProjectR/lib/install.sh
source $HOME/ProjectR/lib/utils.sh
source $HOME/ProjectR/lib/presets.sh
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

# a call for startup internet check
startup_wifi_check

# --- SETUP ESSENTIAL TOOLS INSTALLATION MENU ---
show_menu() {
 # clear
  # cool LOGO
  echo -e "${LOGO}${BOLD}"
  cat <<"EOF" | lolcat

      _       ___   __   __   ___     _              _   _     ___
     | |     | __|  \ \ / /  | __|   | |      ___   | | | |   | _ \
     | |__   | _|    \ V /   | _|    | |__   |___|  | |_| |   |  _/
     |____|  |___|   _\_/_   |___|   |____|  _____   \___/   _|_|_
   _|"""""|_|"""""|_| """"|_|"""""|_|"""""|_|     |_|"""""|_| """ |
   "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'

        ━━━━━━━━━━━━━━ [ SETUP ESSENTIAL TOOLS ] ━━━━━━━━━━━━━━
EOF
  echo -e "${RST}"

  echo -e "${OPTION}${BOLD}"
  boxed_text left "[*] Select the pkg/tool you want to install:" 

  echo -e "${BARRIER}   ╔═════════════╗ ${RST}"
  echo -e "${BARRIER}   ║ ${RST}dpkg tools: ${BARRIER}║${RST}"
  echo -e "${BARRIER}   ╚╔════════════╝═════════════════════════╗ ${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [1]  Git          ${INFO}- Version control ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [2]  Curl         ${INFO}- HTTP requests ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [3]  Wget         ${INFO}- File downloads ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [4]  Bat          ${INFO}- 'cat' with syntax highlighting ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [5]  Htop         ${INFO}- Process viewer ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [6]  Fish         ${INFO}- Friendly shell ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [7]  OpenSSH      ${INFO}- SSH access ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [8]  Python       ${INFO}- Programming language ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [9]  Nmap         ${INFO}- Network scanning ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [10] Libcaca      ${INFO}- A fire effect ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [11] Speedtest-go ${INFO}- Internet speed-test ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [12] Cpufetch     ${INFO}- CPU information ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [13] Neofetch     ${INFO}- System information ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [14] Ranger       ${INFO}- Terminal file manager ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [15] Nano         ${INFO}- Text editor ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [16] Sl           ${INFO}- Steam Locomotive ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [17] Ncdu         ${INFO}- NCurses disk usage analyzer ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [18] Neovim       ${INFO}- Best code editor ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [19] Cbonsai      ${INFO}- Japanise bonsai tree ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [20] Asciinema    ${INFO}- Terminal recording tool ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [21] Croc         ${INFO}- File transferring tool ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [22] Fzf          ${INFO}- File finder ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [23] Zoxide       ${INFO}- Smarter cd command ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [24] Zsh          ${INFO}- Best shell ever ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [25] Duf          ${INFO}- Disk Usage/Free utility ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [26] tty-clock    ${INFO}- A terminal clock ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [27] Pipes.sh     ${INFO}- A cool tool for ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [28] Yazi         ${INFO}- Amazing filemanager for terminal ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [29] Lsd          ${INFO}- An 'ls' alternative with icons/colors ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [30] Broot        ${INFO}- Navigate directories with overviews ${OPTION}(Min)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [31] Dust         ${INFO}- More intuitive version of du ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [32] Procs        ${INFO}- Modern replacement for 'ps' ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [33] Tldr         ${INFO}- Simplified, community-driven man pages ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [34] Node.Js      ${INFO}- JavaScript Runtime environment ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [35] Gh           ${INFO}- A github-cli client ${OPTION}(Dev)${RST}"
  echo -e "${BARRIER}    ╚══════════════════════════════════════╝ ${RST}"

  echo ""
  echo -e "${BARRIER}   ╔════════════╗ ${RST}"
  echo -e "${BARRIER}   ║ ${RST}pip tools: ${BARRIER}║${RST}"
  echo -e "${BARRIER}   ╚╔═══════════╝═════════════════════════╗ ${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [01] Holehe          ${INFO}- Email OSINT scanner ${OPTION}(OSINT)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [02] Asciiquarium    ${INFO}- View of the sea ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ║${RST}${OPTION} [03] Wttr            ${INFO}- A weather tool ${OPTION}(Fun)${RST}"
  echo -e "${BARRIER}    ╚═════════════════════════════════════╝ ${RST}"

  echo ""
  echo -e "${BARRIER}   ╔══════════════════╗ ${RST}"
  echo -e "${BARRIER}   ║${RST}${OPTION} [0] Install ALL tools${RST}"
  echo -e "${BARRIER}   ║${RST}${OPTION} [p] Install by preset${RST}"
  echo -e "${BARRIER}   ║${RST}${ERROR} [e] Exit script${RST}"
  echo -e "${BARRIER}   ╚══════════════════╝ ${RST}"
  echo ""

  echo -ne "${INFO}${BOLD} [*] Choose an option: ${RST}"
  read tool_choice
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
  show_menu
  case "$tool_choice" in
  # Install commands for apt tools.
  1) install_pkg git git "Git: Version control," ;;
  2) install_pkg curl curl "Curl: File downloader 2" ;;
  3) install_pkg wget wget "Wget: File downloader" ;;
  4) install_pkg bat bat "Bat: A better cat" ;;
  5) install_pkg htop htop "Htop: Hardware use Checker" ;;
  6) install_pkg fish fish "Fish: A advanced Shell" ;;
  7) install_pkg ssh openssh "OpenSSH: Server deployment" ;;
  8) install_pkg python3 python3 "Python3: Coding language" ;;
  9) install_pkg nmap nmap "Nmap: Network scanner" ;;
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
  34) install_pkg npm nodejs "Node.Js: JavaScript Runtime environment," ;;
  35) install_pkg gh gh "Gh: Guthub-Cli" ;;
  # Install commands for pip tools
  01)
    echo ""
    ensure_pip_package "holehe" "Holehe"
    ;;
  02)
    echo ""
    ensure_pip_package "asciiquarium" "Asciiquarium"
    ;;
  03)
    echo ""
    ensure_pip_package "wttr" "Wttr"
    ;;
  0)
   # Checks for Internet before proceeding
    is_internet_up 

    # Update package lists
    echo ""
    start_spinner " [*] Updateing package list.."
    pkg_update
    stop_spinner "${OPTION}${BOLD} [✓] Package list refreshed..${RST}"
    echo ""
    sleep 0.1
    echo -e "${INFO}"
   if ask_yes_no " [!] Do you also want to upgrade the system?"; then
    echo -e "${RST}"
    start_spinner " [*] Upgrading system..."
    pkg_upgrade
    stop_spinner "${OPTION}${BOLD} [✓] System Upgrade complete..${RST}"
    else
    boxed_text center "[*] Skipping system upgrade"
   fi

    echo -e "${OPTION}$BOLD"
    boxed_text center "[*] Installing all essential tools"
    echo -e "${RST}"
    log INSTALL "User chose to install all tools"
    install_all
    echo ""
    post_install_summary
    echo -e "${OPTION}${BOLD}" 
   boxed_text center "[✓] All selected tools processed. Press enter to continue.."
    echo -e "${RST}"
    read
    ;;
  p|P|preset|Preset)
    profile_menu
    ;;
  e|E)
    graceful_exit
    ;;
  *) 
    echo -e "${ERROR}${BOLD}"
    boxed_text center "[x] Invalid input: '$tool_choice'. Please select the right option."
    echo -e "${RST}"
    sleep 2
    continue # This restarts the loop immediately
    ;;
  esac
done
