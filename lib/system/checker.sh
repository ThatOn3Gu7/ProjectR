#!/bin/bash
# shellcheck disable=all

projectr_checker_command_exists() {
  if declare -f projectr_command_exists >/dev/null 2>&1; then
    projectr_command_exists "$1"
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

projectr_checker_tool_version() {
  # Best-effort version extraction used by the interactive inspection flow.
  # Many terminal tools support --version, but some prefer -V or "version".
  # We only read the first output line and parse the first x.y style token so
  # the inspection summary remains fast and resilient.
  local cmd="$1" flag version_line
  for flag in --version -V --Version version; do
    version_line=""
    IFS= read -r version_line < <("$cmd" "$flag" 2>&1 || true) || true
    if [[ "$version_line" =~ ([0-9]+([.][0-9]+)+) ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
      return 0
    fi
  done
  printf 'Unknown\n'
}

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
  projectr_tool_id_into tool_id "$cmd"
  projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$manager"

  if projectr_checker_command_exists "$effective_cmd"; then
    version=$(projectr_checker_tool_version "$effective_cmd")
    projectr_install_result_push found "$name"$'\t'"$effective_cmd"$'\t'"$version"
    echo -e "${OPTION}     [✓] \"$name\" is installed ${DIM}(v${version:--unknown})${RST}"
  else
    projectr_install_result_push missing "$name"$'\t'"$effective_cmd"
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

  local manager="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    check_tool "$cmd" "$name" "$manager"
  done

  echo ""
  local total=$((${#FOUND_PKGS[@]} + ${#NOT_FOUND_PKGS[@]}))
  echo -e "${BLUE}"
  print_titled_box --align center " [ Analysis Results ] " \
    "● Total checked: $total" \
    "● Installed:     ${#FOUND_PKGS[@]}" \
    "● Not found:     ${#NOT_FOUND_PKGS[@]}"
  echo -e "${RST}"

  echo -e "${OPTION}"
  print_box center "[✓] Verification process completed."
  echo -e "${RST}"
  printf "${DIM}  [press ENTER]${RST}"
  read -s
  echo
  safe_tput cnorm

  # After summary, offer to view detailed lists of installed and missing tools
  view_tool_summary
}

view_tool_summary() {

  if ! ask "  [ℹ] View tools inspection summary" "n"; then
    msg_info "Skipped summary"
    sleep 2
    return 1
  fi

  # Dynamic interactive menu using arrow keys and highlighted selection
  local options=("View installed tools" "View missing tools" "Back")
  local selected=0 # 0-based index
  local key input

  # Save cursor and hide it during menu interaction
  safe_tput civis
  trap 'safe_tput cnorm; exit' INT TERM

  # Helper: draw the menu box and options
  draw_menu() {
    clear
    echo -e "${OPTION}"
    print_box center " [*] Tool Summary Menu"
    echo -e "${RST}"

    # Print each option, highlighting the current selection
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        # Highlighted selection: invert colors or use bright background
        echo -e "  ${BLUE}${REVERSE:-}▶ ${options[$i]} ${RST}"
      else
        echo -e "  ${DIM}  ${options[$i]}${RST}"
      fi
    done

    echo -e "\n${DIM} Use  ↑/↓ : navigate • ENTER : select • b : back${RST}"
  }

  # Read a single key and handle arrow sequences
  read_key() {
    local key
    IFS= read -rsn1 key
    if [[ $key == $'\e' ]]; then
      read -rsn2 -t 0.01 key
      case "$key" in
      '[A') echo "UP" ;;
      '[B') echo "DOWN" ;;
      *) echo "OTHER" ;;
      esac
    else
      case "$key" in
      '') echo "ENTER" ;;
      b | B) echo "BACK" ;;
      *) echo "OTHER" ;;
      esac
    fi
  }

  # Main loop
  while true; do
    draw_menu
    input=$(read_key)

    case "$input" in
    UP)
      ((selected--))
      [[ $selected -lt 0 ]] && selected=$((${#options[@]} - 1))
      ;;
    DOWN)
      ((selected++))
      [[ $selected -ge ${#options[@]} ]] && selected=0
      ;;
    ENTER)
      case $selected in
      0) # View installed tools
        clear
        echo -e "${OPTION}Installed Tools:${RST}"
        if [[ ${#FOUND_PKGS[@]} -eq 0 ]]; then
          echo -e "  ${DIM}(none)${RST}"
        else
          printf "  ${BOLD_WHITE}%-22s  %-18s  %-12s${RST}\n" "Tool" "Command" "Version"
          printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 58))"
          local record display_name command_name version
          for record in "${FOUND_PKGS[@]}"; do
            IFS=$'\t' read -r display_name command_name version <<<"$record"
            # Backward compatibility for any caller that still stores only a
            # command name in FOUND_PKGS.
            if [[ -z "$command_name" ]]; then
              command_name="$display_name"
              version="unknown"
            fi
            printf "  ${BLUE}✓${RST} %-22s  %-18s  ${DIM}v%-11s${RST}\n" \
              "$display_name" "$command_name" "${version:-unknown}"
          done
        fi
        echo -e "\n${DIM}Press ENTER to continue...${RST}"
        read -s
        ;;
      1) # View missing tools
        clear
        echo -e "${OPTION}Missing Tools:${RST}"
        if [[ ${#NOT_FOUND_PKGS[@]} -eq 0 ]]; then
          echo -e "  ${DIM}(none)${RST}"
        else
          printf "  ${BOLD_WHITE}%-22s  %-18s${RST}\n" "Tool" "Expected command"
          printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 43))"
          local record display_name command_name
          for record in "${NOT_FOUND_PKGS[@]}"; do
            IFS=$'\t' read -r display_name command_name <<<"$record"
            [[ -z "$command_name" ]] && command_name="$display_name"
            printf "  ${ERROR}✖${RST} %-22s  %-18s\n" "$display_name" "$command_name"
          done
        fi
        echo -e "\n${DIM}Press ENTER to continue...${RST}"
        read -s
        ;;
      2) # Back
        break
        ;;
      esac
      ;;
    BACK)
      break
      ;;
    OTHER)
      # Ignore any other key press
      ;;
    esac
  done

  # Restore cursor when exiting the menu
  safe_tput cnorm
  trap - INT TERM
}
