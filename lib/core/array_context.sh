#!/bin/bash
# shellcheck disable=all
# Scoped result-array helpers for installer/checker code.
#
# Bash dynamically scopes local variables, so callers can use:
#   local -a INSTALLED_PKGS=() SKIPPED_PKGS=() FAILED_PKGS=()
# and lower-level functions will update that local context instead of leaking
# into the process-global arrays. The helper below uses namerefs on Bash 4.3+
# and a validated eval fallback for older Bash releases.

projectr_is_identifier() {
  [[ "${1:-}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

projectr_array_push() {
  local array_name="$1"
  local value="$2"

  if ! projectr_is_identifier "$array_name"; then
    echo "projectr_array_push: invalid array name '$array_name'" >&2
    return 2
  fi

  if ((BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3))); then
    local -n _projectr_array_ref="$array_name"
    _projectr_array_ref+=("$value")
  else
    # Fallback is intentionally narrow: the array name is identifier-checked
    # and printf %q protects the value from code injection.
    local quoted
    printf -v quoted '%q' "$value"
    eval "$array_name+=(\$quoted)"
  fi
}

projectr_array_reset() {
  local array_name
  for array_name in "$@"; do
    if ! projectr_is_identifier "$array_name"; then
      echo "projectr_array_reset: invalid array name '$array_name'" >&2
      return 2
    fi
    eval "$array_name=()"
  done
}

projectr_install_result_push() {
  local bucket="$1" value="$2"
  case "$bucket" in
  installed) projectr_array_push INSTALLED_PKGS "$value" ;;
  skipped) projectr_array_push SKIPPED_PKGS "$value" ;;
  failed) projectr_array_push FAILED_PKGS "$value" ;;
  found) projectr_array_push FOUND_PKGS "$value" ;;
  missing) projectr_array_push NOT_FOUND_PKGS "$value" ;;
  *)
    echo "projectr_install_result_push: unknown bucket '$bucket'" >&2
    return 2
    ;;
  esac
}
