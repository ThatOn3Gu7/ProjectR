#!/bin/bash
# shellcheck disable=all
# Checks if internet connection is available or not.
check_internet() {
  if command -v ping >/dev/null 2>&1; then
    ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 && return 0
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -s --max-time 5 https://www.google.com >/dev/null 2>&1 && return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -q --timeout=5 -O /dev/null https://www.google.com >/dev/null 2>&1 && return 0
  fi
  # Last resort: bash built-in TCP — works with zero external tools
  (echo >/dev/tcp/8.8.8.8/53) >/dev/null 2>&1 && return 0
  return 1
}
# startup internet Check
check_startup_connectivity() {
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
    safe_tput civis   # hide cursor
    read -rsn 1 reply # read silently, no echo
    safe_tput cnorm   # restore cursor
    case "$reply" in
    y | Y)
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
require_internet() {
  local max_attempts=3
  local attempt=1

  while ((attempt <= max_attempts)); do
    if check_internet; then
      clear
      echo -e "${OPTION}"
      print_box center "[✓] Internet connection detected. Proceeding."
      echo -e "${RST}"
      return 0
    fi

    log ERROR "No internet connection (attempt $attempt/$max_attempts)"
    echo -e "${ERROR}"
    print_box center "[!] No internet — attempt $attempt of $max_attempts"
    echo -e "${RST}"

    if ((attempt < max_attempts)); then
      echo -e "${INFO}  [*] Retrying in 5 seconds... (Ctrl+C to abort)${RST}"
      sleep 5
    fi
    ((attempt++))
  done

  echo -e "${ERROR}"
  print_box center "[!] No internet after $max_attempts attempts. Cannot continue."
  echo -e "${RST}"
  exit 1
}
