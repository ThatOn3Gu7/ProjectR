#!/usr/bin/env bash
# shellcheck disable=all

projectr_profile_command_exists() {
  if declare -f projectr_command_exists >/dev/null 2>&1; then
    projectr_command_exists "$1"
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

export_profile() {
  if [[ ${#TOOLS[@]} -eq 0 ]]; then
    echo -e "${ERROR} [✗] The tools registry is empty. Export operation aborted.${RST}"
    return 1
  fi

  local backup_file="projectr_profile_$(date +%F).txt"

  if ! touch "$backup_file" 2>/dev/null; then
    echo -e "${ERROR} [✗] Write permissions denied for the current directory: $(pwd)${RST}"
    return 1
  fi
  rm -f "$backup_file"
  echo -e "${INFO} [*] Scanning system for installed ProjectR packages...${RST}"
  if ! touch "$backup_file" 2>/dev/null; then
    echo -e "${ERROR} [✗] Unable to create the profile configuration file: $backup_file${RST}"
    return 1
  fi

  local count=0 tool_id effective_cmd manager
  manager="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    projectr_tool_id_into tool_id "$cmd"
    projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$manager"
    if projectr_profile_command_exists "$effective_cmd"; then
      echo "$cmd" >>"$backup_file"
      ((count++))
    fi
  done

  if [[ $count -eq 0 ]]; then
    echo -e "${BOLD_YELLOW} [!] No tools are currently installed. Profile generation skipped.${RST}"
    rm -f "$backup_file"
    return 0
  fi

  echo -e "${BOLD_GREEN} [✓] Profile configuration exported successfully ($count tools recorded).${RST}"
  echo -e "${OPTION} [→] Saved path: ${BOLD_WHITE}$backup_file${RST}"
}

export_profile_lock() {
  local lock_file="projectr_lock_$(date +%F).yml"
  local wrote=0 record tool_id name package manager entry cmd pkg display type extra cat effective_cmd version
  local -a records=()
  mapfile -t records < <(projectr_state_records)

  if [[ ${#records[@]} -eq 0 ]]; then
    echo -e "${BOLD_YELLOW} [!] No recorded ProjectR-managed tools found to export as a lockfile.${RST}"
    return 1
  fi

  projectr_profile_generate_lockfile >"$lock_file" || return 1
  echo -e "${BOLD_GREEN} [✓] Lockfile exported successfully.${RST}"
  echo -e "${OPTION} [→] Saved path: ${BOLD_WHITE}$lock_file${RST}"
}

import_profile() {
  local file="$1"

  [[ -z "$file" ]] && {
    echo -e "${ERROR} [✗] No profile file specified for import.${RST}"
    return 1
  }
  [[ ! -f "$file" ]] && {
    echo -e "${ERROR} [✗] Profile configuration file not found: $file${RST}"
    return 1
  }
  [[ ! -r "$file" ]] && {
    echo -e "${ERROR} [✗] Profile configuration file is not readable: $file${RST}"
    return 1
  }

  case "$file" in
  *.yml | *.yaml | *.toml)
    projectr_install_profile "$file"
    return $?
    ;;
  esac

  echo -e "${INFO} [*] Parsing environment profile: $file...${RST}"

  local tools_to_install=()
  local line_num=0 skipped=0

  while read -r target_cmd || [[ -n "$target_cmd" ]]; do
    ((line_num++))
    if [[ -z "$target_cmd" ]]; then
      echo -e "${BOLD_YELLOW} [!] Line $line_num: Invalid entry '$target_cmd' skipped.${RST}"
      ((skipped++))
      continue
    fi

    local matched=0
    entry=$(projectr_tool_lookup_cmd_entry "$target_cmd" 2>/dev/null || true)
    if [[ -n "$entry" ]]; then
      matched=1
      IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
      command -v "$cmd" >/dev/null 2>&1 || tools_to_install+=("$entry")
    fi

    if [[ $matched -eq 0 ]]; then
      echo -e "${BOLD_YELLOW} [!] Line $line_num: '$target_cmd' is not present in the tool registry. Entry skipped.${RST}"
      ((skipped++))
      continue
    fi
  done <"$file"

  [[ $skipped -gt 0 ]] && echo -e "${BOLD_YELLOW} [!] $skipped line(s) skipped due to being unknown or invalid.${RST}"

  if [[ ${#tools_to_install[@]} -eq 0 ]]; then
    echo -e "${BOLD_GREEN} [✓] All tools specified in the profile are already installed.${RST}"
    return 0
  fi

  echo -e "${OPTION} [*] Identified ${#tools_to_install[@]} missing tools. Commencing installation...${RST}"
  local failed=0
  for entry in "${tools_to_install[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra" || ((failed++))
  done

  [[ $failed -gt 0 ]] && echo -e "${ERROR} [!] $failed tool(s) failed to install successfully.${RST}" && return 1
  return 0
}
