#!/bin/bash
# shellcheck disable=all
# Local state tracking. Uses SQLite when available and falls back to TSV.

PROJECTR_STATE_DIR="${PROJECTR_STATE_DIR:-$HOME/.local/state/projectr_v2}"
PROJECTR_STATE_DB="$PROJECTR_STATE_DIR/state.db"
PROJECTR_STATE_TSV="$PROJECTR_STATE_DIR/state.tsv"
PROJECTR_ACTIONS_TSV="$PROJECTR_STATE_DIR/actions.tsv"

projectr_state_command_exists() {
  if declare -f projectr_command_exists >/dev/null 2>&1; then
    projectr_command_exists "$1"
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

projectr_state_command_path() {
  if declare -f projectr_command_path >/dev/null 2>&1; then
    projectr_command_path "$1"
  else
    command -v "$1" 2>/dev/null
  fi
}

projectr_state_sqlite_available() {
  [[ "${PROJECTR_STATE_BACKEND:-}" == "tsv" ]] && return 1
  command -v sqlite3 >/dev/null 2>&1 || return 1
  sqlite3 -version >/dev/null 2>&1
}

projectr_state_init() {
  mkdir -p "$PROJECTR_STATE_DIR"
  if projectr_state_sqlite_available; then
    sqlite3 "$PROJECTR_STATE_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS installs (
  tool_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  package TEXT NOT NULL,
  manager TEXT NOT NULL,
  install_type TEXT NOT NULL,
  version TEXT,
  installed_at TEXT NOT NULL,
  source TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  transaction_id TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS actions (
  action_id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  tool_id TEXT NOT NULL,
  name TEXT NOT NULL,
  package TEXT NOT NULL,
  manager TEXT NOT NULL,
  install_type TEXT NOT NULL,
  command_name TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  rollback_status TEXT DEFAULT 'pending'
);
CREATE TABLE IF NOT EXISTS snapshots (
  id TEXT PRIMARY KEY,
  driver TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL
);
SQL
  else
    [[ -f "$PROJECTR_STATE_TSV" ]] || printf 'tool_id\tname\tpackage\tmanager\tinstall_type\tversion\tinstalled_at\tsource\tverification_status\ttransaction_id\n' >"$PROJECTR_STATE_TSV"
    [[ -f "$PROJECTR_ACTIONS_TSV" ]] || printf 'action_id\ttransaction_id\ttool_id\tname\tpackage\tmanager\tinstall_type\tcommand_name\tstatus\tcreated_at\trollback_status\n' >"$PROJECTR_ACTIONS_TSV"
  fi
}

projectr_sql_quote() {
  local value
  value=$(printf '%s' "$1" | sed "s/'/''/g")
  printf "'%s'" "$value"
}

projectr_tool_version() {
  local cmd="$1" version_line
  projectr_state_command_exists "$cmd" || return 0
  IFS= read -r version_line < <("$cmd" --version 2>/dev/null || true)
  version_line=${version_line//$'\t'/ }
  printf '%s\n' "${version_line:0:120}"
}

projectr_state_record_install() {
  local tool_id name package manager install_type cmd
  if [[ $# -eq 4 ]]; then
    tool_id="$1"
    name="$1"
    package="$2"
    manager="$3"
    install_type="pkg"
    cmd="$4"
  else
    tool_id="$1"
    name="$2"
    package="$3"
    manager="$4"
    install_type="$5"
    cmd="$6"
  fi
  local version now source verification transaction_id tmp
  projectr_state_init
  version=$(projectr_tool_version "$cmd")
  now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  source="${SCRIPT_DIR:-unknown}"
  verification=missing
  projectr_state_command_exists "$cmd" && verification=verified
  transaction_id="${PROJECTR_TRANSACTION_ID:-${PROJECTR_SESSION_ID:-manual}}"

  if projectr_state_sqlite_available; then
    sqlite3 "$PROJECTR_STATE_DB" "INSERT OR REPLACE INTO installs(tool_id,name,package,manager,install_type,version,installed_at,source,verification_status,transaction_id) VALUES($(projectr_sql_quote "$tool_id"),$(projectr_sql_quote "$name"),$(projectr_sql_quote "$package"),$(projectr_sql_quote "$manager"),$(projectr_sql_quote "$install_type"),$(projectr_sql_quote "$version"),$(projectr_sql_quote "$now"),$(projectr_sql_quote "$source"),$(projectr_sql_quote "$verification"),$(projectr_sql_quote "$transaction_id"));"
  else
    tmp=$(mktemp "${PROJECTR_STATE_TSV}.XXXXXX") || return 1
    awk -F '\t' -v tool_id="$tool_id" 'NR==1 || $1 != tool_id' "$PROJECTR_STATE_TSV" >"$tmp" 2>/dev/null || true
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$tool_id" "$name" "$package" "$manager" "$install_type" "$version" "$now" "$source" "$verification" "$transaction_id" >>"$tmp"
    mv "$tmp" "$PROJECTR_STATE_TSV" || {
      rm -f "$tmp"
      return 1
    }
  fi
}

projectr_state_record_action() {
  local tool_id="$1" name="$2" package="$3" manager="$4" install_type="$5" command_name="$6" status="$7"
  local action_id transaction_id now tmp
  projectr_state_init
  transaction_id="${PROJECTR_TRANSACTION_ID:-${PROJECTR_SESSION_ID:-manual}}"
  now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  action_id="${transaction_id}:${tool_id}:${now}:${status}:${RANDOM}"

  if projectr_state_sqlite_available; then
    sqlite3 "$PROJECTR_STATE_DB" "INSERT OR REPLACE INTO actions(action_id,transaction_id,tool_id,name,package,manager,install_type,command_name,status,created_at,rollback_status) VALUES($(projectr_sql_quote "$action_id"),$(projectr_sql_quote "$transaction_id"),$(projectr_sql_quote "$tool_id"),$(projectr_sql_quote "$name"),$(projectr_sql_quote "$package"),$(projectr_sql_quote "$manager"),$(projectr_sql_quote "$install_type"),$(projectr_sql_quote "$command_name"),$(projectr_sql_quote "$status"),$(projectr_sql_quote "$now"),'pending');"
  else
    tmp=$(mktemp "${PROJECTR_ACTIONS_TSV}.XXXXXX") || return 1
    cat "$PROJECTR_ACTIONS_TSV" >"$tmp" 2>/dev/null || true
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$action_id" "$transaction_id" "$tool_id" "$name" "$package" "$manager" "$install_type" "$command_name" "$status" "$now" pending >>"$tmp"
    mv "$tmp" "$PROJECTR_ACTIONS_TSV" || {
      rm -f "$tmp"
      return 1
    }
  fi
}

projectr_state_last_transaction_id() {
  projectr_state_init
  if projectr_state_sqlite_available; then
    sqlite3 "$PROJECTR_STATE_DB" 'SELECT transaction_id FROM actions ORDER BY created_at DESC LIMIT 1;' 2>/dev/null
  else
    awk -F '\t' 'NR>1 { last=$2 } END { print last }' "$PROJECTR_ACTIONS_TSV" 2>/dev/null
  fi
}

projectr_state_transaction_actions() {
  local transaction_id="$1"
  projectr_state_init
  if projectr_state_sqlite_available; then
    sqlite3 -separator $'\t' "$PROJECTR_STATE_DB" "SELECT action_id, tool_id, name, package, manager, install_type, command_name, status, rollback_status FROM actions WHERE transaction_id=$(projectr_sql_quote "$transaction_id") ORDER BY created_at DESC;" 2>/dev/null
  else
    awk -F '\t' -v tx="$transaction_id" 'NR>1 && $2==tx { print $1 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $11 }' "$PROJECTR_ACTIONS_TSV" 2>/dev/null
  fi
}

projectr_state_mark_action_status() {
  local action_id="$1" rollback_status="$2" tmp
  projectr_state_init
  if projectr_state_sqlite_available; then
    sqlite3 "$PROJECTR_STATE_DB" "UPDATE actions SET rollback_status=$(projectr_sql_quote "$rollback_status") WHERE action_id=$(projectr_sql_quote "$action_id");"
  else
    tmp=$(mktemp "${PROJECTR_ACTIONS_TSV}.XXXXXX") || return 1
    awk -F '\t' -v OFS='\t' -v id="$action_id" -v status="$rollback_status" 'NR==1 { print; next } { if ($1==id) $11=status; print }' "$PROJECTR_ACTIONS_TSV" >"$tmp" 2>/dev/null || true
    mv "$tmp" "$PROJECTR_ACTIONS_TSV" || {
      rm -f "$tmp"
      return 1
    }
  fi
}

projectr_state_records() {
  projectr_state_init
  if projectr_state_sqlite_available; then
    sqlite3 -separator $'\t' "$PROJECTR_STATE_DB" 'SELECT tool_id, name, package, manager FROM installs ORDER BY name;' 2>/dev/null
  else
    awk -F '\t' 'NR > 1 && NF >= 4 { print $1 "\t" $2 "\t" $3 "\t" $4 }' "$PROJECTR_STATE_TSV" 2>/dev/null
  fi
}

projectr_state_find_registry_entry() {
  local record_tool_id="$1" record_name="${2:-}" record_package="${3:-}" entry num cmd pkg name desc type extra cat
  if declare -f projectr_tool_lookup_entry >/dev/null 2>&1; then
    entry=$(projectr_tool_lookup_entry "$record_tool_id" 2>/dev/null || true)
    [[ -z "$entry" && -n "$record_package" ]] && entry=$(projectr_tool_lookup_entry "$record_package" 2>/dev/null || true)
    [[ -z "$entry" && -n "$record_name" ]] && entry=$(projectr_tool_lookup_entry "$record_name" 2>/dev/null || true)
    if [[ -n "$entry" ]]; then
      printf '%s\n' "$entry"
      return 0
    fi
  fi
  for entry in "${TOOLS[@]}"; do
    IFS='|' read -r num cmd pkg name desc type extra cat <<<"$entry"
    if [[ "$cmd" == "$record_tool_id" || "$name" == "$record_name" || (-n "$record_package" && "$pkg" == "$record_package") ]]; then
      printf '%s\n' "$entry"
      return 0
    fi
  done
  return 1
}

projectr_state_lookup_manager() {
  local tool_id="$1" package="${2:-}"
  projectr_state_init
  if projectr_state_sqlite_available; then
    if [[ -n "$package" ]]; then
      sqlite3 "$PROJECTR_STATE_DB" "SELECT manager FROM installs WHERE tool_id=$(projectr_sql_quote "$tool_id") OR package=$(projectr_sql_quote "$package") LIMIT 1;" 2>/dev/null
    else
      sqlite3 "$PROJECTR_STATE_DB" "SELECT manager FROM installs WHERE tool_id=$(projectr_sql_quote "$tool_id") LIMIT 1;" 2>/dev/null
    fi
  else
    awk -F '\t' -v tool_id="$tool_id" -v package="$package" 'NR>1 && ($1==tool_id || (package!="" && $3==package)) { print $4; exit }' "$PROJECTR_STATE_TSV" 2>/dev/null
  fi
}

projectr_state_remove_install() {
  local tool_id="${1:-}" name="${2:-}" package="${3:-}" tmp
  if [[ $# -eq 2 ]]; then
    package="$2"
    name="$1"
  fi
  [[ -n "$tool_id" || -n "$package" ]] || return 1
  projectr_state_init

  if projectr_state_sqlite_available; then
    if [[ -n "$tool_id" && -n "$package" ]]; then
      sqlite3 "$PROJECTR_STATE_DB" "DELETE FROM installs WHERE tool_id=$(projectr_sql_quote "$tool_id") AND package=$(projectr_sql_quote "$package");"
    elif [[ -n "$tool_id" ]]; then
      sqlite3 "$PROJECTR_STATE_DB" "DELETE FROM installs WHERE tool_id=$(projectr_sql_quote "$tool_id");"
    else
      sqlite3 "$PROJECTR_STATE_DB" "DELETE FROM installs WHERE package=$(projectr_sql_quote "$package");"
    fi
  else
    tmp=$(mktemp "${PROJECTR_STATE_TSV}.XXXXXX") || return 1
    awk -F '\t' -v tool_id="$tool_id" -v package="$package" '
            NR == 1 { print; next }
            (tool_id != "" && $1 == tool_id && (package == "" || $3 == package)) { next }
            (tool_id == "" && package != "" && $3 == package) { next }
            { print }
        ' "$PROJECTR_STATE_TSV" >"$tmp" 2>/dev/null || true
    mv "$tmp" "$PROJECTR_STATE_TSV" || {
      rm -f "$tmp"
      return 1
    }
  fi
  log_info "Removed state record for tool_id='$tool_id' package='$package'" "state"
}

projectr_state_list() {
  projectr_state_init
  if projectr_state_sqlite_available; then
    sqlite3 -header -column "$PROJECTR_STATE_DB" 'SELECT tool_id, name, package, manager, install_type, version, installed_at, verification_status FROM installs ORDER BY name;'
  else
    column -t -s $'\t' "$PROJECTR_STATE_TSV" 2>/dev/null || cat "$PROJECTR_STATE_TSV"
  fi
}

projectr_verify_state() {
  projectr_state_init
  local missing=0 checked=0 unknown=0 record record_tool_id record_name record_package record_manager entry cmd pkg name tool_id effective_cmd
  local -a records=()
  mapfile -t records < <(projectr_state_records)

  echo -e "${OPTION}[*] Verifying ProjectR-managed installations...${RST}"
  local -a installs=()
  mapfile -t installs < <(projectr_state_records)
  if [[ ${#installs[@]} -eq 0 ]]; then
    echo -e "${DIM}[*] No ProjectR-managed installations have been recorded.${RST}"
    return 0
  fi

  for record in "${records[@]}"; do
    IFS=$'\t' read -r record_tool_id record_name record_package record_manager <<<"$record"
    entry=$(projectr_state_find_registry_entry "$record_tool_id" "$record_name" "$record_package") || {
      printf '  %s %-18s %s\n' '!' "$record_name" 'not present in current registry'
      unknown=$((unknown + 1))
      continue
    }
    IFS='|' read -r _ cmd pkg name _ _ _ _ <<<"$entry"
    projectr_tool_id_into tool_id "$cmd"
    projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$record_manager"
    checked=$((checked + 1))
    if projectr_state_command_exists "$effective_cmd"; then
      printf '  %s %-18s %s\n' '✓' "$name" "$(projectr_state_command_path "$effective_cmd")"
    else
      printf '  %s %-18s %s\n' '!' "$name" "missing from PATH (package: $record_package, manager: $record_manager)"
      missing=$((missing + 1))
    fi
  done

  echo -e "${DIM}[*] Verification complete. Inspected $checked recorded tool(s); missing=$missing; unknown=$unknown.${RST}"
  [[ $missing -eq 0 && $unknown -eq 0 ]]
}

projectr_repair_state() {
  projectr_state_init
  local repaired=0 failed=0 record record_tool_id record_name record_package record_manager entry cmd pkg name type extra tool_id effective_cmd
  local -a records=()
  mapfile -t records < <(projectr_state_records)

  echo -e "${OPTION}[*] Initiating repair process for missing ProjectR-managed tools...${RST}"
  if [[ ${#records[@]} -eq 0 ]]; then
    echo -e "${DIM}[*] No recorded ProjectR-managed installations require repair.${RST}"
    return 0
  fi

  for record in "${records[@]}"; do
    IFS=$'\t' read -r record_tool_id record_name record_package record_manager <<<"$record"
    entry=$(projectr_state_find_registry_entry "$record_tool_id" "$record_name" "$record_package") || {
      echo -e "${BOLD_YELLOW:-}[!] Recorded tool '$record_name' is not in the current registry. Skipping...${RST:-}"
      failed=$((failed + 1))
      continue
    }
    IFS='|' read -r _ cmd pkg name _ type extra _ <<<"$entry"
    projectr_tool_id_into tool_id "$cmd"
    projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$record_manager"
    command -v "$effective_cmd" >/dev/null 2>&1 && continue
    PROJECTR_INSTALL_MANAGER_OVERRIDE="$record_manager" projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
    if [[ $? -eq 0 ]]; then
      repaired=$((repaired + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo -e "${OPTION}[✓] Repair operation completed for $repaired tool(s). Failed/skipped: $failed.${RST}"
  [[ $failed -eq 0 ]]
}
