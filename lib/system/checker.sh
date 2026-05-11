#!/bin/bash

# -- checkes if a tools is installed --
check_tool() {
   local cmd=$1 # Tool name to check if its installed or not
   local name="$2" # A name to show to user
   local version
   version=$("$cmd" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+[.0-9]*' | head -n1)

  if command -v "$cmd" >/dev/null 2>&1; then
    FOUND_PKGS+=($cmd)
     echo -e "${OPTION}     [✓] $name is installed ${DIM}(v${version:--Unknown})${RST}"
   else
    NOT_FOUND_PKGS+=($cmd)
     echo -e "${ERROR}     [✗] $name is NOT installed${RST}"
  fi
}
# -- loops through ALL tools and checks each one --
check_tool_main() {
  # Reset arrays every time this runs so numbers don't stack up
  # when the user hits 'i' multiple times in one session
  FOUND_PKGS=()
  NOT_FOUND_PKGS=()

  clear
  echo -e "${OPTION}${BOLD}"
  boxed_text left "[*] Checking if any tools are installed:"
  echo -e "${RST}"
  tput civis

  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
    check_tool "$cmd" "$name"
  done

  echo ""
  local total=$(( ${#FOUND_PKGS[@]} + ${#NOT_FOUND_PKGS[@]} ))
  echo -e "${BLUE}${BOLD}"
  boxed_text_full "center" \
    " [*] ANALYSIS RESULTS" \
    "" \
    "● Total checked: $total" \
    "● Installed:     ${#FOUND_PKGS[@]}" \
    "● Not found:     ${#NOT_FOUND_PKGS[@]}"
  echo -e "${RST}"

  echo -e "${OPTION}${BOLD}"
  boxed_text center " [✓] Task complete. Press ENTER to continue"
  echo -e "${RST}"

  read -s
  tput cnorm
}
