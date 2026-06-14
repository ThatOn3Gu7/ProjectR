#!/bin/bash
# shellcheck disable=all
# Strict-mode helpers for ProjectR. The framework intentionally avoids global
# `set -e` because optional probes and package-manager simulations often return
# non-zero as expected data. Use these wrappers to make failure boundaries
# explicit while keeping `set -uo pipefail` safe.

projectr_try() {
  "$@"
}

projectr_require() {
  local label="$1"
  shift
  "$@"
  local status=$?
  if [ "$status" -ne 0 ]; then
    echo "[ProjectR] required step failed ($status): $label" >&2
    return "$status"
  fi
  return 0
}

projectr_optional() {
  "$@" >/dev/null 2>&1
}

# Command lookup helpers -----------------------------------------------------
#
# ProjectR checks many registry entries in read-only commands such as
# `project list installed`, `project list categories`, dry-run planning, and
# profile export. Repeating `command -v` for the same binaries is cheap once but
# noticeable across hundreds of tools on slower shells/Termux. These helpers
# memoize lookups for the lifetime of the process while keeping a single place
# to clear the cache after a mutating action if future callers need it.
declare -gA PROJECTR_COMMAND_EXISTS_CACHE=()
declare -gA PROJECTR_COMMAND_PATH_CACHE=()

projectr_command_cache_clear() {
  PROJECTR_COMMAND_EXISTS_CACHE=()
  PROJECTR_COMMAND_PATH_CACHE=()
}

projectr_command_exists() {
  local cmd="${1:-}" path
  [[ -n "$cmd" ]] || return 1

  if [[ "${PROJECTR_COMMAND_CACHE_DISABLE:-0}" == "1" ]]; then
    command -v "$cmd" >/dev/null 2>&1
    return $?
  fi

  if [[ -n "${PROJECTR_COMMAND_EXISTS_CACHE[$cmd]+set}" ]]; then
    [[ "${PROJECTR_COMMAND_EXISTS_CACHE[$cmd]}" == "1" ]]
    return $?
  fi

  if path=$(command -v "$cmd" 2>/dev/null); then
    PROJECTR_COMMAND_EXISTS_CACHE[$cmd]=1
    PROJECTR_COMMAND_PATH_CACHE[$cmd]="$path"
    return 0
  fi

  PROJECTR_COMMAND_EXISTS_CACHE[$cmd]=0
  PROJECTR_COMMAND_PATH_CACHE[$cmd]=""
  return 1
}

projectr_command_path() {
  local cmd="${1:-}"
  [[ -n "$cmd" ]] || return 1

  if projectr_command_exists "$cmd"; then
    printf '%s\n' "${PROJECTR_COMMAND_PATH_CACHE[$cmd]:-$(command -v "$cmd" 2>/dev/null)}"
    return 0
  fi
  return 1
}
