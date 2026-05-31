#!/bin/bash
# Local state tracking. Uses SQLite when available and falls back to TSV.

PROJECTR_STATE_DIR="${PROJECTR_STATE_DIR:-$HOME/.local/state/projectr}"
PROJECTR_STATE_DB="$PROJECTR_STATE_DIR/state.db"
PROJECTR_STATE_TSV="$PROJECTR_STATE_DIR/state.tsv"

projectr_state_init() {
    mkdir -p "$PROJECTR_STATE_DIR"
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 "$PROJECTR_STATE_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS installs (
  name TEXT PRIMARY KEY,
  package TEXT NOT NULL,
  manager TEXT NOT NULL,
  version TEXT,
  installed_at TEXT NOT NULL,
  source TEXT NOT NULL
);
SQL
    else
        [[ -f "$PROJECTR_STATE_TSV" ]] || printf 'name\tpackage\tmanager\tversion\tinstalled_at\tsource\n' > "$PROJECTR_STATE_TSV"
    fi
}

projectr_sql_quote() {
    local value
    value=$(printf '%s' "$1" | sed "s/'/''/g")
    printf "'%s'" "$value"
}

projectr_tool_version() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || return 0
    "$cmd" --version 2>/dev/null | head -n1 | tr '\t' ' ' | cut -c1-120 || true
}

projectr_state_record_install() {
    local name="$1" package="$2" manager="$3" cmd="$4" version now source
    projectr_state_init
    version=$(projectr_tool_version "$cmd")
    now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    source="${SCRIPT_DIR:-unknown}"

    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 "$PROJECTR_STATE_DB" "INSERT OR REPLACE INTO installs(name,package,manager,version,installed_at,source) VALUES($(projectr_sql_quote "$name"),$(projectr_sql_quote "$package"),$(projectr_sql_quote "$manager"),$(projectr_sql_quote "$version"),$(projectr_sql_quote "$now"),$(projectr_sql_quote "$source"));"
    else
        awk -F '\t' -v name="$name" 'NR==1 || $1 != name' "$PROJECTR_STATE_TSV" > "$PROJECTR_STATE_TSV.tmp" 2>/dev/null || true
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$package" "$manager" "$version" "$now" "$source" >> "$PROJECTR_STATE_TSV.tmp"
        mv "$PROJECTR_STATE_TSV.tmp" "$PROJECTR_STATE_TSV"
    fi
}

projectr_state_list() {
    projectr_state_init
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 -header -column "$PROJECTR_STATE_DB" 'SELECT name, package, manager, version, installed_at FROM installs ORDER BY name;'
    else
        column -t -s $'\t' "$PROJECTR_STATE_TSV" 2>/dev/null || cat "$PROJECTR_STATE_TSV"
    fi
}

projectr_verify_state() {
    projectr_state_init
    local missing=0
    echo -e "${OPTION}[*] Verifying ProjectR-managed tools${RST}"
    for entry in "${TOOLS[@]}"; do
        IFS='|' read -r _ cmd _ name _ _ _ _ <<< "$entry"
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '  %s %-18s %s\n' '✓' "$name" "$(command -v "$cmd")"
        else
            printf '  %s %-18s %s\n' '!' "$name" 'missing from PATH'
            missing=$((missing + 1))
        fi
    done
    [[ $missing -eq 0 ]] || return 1
}

projectr_repair_state() {
    echo -e "${OPTION}[*] Repairing missing ProjectR-managed tools${RST}"
    local repaired=0
    for entry in "${TOOLS[@]}"; do
        IFS='|' read -r _ cmd pkg name _ type extra _ <<< "$entry"
        command -v "$cmd" >/dev/null 2>&1 && continue
        case "$type" in
            pkg) install_pkg "$cmd" "$pkg" "$name" && repaired=$((repaired + 1)) ;;
            pip) install_lang pip "$pkg" "$name" "$cmd" && repaired=$((repaired + 1)) ;;
            *) echo -e "${BOLD_YELLOW}[!] $name needs a special installer; open the interactive menu.${RST}" ;;
        esac
    done
    echo -e "${OPTION}[✓] Repair attempted for $repaired tool(s).${RST}"
}
