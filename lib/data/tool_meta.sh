#!/usr/bin/env bash
# shellcheck disable=all
# Optional v2 metadata layer without breaking the legacy TOOLS array.

# Package name overrides by tool_id/current manager.
declare -gA PROJECTR_TOOL_PKG_OVERRIDES=(
    [fd:apt]=fd-find
    [fd:apt-get]=fd-find
    [sqlite3:apt]=sqlite3
    [sqlite3:apt-get]=sqlite3
    [docker:apt]=docker.io
    [docker:apt-get]=docker.io
    [psql:apt]=postgresql-client
    [psql:apt-get]=postgresql-client
)

# Binary name overrides when a distro packages the tool under a different command.
declare -gA PROJECTR_TOOL_CMD_OVERRIDES=(
    [fd:apt]=fdfind
    [fd:apt-get]=fdfind
    [bat:apt]=batcat
    [bat:apt-get]=batcat
)

projectr_tool_id() {
    printf '%s\n' "$1"
}

projectr_registry_package_for_manager() {
    local tool_id="$1" default_pkg="$2" manager="$3"
    printf '%s\n' "${PROJECTR_TOOL_PKG_OVERRIDES[$tool_id:$manager]:-$default_pkg}"
}

projectr_registry_cmd_for_manager() {
    local tool_id="$1" default_cmd="$2" manager="$3"
    printf '%s\n' "${PROJECTR_TOOL_CMD_OVERRIDES[$tool_id:$manager]:-$default_cmd}"
}

projectr_effective_package() {
    local tool_id="$1" default_pkg="$2" manager="${3:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}"
    projectr_registry_package_for_manager "$tool_id" "$default_pkg" "$manager"
}

projectr_effective_cmd() {
    local tool_id="$1" default_cmd="$2" manager="${3:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}"
    projectr_registry_cmd_for_manager "$tool_id" "$default_cmd" "$manager"
}
