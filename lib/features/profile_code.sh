#!/bin/bash
# shellcheck disable=all
# Configuration-as-code profile reader for simple projectr.yml/projectr.toml files.

projectr_profile_tools() {
    local file="$1"
    [[ -f "$file" ]] || { echo -e "${ERROR}[!] Profile file not found: $file${RST}" >&2; log_error "Profile not found: $file" "profile"; return 1; }
    case "$file" in
        *.yml|*.yaml)
            awk '
                /^[[:space:]]*tools:[[:space:]]*$/ { in_tools=1; next }
                in_tools && /^[^[:space:]-]/ { in_tools=0 }
                in_tools && /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, ""); gsub(/["'"'"']/, ""); print; next }
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
        *) echo -e "${ERROR}[!] Unsupported profile file format: $file${RST}" >&2; log_error "Unsupported profile format: $file" "profile"; return 1 ;;
    esac
}

projectr_install_profile() {
    local file="$1" tool
    mapfile -t _projectr_profile_tools < <(projectr_profile_tools "$file")
    [[ ${#_projectr_profile_tools[@]} -gt 0 ]] || { echo -e "${ERROR}[!] No tool definitions found in $file${RST}"; log_warn "No tools found in profile: $file" "profile"; return 1; }
    local _old_nvim="${PROJECTR_NVIM_CONFIG-}" _old_omz="${PROJECTR_ZSH_INSTALL_OMZ-}" _old_theme="${PROJECTR_ZSH_THEME-}" _old_p10k="${PROJECTR_ZSH_INSTALL_P10K-}"
    declare -f projectr_profile_export_settings >/dev/null 2>&1 && projectr_profile_export_settings "$file" || true
    log_info "Installing profile $file with ${#_projectr_profile_tools[@]} tool(s)" "profile"
    local status=0 rc entry cmd pkg name desc type extra cat
    for tool in "${_projectr_profile_tools[@]}"; do
        entry=$(projectr_profile_find_entry "$tool") || {
            echo -e "${ERROR}[!] Unrecognized tool in profile definition: $tool${RST}"
            status=1
            continue
        }
        IFS='|' read -r _ cmd pkg name desc type extra cat <<< "$entry"
        projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
        rc=$?
        [[ $rc -ne 0 ]] && status=$rc
    done
    PROJECTR_NVIM_CONFIG="${_old_nvim}" PROJECTR_ZSH_INSTALL_OMZ="${_old_omz}" PROJECTR_ZSH_THEME="${_old_theme}" PROJECTR_ZSH_INSTALL_P10K="${_old_p10k}"
    export PROJECTR_NVIM_CONFIG PROJECTR_ZSH_INSTALL_OMZ PROJECTR_ZSH_THEME PROJECTR_ZSH_INSTALL_P10K
    return "$status"
}


projectr_profile_json_escape() {
    if declare -f projectr_doctor_json_escape >/dev/null 2>&1; then
        projectr_doctor_json_escape "${1-}"
    elif declare -f projectr_escape_json >/dev/null 2>&1; then
        projectr_escape_json "${1-}"
    else
        local value="${1-}"
        value=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\t\r\n' '   ')
        printf '%s' "$value"
    fi
}

projectr_profile_find_entry() {
    local target="$1" entry cmd pkg name desc type extra cat
    for entry in "${TOOLS[@]}"; do
        IFS='|' read -r _ cmd pkg name desc type extra cat <<< "$entry"
        if [[ "${cmd,,}" == "${target,,}" || "${pkg,,}" == "${target,,}" || "${name,,}" == "${target,,}" ]]; then
            printf '%s\n' "$entry"
            return 0
        fi
    done
    return 1
}

projectr_profile_diff() {
    local file="" json=0 arg
    for arg in "$@"; do
        case "$arg" in
            --profile=*) file="${arg#--profile=}" ;;
            --profile) file="__NEXT__" ;;
            --json) json=1 ;;
            --*) echo -e "${ERROR}[!] Unrecognized difference-comparison parameter: $arg${RST}" >&2; return 2 ;;
            *)
                if [[ "$file" == "__NEXT__" ]]; then
                    file="$arg"
                elif [[ -z "$file" ]]; then
                    file="$arg"
                else
                    echo -e "${ERROR}[!] Unexpected comparison argument: $arg${RST}" >&2
                    return 2
                fi
                ;;
        esac
    done

    [[ -n "$file" && "$file" != "__NEXT__" ]] || { echo -e "${ERROR}[!] The diff operation requires --profile <file>.${RST}" >&2; return 1; }
    [[ -f "$file" ]] || { projectr_profile_tools "$file" >/dev/null; return 1; }
    case "$file" in
        *.yml|*.yaml|*.toml) ;;
        *) projectr_profile_tools "$file" >/dev/null; return 1 ;;
    esac

    local tmp tool entry cmd pkg name desc type extra cat status installed=0 missing=0 unknown=0 first=1
    tmp=$(mktemp) || return 1
    while IFS= read -r tool; do
        [[ -n "$tool" ]] || continue
        entry=$(projectr_profile_find_entry "$tool") || {
            printf '%s\t%s\t%s\t%s\t%s\n' "$tool" "-" "-" "unknown" "not in registry" >> "$tmp"
            unknown=$((unknown + 1))
            continue
        }
        IFS='|' read -r _ cmd pkg name desc type extra cat <<< "$entry"
        if command -v "$cmd" >/dev/null 2>&1; then
            status="installed"
            installed=$((installed + 1))
        else
            status="missing"
            missing=$((missing + 1))
        fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$cmd" "$pkg" "$status" "$type" >> "$tmp"
    done < <(projectr_profile_tools "$file")

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        echo -e "${ERROR}[!] No tool definitions found in $file${RST}" >&2
        return 1
    fi

    if [[ $json -eq 1 ]]; then
        printf '{"profile":"%s","installed":%s,"missing":%s,"unknown":%s,"tools":[' "$(projectr_profile_json_escape "$file")" "$installed" "$missing" "$unknown"
        while IFS=$'\t' read -r name cmd pkg status type; do
            [[ $first -eq 0 ]] && printf ','
            first=0
            printf '{"name":"%s","cmd":"%s","package":"%s","status":"%s","type":"%s"}' \
                "$(projectr_profile_json_escape "$name")" \
                "$(projectr_profile_json_escape "$cmd")" \
                "$(projectr_profile_json_escape "$pkg")" \
                "$(projectr_profile_json_escape "$status")" \
                "$(projectr_profile_json_escape "$type")"
        done < "$tmp"
        printf ']}\n'
    else
        echo -e "${OPTION}[*] Profile diff: ${BOLD_WHITE}$file${RST}"
        printf '  %-18s %-14s %-18s %-10s %s\n' Tool Command Package Status Type
        printf '  %s\n' '────────────────────────────────────────────────────────────────────'
        while IFS=$'\t' read -r name cmd pkg status type; do
            printf '  %-18s %-14s %-18s %-10s %s\n' "$name" "$cmd" "$pkg" "$status" "$type"
        done < "$tmp"
        printf '  %s\n' '────────────────────────────────────────────────────────────────────'
        echo -e "${DIM}[*] installed=$installed missing=$missing unknown=$unknown${RST}"
    fi
    rm -f "$tmp"
    [[ $missing -eq 0 && $unknown -eq 0 ]]
}
