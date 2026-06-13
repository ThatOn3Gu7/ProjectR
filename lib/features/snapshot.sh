#!/bin/bash
# shellcheck disable=all
# Filesystem snapshot hooks for rollback integration. The feature is opt-in for
# safety: set PROJECTR_ENABLE_SNAPSHOTS=1 or pass an explicit call from a future
# batch install path before structural changes.

projectr_snapshot_driver() {
  if command -v timeshift >/dev/null 2>&1; then
    echo "timeshift"
    return 0
  fi
  if command -v btrfs >/dev/null 2>&1 && findmnt -n -o FSTYPE / 2>/dev/null | grep -qx 'btrfs'; then
    echo "btrfs"
    return 0
  fi
  if command -v zfs >/dev/null 2>&1 && findmnt -n -o FSTYPE / 2>/dev/null | grep -qx 'zfs'; then
    echo "zfs"
    return 0
  fi
  echo "none"
}

projectr_state_record_snapshot() {
  local snapshot_id="$1" driver="$2" created_at="$3"
  projectr_state_init
  if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$PROJECTR_STATE_DB" "CREATE TABLE IF NOT EXISTS snapshots (id TEXT PRIMARY KEY, driver TEXT NOT NULL, created_at TEXT NOT NULL, status TEXT NOT NULL); INSERT OR REPLACE INTO snapshots(id,driver,created_at,status) VALUES($(projectr_sql_quote "$snapshot_id"),$(projectr_sql_quote "$driver"),$(projectr_sql_quote "$created_at"),'created');"
  else
    local file="$PROJECTR_STATE_DIR/snapshots.tsv"
    [[ -f "$file" ]] || printf 'id\tdriver\tcreated_at\tstatus\n' >"$file"
    printf '%s\t%s\t%s\t%s\n' "$snapshot_id" "$driver" "$created_at" "created" >>"$file"
  fi
}

projectr_snapshot_create() {
  local reason="${1:-install}"
  local driver snapshot_id created_at root_subvol parent
  driver=$(projectr_snapshot_driver)
  [[ "$driver" != "none" ]] || return 2

  created_at=$(date -u '+%Y%m%dT%H%M%SZ')
  snapshot_id="projectr_pre_install_${created_at}_${reason//[^A-Za-z0-9_.-]/_}"

  case "$driver" in
  timeshift)
    sudo timeshift --create --comments "$snapshot_id" --tags O >/dev/null 2>&1 || return 1
    ;;
  btrfs)
    root_subvol=$(findmnt -n -o SOURCE / 2>/dev/null) || return 1
    parent="/.snapshots/projectr"
    sudo mkdir -p "$parent" || return 1
    sudo btrfs subvolume snapshot -r / "$parent/$snapshot_id" >/dev/null 2>&1 || return 1
    ;;
  zfs)
    root_subvol=$(findmnt -n -o SOURCE / 2>/dev/null) || return 1
    sudo zfs snapshot "${root_subvol}@${snapshot_id}" >/dev/null 2>&1 || return 1
    ;;
  esac

  if declare -f projectr_state_record_snapshot >/dev/null 2>&1; then
    projectr_state_record_snapshot "$snapshot_id" "$driver" "$created_at" || true
  fi
  echo "$driver:$snapshot_id"
}

projectr_snapshot_pre_install() {
  local reason="${1:-install}"
  [[ "${PROJECTR_ENABLE_SNAPSHOTS:-0}" == "1" ]] || return 0
  local result status
  result=$(projectr_snapshot_create "$reason")
  status=$?
  case "$status" in
  0) log_info "Created pre-install snapshot $result" "snapshot" ;;
  2) log_warn "Snapshot requested but no supported snapshot driver was found" "snapshot" ;;
  *) log_warn "Snapshot requested but creation failed for reason=$reason" "snapshot" ;;
  esac
  return 0
}
