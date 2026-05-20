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
  # ONE-TIME: already said continue without WiFi
    if [ "$(config_get 'skip_wifi_check')" = "true" ]; then
        return 0
    fi
    log ERROR "No internet connection"
    echo -e "${ERROR}"
    print_box center "        It seems that you are not online
Please make sure to turn on WI-FI to continue :)"
    echo -e "${OPTION}"
    print_box center " [!] Continue Anyways? [y/N]"
    echo -e "${RST}"
    safe_tput civis        # hide cursor
    read -rsn 1 reply    # read silently, no echo
    safe_tput cnorm        # restore cursor
  case "$reply" in
    y|Y) 
     if ask " [*] Are you sure? Preferences will be saved.." "n"; then
       config_set "skip_wifi_check" "true"
        echo -e "${OPTION} [*] You won't be prompted next time when you're offline ${RST}"
         sleep 3 
      else
       log ENTER "User still continued"
        clear
      fi 
      ;;
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
      print_box center "[!] No internet connection detected. Did you lose it?"
      echo -e "${OPTION}"
      print_box center "[*] Please have stable internet connection to continue ;)"
      echo -e "${RST}" 
      exit 0
    else
      clear
      echo -e "${OPTION}"
       print_box center "[✓] Internet connection detected. Proceeding."
      echo -e ${RST}
    fi
}
