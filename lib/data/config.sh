#!/bin/bash
# -- Session & persistent config store --
# Saves one-time user choices so they aren't asked again.

CONFIG_FILE="${HOME}/.config/projectr/session.conf"

# Ensure the config dir and file exist
config_init() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    [ -f "$CONFIG_FILE" ] || touch "$CONFIG_FILE"
}

# Get a value by key. Prints the value or nothing if not set.
# Usage: val=$(config_get "skip_dep_check")
config_get() {
    local key="$1"
    grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null | tail -n1 | cut -d'=' -f2-
}

# Set a key=value pair. Overwrites if already exists.
# Usage: config_set "skip_dep_check" "true"
config_set() {
    local key="$1" value="$2"
    config_init
    local tmp
    tmp=$(mktemp "${CONFIG_FILE}.XXXXXX") || return 1
    grep -v "^${key}=" "$CONFIG_FILE" > "$tmp" 2>/dev/null || true
    echo "${key}=${value}" >> "$tmp"
    mv "$tmp" "$CONFIG_FILE"
}

# Clear a single key (for resetting a specific choice)
# Usage: config_clear "skip_dep_check"
config_clear() {
    local key="$1"
    local tmp
    tmp=$(mktemp "${CONFIG_FILE}.XXXXXX") || return 1
    grep -v "^${key}=" "$CONFIG_FILE" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$CONFIG_FILE"
}
# Clear ALL saved config (nuclear reset)
config_reset_all() {
    > "$CONFIG_FILE"
    echo -e "${OPTION} [✓] All saved preferences cleared.${RST}"
}

config_init
