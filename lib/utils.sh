#!/bin/bash
# -- log creation --
LOG_FILE="$HOME/ProjectR/log/logs.log"

# -- Small message for installer --
be_patient() {
  clear 
   echo -e "${OPT}${BOLD}"
    boxed_text center "[*] Installation may take a while, Please be patient"
   echo -e "${INFO}${BOLD}"
}

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
# just a simple log function 
log() {
    local level="$1"
    local message="$2"

    echo "[$(date '+%H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}
# startup internet Check
startup_wifi_check() {
  if ! check_internet; then
    log ERR "No internet connection"
    echo -e "${ERR}${BOLD}"
    boxed_text center "        It seems that you are not onlile
Please make sure to turn on WI-FI to continue :)"
    echo -e "${OPT}${BOLD}"
    boxed_text center " [!] Still continue? [y/N]"
    tput civis        # hide cursor
    read -rsn 1 reply    # read silently, no echo
    tput cnorm        # restore cursor
  case "$reply" in
    y|Y) log ENTER "User still continued"
      clear ;;
    *) exit 0 ;;
  esac
  fi
}

# internet connection detection
is_internet_up() {
    # Check for internet connection
    if ! check_internet; then
      log ERR "No internet connection"
      echo ""
      echo -e "${ERR}${BOLD}"
      boxed_text center "[!] No internet connection detected. Did you lose it?"
      echo -e "${OPT}${BOLD}"
      boxed_text center "[*] Please have stable internet connection to continue ;)"
      echo -e "${RST}" 
      exit 0
    else
      clear
      echo -e "${OPT}${BOLD}"
       boxed_text center "[✓] Internet connection detected. Proceeding."
      echo -e ${RST}
    fi
}
# post-install summary pop-up
post_install_summary() {
    log OK "Post-Installation-Summary shown"
    echo ""
    echo -e "${OPT}${BOLD}"
    boxed_text center " [*] Post-Installation Summary" 
    echo -e "${RST}"

    if [ ${#INSTALLED_PKGS[@]} -gt 0 ]; then
        echo -e "${SUCCESS}${BOLD}Installed:${RST}"
        for pkg in "${INSTALLED_PKGS[@]}"; do
            echo " [ ✓ ] $pkg"
        done
        echo ""
    fi

    if [ ${#SKIPPED_PKGS[@]} -gt 0 ]; then
        echo -e "${OPT}${BOLD}Skipped:${RST}"
        for pkg in "${SKIPPED_PKGS[@]}"; do
            echo " [ → ] $pkg"
        done
        echo ""
    fi

    if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
        echo -e "${ERR}${BOLD}Failed:${RST}"
        for pkg in "${FAILED_PKGS[@]}"; do
            echo " [ ✗ ] $pkg"
        done
        echo ""
    fi
}
# Print a boxed message centered in the terminal
boxed_text() {
    local align="$1"
    shift
    local text="$*"

    # Get terminal width
    local term_width
    term_width=$(tput cols)

    # Split text into lines
    IFS=$'\n' read -rd '' -a lines <<< "$text"

    # Find longest line length
    local max_len=0
    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done

    # Box padding
    local padding=2
    local box_width=$(( max_len + padding * 2 ))

    # Calculate alignment offset
    local offset=0
    case "$align" in
        center)
            offset=$(( (term_width - box_width - 2) / 2 ))
            ;;
        right)
            offset=$(( term_width - box_width - 2 ))
            ;;
        left|*)
            offset=0
            ;;
    esac

    (( offset < 0 )) && offset=0

    local indent
    indent=$(printf '%*s' "$offset")

    # Top border
    echo "${indent}┌$(printf '─%.0s' $(seq 1 $box_width))┐"

    # Text lines
    for line in "${lines[@]}"; do
        printf "%s│%*s%s%*s│\n" \
            "$indent" \
            "$padding" "" \
            "$line" \
            "$(( box_width - ${#line} - padding ))" ""
    done

    # Bottom border
    echo "${indent}└$(printf '─%.0s' $(seq 1 $box_width))┘"
}
# Start a spinner in the background
# $1 -> message to display alongside the spinner
start_spinner() {
    local message="$1"
    local spin_chars="|/-\\"
    local i=0

     # Don't start if already running
     if [ -n "$SPINNER_PID" ]; then
         return 0
     fi

    # Hide cursor
    tput civis 2>/dev/null

    # Run spinner in background
    (
        while :; do
            printf "\r%s %s" "$message" "${spin_chars:i++%${#spin_chars}:1}"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}
# Stop the spinner
stop_spinner() {
    # This stops the background spinner
    kill "$SPINNER_PID" >/dev/null 2>&1
    wait "$SPINNER_PID" 2>/dev/null

    # Clear the entire line
    printf "\r\033[2K"

    # Show cursor again
    tput cnorm 2>/dev/null
    unset SPINNER_PID
    echo -e "$1"
}
# This function asks the user to choose [y/N]
ask_yes_no() {
    local prompt="$1"
    local reply

    read -rp "$prompt [y/N]: " reply
    case "$reply" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}
# Updates package list based on detected package manager
pkg_update() {
  log OK "pkg list updated"
   PM="$(detect_pkg_manager)"
    case "$PM" in
        apt)
             apt update -y >/dev/null 2>&1
            ;;
        dnf)
            sudo dnf makecache >/dev/null 2>&1
            ;;
        yum)
            sudo yum makecache >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -Sy --noconfirm
            ;;
        zypper)
            sudo zypper refresh >/dev/null 2>&1
            ;;
        apk)
            sudo apk update >/dev/null 2>&1
            ;;
        brew)
            brew update >/dev/null 2>&1
            ;;
        pkg) # Termux
            pkg update -y >/dev/null 2>&1
            ;;
        nix)
            nix-channel --update >/dev/null 2>&1
            ;;
        flatpak)
            flatpak update --appstream >/dev/null 2>&1
            ;;
        snap)
            snap refresh --list >/dev/null 2>&1 || true
            ;;
        winget)
            winget source update >/dev/null 2>&1
            ;;
        scoop)
            scoop update >/dev/null 2>&1
            ;;
        *)
          echo -e "${ERR}${BOLD}"
          boxed_text center " [!] No supported package manager found, So package list not updated"
          echo -e "${RST}"
          stop_spinner
            return 1
            ;;
    esac
}

# Upgrades system based on detected package manager.
pkg_upgrade() {
  log OK "pkg/system upgraded"
   PM="$(detect_pkg_manager)"
    case "$PM" in
        apt)  apt upgrade -y >/dev/null 2>&1 ;;
        dnf) sudo dnf upgrade -y >/dev/null 2>&1 ;;
        yum) sudo yum upgrade -y >/dev/null 2>&1 ;;
        pacman) pacman -Su --noconfirm ;;
        brew) brew upgrade >/dev/null 2>&1 ;;
        pkg) pkg upgrade -y >/dev/null 2>&1 ;;
        *)
          echo -e "${ERR}${BOLD}"
          boxed_text center "[!] System upgrade not supported for: $PM..${RST}"
          echo -e "${RST}"
          stop_spinner  
            return 1
            ;;
    esac
}

# Prints a message whenever user decides to exit the script.
graceful_exit() {
  log EXIT "Exited script"
   echo ""
    echo -e "${INFO}${BOLD}"
    boxed_text center " Thanks for using the script
     See you next time "
    echo -e "${RST}"
    exit 0
}
