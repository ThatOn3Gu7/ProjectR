#!/bin/bash
# Configuration-as-code profile reader for simple projectr.yml/projectr.toml files.

projectr_profile_tools() {
    local file="$1"
    [[ -f "$file" ]] || { echo -e "${ERROR}[!] Profile not found: $file${RST}" >&2; return 1; }
    case "$file" in
        *.yml|*.yaml)
            awk '
                /^[[:space:]]*tools:[[:space:]]*$/ { in_tools=1; next }
                in_tools && /^[^[:space:]-]/ { in_tools=0 }
                in_tools && /^[[:space:]]*-[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/["'"'"']/, ""); print }
            ' "$file"
            ;;
        *.toml)
            awk -F '=' '
                $1 ~ /^[[:space:]]*tools[[:space:]]*$/ {
                    value=$2; gsub(/[][]/, "", value); print value
                }
            ' "$file" | tr ',' '\n' | sed 's/["[:space:]]//g; /^$/d'
            ;;
        *) echo -e "${ERROR}[!] Unsupported profile format: $file${RST}" >&2; return 1 ;;
    esac
}

projectr_install_profile() {
    local file="$1" tool
    mapfile -t _projectr_profile_tools < <(projectr_profile_tools "$file")
    [[ ${#_projectr_profile_tools[@]} -gt 0 ]] || { echo -e "${ERROR}[!] No tools found in $file${RST}"; return 1; }
    for tool in "${_projectr_profile_tools[@]}"; do
        _flag_install "$tool"
    done
}
