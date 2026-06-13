#!/bin/bash
# shellcheck disable=all
# Tool registry audit helpers. These checks keep lib/data/tools.sh from growing
# broken entries as the ProjectR database expands.

projectr_audit_tools() {
  local strict=0 arg
  for arg in "$@"; do
    case "$arg" in
    --strict) strict=1 ;;
    --no-color) projectr_disable_color ;;
    esac
  done

  local errors=0 warnings=0 total=0
  local nums=" " cmds=" " names=" "
  echo ""
  echo -e "${OPTION}[*] Commencing audit of the ProjectR tool database...${RST}"
  log_info "Starting tool database audit strict=$strict" "audit"

  for entry in "${TOOLS[@]}"; do
    total=$((total + 1))
    local num cmd pkg name desc type extra cat rest
    IFS='|' read -r num cmd pkg name desc type extra cat rest <<<"$entry"

    if [[ -n "${rest:-}" ]]; then
      echo -e "${ERROR}[x] Entry #${num:-?} has too many fields.${RST}"
      log_error "Tool audit: entry #${num:-?} has too many fields" "audit"
      errors=$((errors + 1))
    fi

    if [[ -z "$num" || -z "$cmd" || -z "$pkg" || -z "$name" || -z "$desc" || -z "$type" || -z "$extra" || -z "$cat" ]]; then
      echo -e "${ERROR}[x] Entry #${num:-?} has blank required fields.${RST}"
      log_error "Tool audit: entry #${num:-?} has blank required fields" "audit"
      errors=$((errors + 1))
    fi

    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo -e "${ERROR}[x] Entry '$name' has non-numeric id: $num${RST}"
      log_error "Tool audit: entry '$name' has non-numeric id '$num'" "audit"
      errors=$((errors + 1))
    elif [[ "$nums" == *" $num "* ]]; then
      echo -e "${ERROR}[x] Duplicate tool id: $num ($name).${RST}"
      log_error "Tool audit: duplicate id $num for $name" "audit"
      errors=$((errors + 1))
    else
      nums+="$num "
    fi

    if [[ "$cmds" == *" ${cmd,,} "* ]]; then
      echo -e "${BOLD_YELLOW}[!] Duplicate command key: $cmd ($name).${RST}"
      log_warn "Tool audit: duplicate command key $cmd for $name" "audit"
      warnings=$((warnings + 1))
    else
      cmds+="${cmd,,} "
    fi

    if [[ "$names" == *" ${name,,} "* ]]; then
      echo -e "${BOLD_YELLOW}[!] Duplicate display name: $name.${RST}"
      log_warn "Tool audit: duplicate display name $name" "audit"
      warnings=$((warnings + 1))
    else
      names+="${name,,} "
    fi

    case "$type" in
    pkg | pip | pip3 | pipx | cargo | gem | npm | yarn | pnpm | bun | go | composer | special) ;;
    *)
      echo -e "${ERROR}[x] $name has unsupported type '$type'.${RST}"
      log_error "Tool audit: $name has unsupported type '$type'" "audit"
      errors=$((errors + 1))
      ;;
    esac

    if [[ "$type" == "special" ]]; then
      if [[ "$extra" == "-" || -z "$extra" ]]; then
        echo -e "${ERROR}[x] $name is special but has no installer function in extra.${RST}"
        log_error "Tool audit: $name special entry missing installer function" "audit"
        errors=$((errors + 1))
      elif ! declare -f "$extra" >/dev/null 2>&1; then
        echo -e "${ERROR}[x] $name references missing special installer '$extra'.${RST}"
        log_error "Tool audit: $name references missing installer '$extra'" "audit"
        errors=$((errors + 1))
      fi
    elif [[ "$extra" != "-" ]]; then
      echo -e "${BOLD_YELLOW}[!] $name has unused extra field '$extra' for type '$type'.${RST}"
      log_warn "Tool audit: $name has unused extra '$extra' for type '$type'" "audit"
      warnings=$((warnings + 1))
    fi
  done

  echo -e "${INFO}[*] Inspection complete. Audited ${BOLD_WHITE}$total${RST}${INFO} tool entries.${RST}"
  echo -e "${INFO}[*] Audit results: ${BOLD_WHITE}$errors${RST}${INFO} error(s), ${BOLD_WHITE}$warnings${RST}${INFO} warning(s).${RST}"

  if ((errors > 0 || (strict && warnings > 0))); then
    log_fail "Tool database audit failed: errors=$errors warnings=$warnings strict=$strict" "audit"
    return 1
  fi

  echo -e "${OPTION}[✓] Tool database audit completed successfully.${RST}"
  log_ok "Tool database audit passed: total=$total warnings=$warnings strict=$strict" "audit"
}
