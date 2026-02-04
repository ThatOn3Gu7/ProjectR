#!/bin/bash

# -- checkes if a tools is installed --
check_tool() {
   local cmd=$1 # Tool name to check if its installed or not
   local name="$2" # A name to show to user

  if command -v "$cmd" >/dev/null 2>&1; then
     echo -e "${OPT}${BOLD}   [✓] $name is installed${RST}"
    sleep 0.1
   else
     echo -e "${ERR}${BOLD}   [✗] $name is NOT installed${RST}"
    sleep 0.1
  fi
}
# -- Calls the tool checker repeatedly --
check_tool_main() {
 echo -e "${OPT}${BOLD}"
   boxed_text center " [*] Checking if any tools are installed"
 echo -e "${RST}"
 tput civis
 check_tool git "Git" 
 check_tool curl "Curl" 
 check_tool wget "Wget" 
 check_tool bat "Bat" 
 check_tool htop "Htop" 
 check_tool fish "Fish" 
 check_tool ssh "OpenSSH" 
 check_tool python3 "Python3" 
 check_tool nmap "Nmap" 
 check_tool cacademo "Libcaca" 
 check_tool speedtest-go "Speedtest-Go" 
 check_tool cpufetch "CPUfetch" 
 check_tool neofetch "Neofetch" 
 check_tool ranger "Ranger" 
 check_tool nano "Nano" 
 check_tool sl "Steam Locomotive," 
 check_tool ncdu "Ncdu" 
 check_tool nvim "Neovim" 
 check_tool cbonsai "Cbonsai" 
 check_tool asciinema "Asciinema" 
 check_tool croc "Croc" 
 check_tool fzf "Fzf" 
 check_tool zoxide "Zoxide" 
 check_tool zsh "Z shell" 
 check_tool duf "Duf" 
 check_tool tty-clock "Tty-clock" 
 check_tool pipes.sh "Pipes.sh" 
 check_tool yazi "Yazi" 
 check_tool lsd "Lsd" 
 check_tool broot "Broot" 
 check_tool dust "Dust" 
 check_tool procs "Procs" 
 check_tool tldr "Tldr" 
 check_tool gh "Gh"
 check_tool holehe "Holehe"
 check_tool asciiquarium "Asciiqurium"
 check_tool wttr "Wttr.io"
 check_tool tmux "Tmux"
 check_tool lazygit "Lazygit"           

 echo -e "${OPT}${BOLD}"
  boxed_text center " [✓] Taks complete.. press ENTER to continue"
 echo -e "${RST}"

  # Time to raed result
  read
 tput cnorm
}
