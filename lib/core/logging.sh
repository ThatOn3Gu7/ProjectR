#!/bin/bash
# shellcheck disable=all

# ProjectR logging is intentionally dependency-light: plain text, append-only,
# and safe to call from any sourced file. It records both user-facing events and
# command diagnostics so install.log is useful when something fails silently.
PROJECTR_LOG_DIR="${PROJECTR_LOG_DIR:-${SCRIPT_DIR:-$(pwd)}/log}"
LOG_FILE="${PROJECTR_LOG_FILE:-$PROJECTR_LOG_DIR/install.log}"
PROJECTR_LOG_MAX_BYTES="${PROJECTR_LOG_MAX_BYTES:-524288}"
PROJECTR_LOG_KEEP="${PROJECTR_LOG_KEEP:-3}"
PROJECTR_SESSION_ID="${PROJECTR_SESSION_ID:-$(date '+%Y%m%d-%H%M%S')-$$}"
PROJECTR_LAST_CMD_OUTPUT=""
PROJECTR_LAST_CMD_STATUS=0

_log_init() {
  local log_dir size i
  log_dir="$(dirname "$LOG_FILE")"

  if ! mkdir -p "$log_dir" 2>/dev/null; then
    echo "[logging] WARNING: could not create log dir: $log_dir" >&2
    return 1
  fi
  chmod 700 "$log_dir" 2>/dev/null || true

  if [[ -f "$LOG_FILE" ]]; then
    size=$(wc -c <"$LOG_FILE" 2>/dev/null || echo 0)
    if ((size > PROJECTR_LOG_MAX_BYTES)); then
      for ((i = PROJECTR_LOG_KEEP; i >= 1; i--)); do
        if [[ -f "$LOG_FILE.$i" ]]; then
          if ((i == PROJECTR_LOG_KEEP)); then
            rm -f "$LOG_FILE.$i"
          else
            mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))" 2>/dev/null || true
          fi
        fi
      done
      mv "$LOG_FILE" "$LOG_FILE.1" 2>/dev/null || true
    fi
  fi

  touch "$LOG_FILE" 2>/dev/null || return 1
  chmod 600 "$LOG_FILE" 2>/dev/null || true
  _LOG_READY=1
}

projectr_log_sanitize() {
  local message="$*"
  message=$(printf '%s' "$message" | tr '\r\n' '  ')
  printf '%s' "$message"
}
log() {
  local level="${1:-INFO}" message="${2:-}" component="${3:-core}"
  [[ "${_LOG_READY:-0}" != "1" ]] && _log_init || true
  [[ -n "$message" ]] || message="(no message)"
  message=$(projectr_log_sanitize "$message")
  printf '[%s] [%s] [session:%s] [pid:%s] [%s] %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S%z')" "$level" "$PROJECTR_SESSION_ID" "$$" "$component" "$message" \
    >>"$LOG_FILE" 2>/dev/null || true
}

log_info() { log INFO "$1" "${2:-core}"; }
log_ok() { log OK "$1" "${2:-core}"; }
log_warn() { log WARN "$1" "${2:-core}"; }
log_error() { log ERROR "$1" "${2:-core}"; }
log_fail() { log FAIL "$1" "${2:-core}"; }

projectr_log_file_excerpt() {
  local level="$1" file="$2" component="${3:-command}" lines="${4:-12}"
  [[ -f "$file" ]] || return 0
  local excerpt
  excerpt=$(grep -v '^[[:space:]]*$' "$file" 2>/dev/null | tail -n "$lines" | tr -cd '\11\12\15\40-\176')
  [[ -n "$excerpt" ]] || return 0
  log "$level" "command output tail: $excerpt" "$component"
}

projectr_command_string() {
  local out="" arg
  for arg in "$@"; do
    printf -v arg '%q' "$arg"
    out+="${out:+ }$arg"
  done
  printf '%s' "$out"
}

projectr_run_logged() {
  local component="$1" action="$2"
  shift 2
  local tmp status start duration cmd_string
  tmp=$(mktemp) || {
    log_error "Failed to create temp output file for: $action" "$component"
    return 1
  }
  cmd_string=$(projectr_command_string "$@")
  start=$(date +%s)
  log INFO "START $action :: $cmd_string" "$component"

  "$@" >"$tmp" 2>&1
  status=$?
  duration=$(($(date +%s) - start))
  PROJECTR_LAST_CMD_STATUS=$status
  PROJECTR_LAST_CMD_OUTPUT="$tmp"

  if [[ $status -eq 0 ]]; then
    log OK "SUCCESS $action (exit=$status duration=${duration}s)" "$component"
    projectr_log_file_excerpt DEBUG "$tmp" "$component" 5
  else
    log FAIL "FAILED $action (exit=$status duration=${duration}s) :: $cmd_string" "$component"
    projectr_log_file_excerpt FAIL "$tmp" "$component" 20
  fi

  rm -f "$tmp"
  PROJECTR_LAST_CMD_OUTPUT=""
  return $status
}

projectr_log_environment() {
  log INFO "ProjectR root=${SCRIPT_DIR:-unknown}; shell=${SHELL:-unknown}; user=${USER:-unknown}; pwd=$(pwd); args=${PROJECTR_ORIGINAL_ARGS:-}" "startup"
  log INFO "Detected primary package manager: ${PRIMARY_PKG_MANAGER:-unknown}; all=${DETECTED_PKG_MANAGERS[*]:-unknown}" "startup"
}
