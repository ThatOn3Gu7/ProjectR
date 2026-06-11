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

projectr_command_exists() {
    command -v "$1" >/dev/null 2>&1
}
