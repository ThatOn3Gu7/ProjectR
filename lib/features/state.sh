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
    local name="$1" package="$2" manager="$3" cmd="$4" version now source tmp
    projectr_state_init
    version=$(projectr_tool_version "$cmd")
    now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    source="${SCRIPT_DIR:-unknown}"

    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 "$PROJECTR_STATE_DB" "INSERT OR REPLACE INTO installs(name,package,manager,version,installed_at,source) VALUES($(projectr_sql_quote "$name"),$(projectr_sql_quote "$package"),$(projectr_sql_quote "$manager"),$(projectr_sql_quote "$version"),$(projectr_sql_quote "$now"),$(projectr_sql_quote "$source"));"
    else
        tmp=$(mktemp "${PROJECTR_STATE_TSV}.XXXXXX") || return 1
        awk -F '\t' -v name="$name" 'NR==1 || $1 != name' "$PROJECTR_STATE_TSV" > "$tmp" 2>/dev/null || true
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$package" "$manager" "$version" "$now" "$source" >> "$tmp"
        mv "$tmp" "$PROJECTR_STATE_TSV" || { rm -f "$tmp"; return 1; }
    fi
}

projectr_state_records() {
    projectr_state_init
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 -separator $'\t' "$PROJECTR_STATE_DB" 'SELECT name, package, manager FROM installs ORDER BY name;' 2>/dev/null
    else
        awk -F '\t' 'NR > 1 && NF >= 3 { print $1 "\t" $2 "\t" $3 }' "$PROJECTR_STATE_TSV" 2>/dev/null
    fi
}

projectr_state_find_registry_entry() {
    local record_name="$1" record_package="${2:-}" entry num cmd pkg name desc type extra cat
    for entry in "${TOOLS[@]}"; do
        IFS='|' read -r num cmd pkg name desc type extra cat <<< "$entry"
        if [[ "$name" == "$record_name" || ( -n "$record_package" && "$pkg" == "$record_package" ) ]]; then
            printf '%s\n' "$entry"
            return 0
        fi
    done
    return 1
}


projectr_state_remove_install() {
    local name="${1:-}" package="${2:-}" tmp
    [[ -n "$name" || -n "$package" ]] || return 1
    projectr_state_init

    if command -v sqlite3 >/dev/null 2>&1; then
        if [[ -n "$name" && -n "$package" ]]; then
            sqlite3 "$PROJECTR_STATE_DB" "DELETE FROM installs WHERE name=$(projectr_sql_quote "$name") OR package=$(projectr_sql_quote "$package");"
        elif [[ -n "$name" ]]; then
            sqlite3 "$PROJECTR_STATE_DB" "DELETE FROM installs WHERE name=$(projectr_sql_quote "$name");"
        else
            sqlite3 "$PROJECTR_STATE_DB" "DELETE FROM installs WHERE package=$(projectr_sql_quote "$package");"
        fi
    else
        tmp=$(mktemp "${PROJECTR_STATE_TSV}.XXXXXX") || return 1
        awk -F '	' -v name="$name" -v package="$package" '
            NR == 1 { print; next }
            (name != "" && $1 == name) { next }
            (package != "" && $2 == package) { next }
            { print }
        ' "$PROJECTR_STATE_TSV" > "$tmp" 2>/dev/null || true
        mv "$tmp" "$PROJECTR_STATE_TSV" || { rm -f "$tmp"; return 1; }
    fi
    log_info "Removed state record for name='$name' package='$package'" "state"
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
    local missing=0 checked=0 unknown=0 record record_name record_package record_manager entry cmd pkg name
    local -a records=()
    mapfile -t records < <(projectr_state_records)

    echo -e "${OPTION}[*] Verifying ProjectR-managed tools${RST}"
    if [[ ${#records[@]} -eq 0 ]]; then
        echo -e "${DIM}[*] No ProjectR-managed installs have been recorded yet.${RST}"
        return 0
    fi

    for record in "${records[@]}"; do
        IFS=$'\t' read -r record_name record_package record_manager <<< "$record"
        entry=$(projectr_state_find_registry_entry "$record_name" "$record_package") || {
            printf '  %s %-18s %s\n' '!' "$record_name" 'not present in current registry'
            unknown=$((unknown + 1))
            continue
        }
        IFS='|' read -r _ cmd pkg name _ _ _ _ <<< "$entry"
        checked=$((checked + 1))
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '  %s %-18s %s\n' '✓' "$name" "$(command -v "$cmd")"
        else
            printf '  %s %-18s %s\n' '!' "$name" "missing from PATH (package: $pkg, manager: $record_manager)"
            missing=$((missing + 1))
        fi
    done

    echo -e "${DIM}[*] Checked $checked recorded tool(s); missing=$missing; unknown=$unknown.${RST}"
    [[ $missing -eq 0 && $unknown -eq 0 ]]
}

projectr_repair_state() {
    projectr_state_init
    local repaired=0 failed=0 record record_name record_package record_manager entry cmd pkg name type extra
    local -a records=()
    mapfile -t records < <(projectr_state_records)

    echo -e "${OPTION}[*] Repairing missing ProjectR-managed tools${RST}"
    if [[ ${#records[@]} -eq 0 ]]; then
        echo -e "${DIM}[*] No recorded ProjectR-managed installs to repair.${RST}"
        return 0
    fi

    for record in "${records[@]}"; do
        IFS=$'\t' read -r record_name record_package record_manager <<< "$record"
        entry=$(projectr_state_find_registry_entry "$record_name" "$record_package") || {
            echo -e "${BOLD_YELLOW:-}[!] Recorded tool '$record_name' is not in the current registry — skipping.${RST:-}"
            failed=$((failed + 1))
            continue
        }
        IFS='|' read -r _ cmd pkg name _ type extra _ <<< "$entry"
        command -v "$cmd" >/dev/null 2>&1 && continue
        if projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"; then
            repaired=$((repaired + 1))
        else
            failed=$((failed + 1))
        fi
    done

    echo -e "${OPTION}[✓] Repair attempted for $repaired tool(s); failed/skipped unknown: $failed.${RST}"
    [[ $failed -eq 0 ]]
}
