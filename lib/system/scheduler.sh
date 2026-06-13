#!/usr/bin/env bash
# shellcheck disable=all
# Background update scheduler with explicit status/enable/disable operations.

PROJECTR_SCHEDULER_ALERT_FILE="${PROJECTR_SCHEDULER_ALERT_FILE:-${HOME}/.config/projectr_v2/.update_alert}"
PROJECTR_SCHEDULER_CRON_TAG="# projectr-scheduler"

projectr_scheduler_show_alert() {
  if [[ -f "$PROJECTR_SCHEDULER_ALERT_FILE" ]]; then
    echo -e "${BOLD_YELLOW:-} 🔔 [NOTIFICATION] ProjectR found package updates available.${RST:-}"
    echo -e "${DIM:-}    Run 'project upgrade' or your preferred package manager.${RST:-}\n"
    rm -f "$PROJECTR_SCHEDULER_ALERT_FILE"
  fi
}

projectr_updates_available() {
  local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
  case "$pm" in
  apt | apt-get) apt list --upgradable 2>/dev/null | awk 'NR>1{found=1} END{exit found?0:1}' ;;
  pacman) pacman -Qu >/dev/null 2>&1 ;;
  dnf | yum)
    "$pm" check-update >/dev/null 2>&1
    [[ $? -eq 100 ]]
    ;;
  brew) brew outdated >/dev/null 2>&1 ;;
  flatpak) flatpak remote-ls --updates >/dev/null 2>&1 ;;
  snap) snap refresh --list 2>/dev/null | awk 'NR>1{found=1} END{exit found?0:1}' ;;
  *) return 1 ;;
  esac
}

projectr_scheduler_run_check() {
  mkdir -p "$(dirname "$PROJECTR_SCHEDULER_ALERT_FILE")"
  if projectr_updates_available; then
    printf '1\n' >"$PROJECTR_SCHEDULER_ALERT_FILE"
    echo "updates-available"
    return 0
  fi
  rm -f "$PROJECTR_SCHEDULER_ALERT_FILE"
  echo "up-to-date"
  return 1
}

projectr_scheduler_cron_line() {
  local launcher="${PROJECTR_SCHEDULER_LAUNCHER:-${PROJECTR_LAUNCHER_NAME:-project}}"
  if command -v "$launcher" >/dev/null 2>&1; then
    printf '0 9 * * * %s scheduler run-check --quiet %s\n' "$launcher" "$PROJECTR_SCHEDULER_CRON_TAG"
  else
    printf '0 9 * * * /bin/bash %q/main.sh scheduler run-check --quiet %s\n' "$SCRIPT_DIR" "$PROJECTR_SCHEDULER_CRON_TAG"
  fi
}

projectr_scheduler_status() {
  local found=0
  if command -v systemctl >/dev/null 2>&1 && systemctl --user status projectr-update.timer >/dev/null 2>&1; then
    echo "systemd-user: enabled"
    found=1
  fi
  if command -v crontab >/dev/null 2>&1 && crontab -l 2>/dev/null | grep -Fq "$PROJECTR_SCHEDULER_CRON_TAG"; then
    echo "cron: enabled"
    found=1
  fi
  [[ -f "$PROJECTR_SCHEDULER_ALERT_FILE" ]] && echo "alert-cache: pending"
  ((found == 0)) && echo "disabled"
}

projectr_scheduler_enable() {
  if command -v systemctl >/dev/null 2>&1; then
    local user_dir="${HOME}/.config/systemd/user"
    mkdir -p "$user_dir"
    cat >"$user_dir/projectr-update.service" <<EOF
[Unit]
Description=ProjectR update availability check

[Service]
Type=oneshot
ExecStart=/bin/bash ${SCRIPT_DIR}/main.sh scheduler run-check --quiet
EOF
    cat >"$user_dir/projectr-update.timer" <<EOF
[Unit]
Description=Run ProjectR update check daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    systemctl --user enable --now projectr-update.timer >/dev/null 2>&1 || true
    echo "systemd-user enabled"
    return 0
  fi

  if command -v crontab >/dev/null 2>&1; then
    local tmp
    tmp=$(mktemp) || return 1
    {
      crontab -l 2>/dev/null | grep -Fv "$PROJECTR_SCHEDULER_CRON_TAG"
      projectr_scheduler_cron_line
    } >"$tmp"
    crontab "$tmp"
    rm -f "$tmp"
    echo "cron enabled"
    return 0
  fi

  echo -e "${ERROR:-}[!] No supported scheduler backend found (systemd --user or crontab).${RST:-}" >&2
  return 1
}

projectr_scheduler_disable() {
  local rc=1
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now projectr-update.timer >/dev/null 2>&1 || true
    rm -f "${HOME}/.config/systemd/user/projectr-update.service" "${HOME}/.config/systemd/user/projectr-update.timer"
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    rc=0
  fi
  if command -v crontab >/dev/null 2>&1; then
    local tmp
    tmp=$(mktemp) || return 1
    crontab -l 2>/dev/null | grep -Fv "$PROJECTR_SCHEDULER_CRON_TAG" >"$tmp" || true
    crontab "$tmp" 2>/dev/null || true
    rm -f "$tmp"
    rc=0
  fi
  rm -f "$PROJECTR_SCHEDULER_ALERT_FILE"
  return $rc
}

projectr_scheduler_cli() {
  local action="${1:-status}"
  case "$action" in
  status) projectr_scheduler_status ;;
  enable) projectr_scheduler_enable ;;
  disable) projectr_scheduler_disable ;;
  run-check) projectr_scheduler_run_check ;;
  *)
    echo "Unknown scheduler action: $action" >&2
    return 1
    ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  source "$SCRIPT_DIR/lib/system/detect.sh"
  projectr_scheduler_cli "$@"
fi
