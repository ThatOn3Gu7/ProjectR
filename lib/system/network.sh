#!/bin/bash

# Checkes if internet connection is available or not. 
check_internet() {
  ping -c 1 8.8.8.8 >/dev/null 2>&1 
  curl -s --max-time 5 https://8.8.8.8 >/dev/null 2>&1 || \
  wget -q --timeout=5 -O /dev/null https://8.8.8.8 >/dev/null 2>&1
}
# startup internet Check
startup_wifi_check() {
  if ! check_internet; then
    log ERROR "No internet connection"
    echo -e "${ERROR}"
    boxed_text center "        It seems that you are not online
Please make sure to turn on WI-FI to continue :)"
    echo -e "${OPTION}"
    boxed_text center " [!] Continue Anyways? [y/N]"
    echo -e "${RST}"
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
      log ERROR "No internet connection"
      echo ""
      echo -e "${ERROR}"
      boxed_text center "[!] No internet connection detected. Did you lose it?"
      echo -e "${OPTION}"
      boxed_text center "[*] Please have stable internet connection to continue ;)"
      echo -e "${RST}" 
      exit 0
    else
      clear
      echo -e "${OPTION}"
       boxed_text center "[✓] Internet connection detected. Proceeding."
      echo -e ${RST}
    fi
}
