#!/bin/bash
# shellcheck disable=all

check_tool() {
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
     echo -e "${OPTION}     [✓] \"$name\" is installed ${DIM}(v${version:--Unknown})${RST}"
   else
    projectr_install_result_push missing "$effective_cmd"
     echo -e "${ERROR}     [✗] \"$name\" is NOT installed${RST}"
  fi
}

check_all_tools() {
  local -a FOUND_PKGS=()
  local -a NOT_FOUND_PKGS=()

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
