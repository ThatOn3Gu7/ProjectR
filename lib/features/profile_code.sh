#!/bin/bash
# Configuration-as-code profile reader for simple projectr.yml/projectr.toml files.

projectr_profile_tools() {
    local file="$1"
    [[ -f "$file" ]] || { echo -e "${ERROR}[!] Profile not found: $file${RST}" >&2; log_error "Profile not found: $file" "profile"; return 1; }
    case "$file" in
        *.yml|*.yaml)
            awk '
                /^[[:space:]]*tools:[[:space:]]*$/ { in_tools=1; next }
                in_tools && /^[^[:space:]-]/ { in_tools=0 }
                in_tools && /^[[:space:]]*-[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/["'"'"']/, ""); print }
            ' "$file"
            ;;
            *.toml)
               awk '
                   /^[[:space:]]*tools[[:space:]]*=/ {
                       if (/\[.*\]/) {
                           sub(/.*\[/, ""); sub(/\].*/, "")
                           n = split($0, arr, /,/)
                           for (i=1; i<=n; i++) {
                               gsub(/["'"'"'[:space:]]/, "", arr[i])
                               if (arr[i] != "") print arr[i]
                           }
                           in_list = 0
                       } else {
                           in_list = 1
                       }
                       next
                   }
                   in_list {
                       if (/\]/) { in_list = 0; next }
                       gsub(/["'"'"',[:space:]]/, "")
                       if ($0 != "") print $0
                   }
               ' "$file"
               ;;
        *) echo -e "${ERROR}[!] Unsupported profile format: $file${RST}" >&2; log_error "Unsupported profile format: $file" "profile"; return 1 ;;
    esac
}

projectr_install_profile() {
    local file="$1" tool
    mapfile -t _projectr_profile_tools < <(projectr_profile_tools "$file")
    [[ ${#_projectr_profile_tools[@]} -gt 0 ]] || { echo -e "${ERROR}[!] No tools found in $file${RST}"; log_warn "No tools found in profile: $file" "profile"; return 1; }
    log_info "Installing profile $file with ${#_projectr_profile_tools[@]} tool(s)" "profile"
    for tool in "${_projectr_profile_tools[@]}"; do
        _flag_install "$tool"
    done
}
