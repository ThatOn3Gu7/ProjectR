#!/bin/bash
# shellcheck disable=all

check_tool() {
   # Determine if a tool is available and record its status
   # "$cmd" – the command to test
   # "$name" – friendly name for display
   # "$manager" – package manager (unused here but kept for compatibility)
   # Return: prints status and populates global arrays FOUND_PKGS / NOT_FOUND_PKGS

   local cmd="$1"
   local name="$2"
   local manager="${3:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}"
   local tool_id effective_cmd version=""
   tool_id=$(projectr_tool_id "$cmd")
   effective_cmd=$(projectr_effective_cmd "$tool_id" "$cmd" "$manager")

  if command -v "$effective_cmd" >/dev/null 2>&1; then
    local _flag
    for _flag in --version -V --Version version; do
       version=$("$effective_cmd" "$_flag" 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+[.0-9]*' | head -n1)
       [[ -n "$version" ]] && break
    done
    projectr_install_result_push found "$effective_cmd"
     echo -e "${OPTION}     [✓] \"$name\" is installed ${DIM}(v${version:--unknown})${RST}"
   else
    projectr_install_result_push missing "$effective_cmd"
     echo -e "${ERROR}     [✗] \"$name\" is not installed${RST}"
  fi
}

check_all_tools() {
  FOUND_PKGS=()
  NOT_FOUND_PKGS=()

  clear
  echo -e "${OPTION}"
  print_box left "[*] Verification of installed tools in progress:"
  echo -e "${RST}"
  safe_tput civis

  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
    check_tool "$cmd" "$name"
  done

  echo ""
  local total=$(( ${#FOUND_PKGS[@]} + ${#NOT_FOUND_PKGS[@]} ))
  echo -e "${BLUE}"
  print_titled_box --align center "Analysis Results" \
                                "● Total checked: $total" \
                                "● Installed:     ${#FOUND_PKGS[@]}" \
                                "● Not found:     ${#NOT_FOUND_PKGS[@]}"
  echo -e "${RST}"

  echo -e "${OPTION}"
  print_box center "[✓] Verification process completed."
  echo -e "${RST}"
  printf "${DIM}  [press ENTER]${RST}"
  read -s; echo
  safe_tput cnorm

  # After summary, offer to view detailed lists of installed and missing tools
  view_tool_summary
}

view_tool_summary() {
  while true; do
    echo -e "${OPTION}"
    print_box left "[?] Choose an option:"
    echo -e "${RST}"
    echo -e " ${OPTION}[1] View installed tools"
    echo -e " ${OPTION}[2] View missing tools"
    echo -e " ${OPTION}[b] Back"
    read -p "Select: " opt
    case "$opt" in
      1)
        clear
        echo -e "${OPTION}Installed Tools:${RST}"
        for tool in "${FOUND_PKGS[@]}"; do
          echo "  $tool"
        done
        echo
        read -p "Press ENTER to continue..." dummy
        ;;
      2)
        clear
        echo -e "${OPTION}Missing Tools:${RST}"
        for tool in "${NOT_FOUND_PKGS[@]}"; do
          echo "  $tool"
        done
        echo
        read -p "Press ENTER to continue..." dummy
        ;;
      b|B)
        break
        ;;
      *)
        echo -e "${ERROR}Invalid selection.${RST}"
        ;;
    esac
  done
}
