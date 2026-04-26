#!/bin/bash

# -- source all the other utilitys --
source lib/core/colors.sh
source lib/core/progress_bar.sh
source lib/core/logging.sh
source lib/core/display.sh
source lib/core/spinner.sh
source lib/core/prompts.sh
# -- system logics sourced --
source lib/system/detect.sh 
source lib/system/network.sh
source lib/system/checker.sh
source lib/system/dependencies.sh
# -- function logics sourced --
source lib/features/presets.sh
source lib/features/installer.sh
source lib/features/post_install.sh
source lib/features/neovim_setup.sh
source lib/features/zsh_setup.sh
source lib/features/upgrade.sh
source lib/features/update.sh
# -- sub_menus sourced --
source lib/sub_menus/presets.sh
source lib/sub_menus/uninstall.sh
# PM="$(detect_pkg_manager)"
trap graceful_exit SIGINT
log START "Script started"
# -- dependencies check -- 
check_dependencies_menu
# a call for startup internet check
startup_wifi_check
# -- main installer menu  --
show_main_menu() {
 # clear
  # cool LOGO with colors
  cat <<"EOF" #| lolcat

    ██▓███   ██▀███   ▒█████   ▄████▄  ▓█████   ██████     ██▀███  
   ▓██░  ██▒▓██ ▒ ██▒▒██▒  ██▒▒██▀ ▀█  ▓█   ▀ ▒██    ▒    ▓██ ▒ ██▒
   ▓██░ ██▓▒▓██ ░▄█ ▒▒██░  ██▒▒▓█    ▄ ▒███   ░ ▓██▄      ▓██ ░▄█ ▒
   ▒██▄█▓▒ ▒▒██▀▀█▄  ▒██   ██░▒▓▓▄ ▄██▒▒▓█  ▄   ▒   ██▒   ▒██▀▀█▄  
   ▒██▒ ░  ░░██▓ ▒██▒░ ████▓▒░▒ ▓███▀ ░░▒████▒▒██████▒▒   ░██▓ ▒██▒
   ▒▓▒░ ░  ░░ ▒▓ ░▒▓░░ ▒░▒░▒░ ░ ░▒ ▒  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░   ░ ▒▓ ░▒▓░
   ░▒ ░       ░▒ ░ ▒░  ░ ▒ ▒░   ░  ▒    ░ ░  ░░ ░▒  ░ ░     ░▒ ░ ▒░
   ░░         ░░   ░ ░ ░ ░ ▒  ░           ░   ░  ░  ░       ░░   ░ 
               ░         ░ ░  ░ ░         ░  ░      ░        ░     
                              ░                                    
   [--------------------------------------------------------------]
     > Purpose: Made to install tools/utilities.
     > C0ded by: ThatOn3Gu7
     > V3rsion: 1.1 | 2026-02-10
     > Status: [ Ready to install packages ]
   [--------------------------------------------------------------]
EOF

  echo -e "${OPTION}${BOLD}"
  boxed_text left "[*] Select the pkg/tool you want to install:" 

  echo -e "${BARR}   ╔═════════════════╗ ${RST}"
  echo -e "${BARR}   ║ ${RST}Available pkgs: ${BARR}║${RST}"
  echo -e "${BARR}   ╚╔════════════════╝═══════════════════╗ ${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}01${OPTION}] Git           ${INFO}- Version control ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}02${OPTION}] Curl          ${INFO}- HTTP requests ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}03${OPTION}] Wget          ${INFO}- File downloads ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}04${OPTION}] Bat           ${INFO}- 'cat' with syntax highlighting ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}05${OPTION}] Htop          ${INFO}- Process viewer ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}06${OPTION}] Fish          ${INFO}- Friendly shell ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}07${OPTION}] OpenSSH       ${INFO}- SSH access ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}08${OPTION}] Python        ${INFO}- Programming language ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}09${OPTION}] Nmap          ${INFO}- Network scanning ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}10${OPTION}] Libcaca       ${INFO}- A fire effect ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}11${OPTION}] Speedtest-go  ${INFO}- Internet speed-test ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}12${OPTION}] Cpufetch      ${INFO}- CPU information ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}13${OPTION}] Neofetch      ${INFO}- System information ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}14${OPTION}] Ranger        ${INFO}- Terminal file manager ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}15${OPTION}] Nano          ${INFO}- Text editor ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}16${OPTION}] Sl            ${INFO}- Steam Locomotive ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}17${OPTION}] Ncdu          ${INFO}- NCurses disk usage analyzer ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}18${OPTION}] Neovim        ${INFO}- Best code editor ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}19${OPTION}] Cbonsai       ${INFO}- Japanise bonsai tree ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}20${OPTION}] Asciinema     ${INFO}- Terminal recording tool ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}21${OPTION}] Croc          ${INFO}- File transferring tool ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}22${OPTION}] Fzf           ${INFO}- File finder ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}23${OPTION}] Zoxide        ${INFO}- Smarter cd command ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}24${OPTION}] Zsh           ${INFO}- Best shell ever ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}25${OPTION}] Duf           ${INFO}- Disk Usage/Free utility ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}26${OPTION}] Tty-clock     ${INFO}- A terminal clock ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}27${OPTION}] Pipes.sh      ${INFO}- A cool tool for ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}28${OPTION}] Yazi          ${INFO}- Amazing filemanager for terminal ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}29${OPTION}] Lsd           ${INFO}- An 'ls' alternative with icons/colors ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}30${OPTION}] Broot         ${INFO}- Navigate directories with overviews ${OPTION}(Min)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}31${OPTION}] Dust          ${INFO}- More intuitive version of du ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}32${OPTION}] Procs         ${INFO}- Modern replacement for 'ps' ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}33${OPTION}] Tldr          ${INFO}- Simpl, community-driven man pages ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}34${OPTION}] Node.Js       ${INFO}- JavaScript Runtime environment ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}35${OPTION}] Gh            ${INFO}- A github-cli client ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}36${OPTION}] Holehe        ${INFO}- Email OSINT scanner ${OPTION}(OSINT)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}37${OPTION}] Asciiquarium  ${INFO}- View of the sea ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}38${OPTION}] Wttr          ${INFO}- A weather tool ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}39${OPTION}] Tmux          ${INFO}- A multitasker tool ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}40${OPTION}] Lazygit       ${INFO}- An TUI for git ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}41${OPTION}] Ani-cli       ${INFO}- A terminal anime streaming tool ${OPTION}(Fun)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}42${OPTION}] Code-Server   ${INFO}- VsCode on android ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}43${OPTION}] Pipx          ${INFO}- A python-cli tool installer ${OPTION}(Dev)${RST}"
  echo -e "${BARR}    ╚═════════════════════════════════════╝ ${RST}"

echo ""

echo -e "${BARR}   ╔════════════════╗ ${RST}"
echo -e "${BARR}   ║ ${RST}Other Options: ${BARR}║${RST}"
echo -e "${BARR}   ╚╔═══════════════╝══╗ ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}0${OPTION}] Install ALL ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}p${OPTION}] Install by preset${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}i${OPTION}] Inspect installed ${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${BRIGHT_WHITE}u${OPTION}] Uninstall tools${RST}"
echo -e "${BARR}    ║${RST}${OPTION} [${ERROR}e${OPTION}] Exits the script${RST}"
echo -e "${BARR}    ╚══════════════════╝ ${RST}"
  echo -e "${OPTION}${BOLD}"
  read -p " [*] Enter the tool numbers (separate by spaces): " -a selections
  echo ""
}

while true; do
 show_main_menu
  for selected in "${selections[@]}"; do
   case $selected in
  # Install commands for apt tools.
  1) be_patient
   install_pkg git git "Git: Version control" ;;
  2) be_patient 
    install_pkg curl curl "Curl: HTTP request" ;;
  3) be_patient
    install_pkg wget wget "Wget: Command-line downloader" ;;
  4) be_patient
    install_pkg bat bat "Bat: A better cat" ;;
  5)  be_patient
    install_pkg htop htop "Htop: Hardware use Checker" ;;
  6)  be_patient
    install_pkg fish fish "Fish: A advanced Shell" ;;
  7)  be_patient
    install_pkg ssh openssh "OpenSSH: Server deployment" ;;
  8)  be_patient
    install_pkg python3 python3 "Python3: Coding language" ;;
  9)  be_patient
    install_pkg nmap nmap "Nmap: Network scanner" ;;
  10) be_patient
    install_pkg cacademo libcaca "Libcaca: Cool fire" ;;
  11) be_patient
    install_pkg speedtest-go speedtest-go "Speedtest-Go: WI-FI-speed Checker " ;;
  12) be_patient
    install_pkg cpufetch cpufetch "CPUfetch: Cpu-info" ;;
  13) be_patient
    install_pkg neofetch neofetch "Neofetch: System-info" ;;
  14) be_patient
    install_pkg ranger ranger "Ranger: Also a Filamanager" ;;
  15) be_patient
    install_pkg nano nano "Nano: Text editor" ;;
  16) be_patient
    install_pkg sl sl "Steam Locomotive" ;;
  17) be_patient
    install_pkg ncdu ncdu "Ncdu: disk use analyser" ;;
  18) be_patient
    install_neovim_full ;;
  19) be_patient
    install_pkg cbonsai cbonsai "Cbonsai: Japanise tree" ;;
  20) be_patient
    install_pkg asciinema asciinema "Asciinema: Terminal-recoder" ;;
  21) be_patient
    install_pkg croc croc "Croc: File-sender" ;;
  22) be_patient
    install_pkg fzf fzf "Fzf: Fuzzy-finder" ;;
  23) be_patient
    install_pkg zoxide zoxide "Zoxide: A better 'cd'" ;;
  24) be_patient
    install_zsh_full ;;
  25) be_patient
    install_pkg duf duf "Duf: File/dir size Checker" ;;
  26) be_patient
    install_pkg tty-clock tty-clock "Tty-clock: A terminal clock" ;;
  27) be_patient
    install_pkg pipes.sh pipes.sh "Pipes.sh: Snake" ;;
  28) be_patient
    install_pkg yazi yazi "Yazi: Filamanager" ;;
  29) be_patient
    install_pkg lsd lsd "Lsd: Batter 'ls' alternative" ;;
  30) be_patient
    install_pkg broot broot "Broot: Filenavigator" ;; 
  31) be_patient
    install_pkg dust dust "Dust: Better 'du' alternative" ;;
  32) be_patient
    install_pkg procs procs "Procs: Morden 'ps'" ;;
  33) be_patient
    install_pkg tldr tldr "Tldr: Man pages" ;;
  34) be_patient
    install_pkg npm nodejs "Node.Js: JS Runtime env" ;;
  35) be_patient
    install_pkg gh gh "Gh: Guthub-Cli" ;;
  # Install commands for pip tools
  36) be_patient
    install_pip "holehe" "Holehe" ;;
  37) be_patient
    install_pip "asciiquarium" "Asciiquarium" ;;
  38) be_patient
    install_pip "wttr" "Wttr" ;;
  39) be_patient
    install_pkg tmux tmux "Tmux: A multitasker" ;;
  40) be_patient
    install_pkg lazygit lazygit "Lazygit: A git TUI" ;;
  41) be_patient
    install_pkg ani-cli ani-cli "Ani-cli: A anime streamer" ;;
  42) be_patient
    install_pkg code-server code-server "Code-Server: VsCode on android" ;;
  43) be_patient
    install_pip pipx pipx "Pipx: A py-cli tools installer" ;;
  0) clear
    install_all
    ;;
  p|P)
    preset_menu
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
    echo -e "${ERROR}${BOLD}"
    boxed_text center "[x] Invalid input: '$selections'. Please select the right option."
    echo -e "${RST}"
    sleep 2
    continue # This restarts the loop immediately
    ;;
  esac
 done
done
