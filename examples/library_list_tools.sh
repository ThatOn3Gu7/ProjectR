#!/usr/bin/env bash
# shellcheck disable=SC1090
# Example: use ProjectR as a sourceable registry library.
#
# Run from the repository root:
#   bash examples/library_list_tools.sh
#
# Or point PROJECTR_ROOT_OVERRIDE at a checkout:
#   PROJECTR_ROOT_OVERRIDE=/path/to/ProjectR bash examples/library_list_tools.sh

set -uo pipefail

if [[ -n "${PROJECTR_ROOT_OVERRIDE:-}" ]]; then
  PROJECTR_ROOT="$PROJECTR_ROOT_OVERRIDE"
else
  PROJECTR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# shellcheck source=../lib/projectr.sh
source "$PROJECTR_ROOT/lib/projectr.sh"

# No plugin loading here; this keeps output deterministic for demos.
projectr_init --no-plugins

printf 'ProjectR %s at %s\n' "$(projectr_version)" "$(projectr_root)"
printf 'Detected package manager: %s\n' "$(projectr_detect_manager)"
printf 'Registered tools: %s\n\n' "$(projectr_tool_count)"

printf 'First 10 developer tools from the registry:\n'
printf '%-16s %-22s %-8s %s\n' 'COMMAND' 'PACKAGE' 'TYPE' 'NAME'
printf '%-16s %-22s %-8s %s\n' '-------' '-------' '----' '----'

count=0
while IFS=$'\t' read -r num cmd pkg name desc type extra category; do
  [[ "$category" == "Dev" ]] || continue
  printf '%-16s %-22s %-8s %s\n' "$cmd" "$pkg" "$type" "$name"
  count=$((count + 1))
  [[ $count -ge 10 ]] && break
done < <(projectr_tool_list --format=tsv)

printf '\nStatus for a few common tools:\n'
for tool in git curl jq fd; do
  printf '  %-8s ' "$tool"
  projectr_tool_status "$tool" || true
done
