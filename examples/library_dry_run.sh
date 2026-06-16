#!/usr/bin/env bash
# shellcheck disable=SC1090
# Example: use ProjectR's library API to generate a dry-run install plan.
#
# Run from the repository root:
#   bash examples/library_dry_run.sh git curl jq
#
# If no arguments are provided, the example plans git/curl/jq.

set -uo pipefail

PROJECTR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/projectr.sh
source "$PROJECTR_ROOT/lib/projectr.sh"

projectr_init --no-plugins --no-color

if [[ $# -eq 0 ]]; then
  set -- git curl jq
fi

printf 'Planning install for: %s\n' "$*" >&2
projectr_plan_install "$@" --json
