#!/bin/bash

# -- checkes if a tools is installed --
check_tool() {
   local cmd="$1" # Tool name to check if its installed or not
   local name="$2" # A name to show to user
   local version=""
   for _flag in --version -V --Version version; do
       version=$("$cmd" "$_flag" 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+[.0-9]*' | head -n1)
       [[ -n "$version" ]] && break
   done

  if command -v "$cmd" >/dev/null 2>&1; then
    FOUND_PKGS+=("$cmd")
     echo -e "${OPTION}     [✓] "$name" is installed ${DIM}(v${version:--Unknown})${RST}"
   else
    NOT_FOUND_PKGS+=("$cmd")
     echo -e "${ERROR}     [✗] "$name" is NOT installed${RST}"
  fi
}
# -- loops through ALL tools and checks each one --
check_all_tools() {
  # Reset arrays every time this runs so numbers don't stack up
  # when the user hits 'i' multiple times in one session
  FOUND_PKGS=()
  NOT_FOUND_PKGS=()

  clear
  echo -e "${OPTION}"
  print_box left "[*] Checking if any tools are installed:"
  echo -e "${RST}"
  safe_tput civis

  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
    check_tool "$cmd" "$name"
  done

  echo ""
  local total=$(( ${#FOUND_PKGS[@]} + ${#NOT_FOUND_PKGS[@]} ))
  echo -e "${BLUE}"
  print_titled_box --align center " [ ANALYSIS RESULTS ] " \
                                "● Total checked: $total" \
                                "● Installed:     ${#FOUND_PKGS[@]}" \
                                "● Not found:     ${#NOT_FOUND_PKGS[@]}"
  echo -e "${RST}"

  echo -e "${OPTION}"
  print_box center " [✓] Task complete."
  echo -e "${RST}"
  printf "${DIM}  [press ENTER]${RST}"
  read -s; echo
  safe_tput cnorm
}
