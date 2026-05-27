#!/usr/bin/env bash
# File: lib/features/profile_manager.sh

export_profile() {
    local backup_file="projectr_profile_$(date +%F).txt"
    echo -e "${INFO} [*] Scanning system for installed ProjectR tools...${RST}"
    
    # Target directory cleanup
    mkdir -p "$(pwd)"
    
    local count=0
    > "$backup_file"

    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "$cmd" >> "$backup_file"
            ((count++))
        fi
    done

    echo -e "${BOLD_GREEN} [✓] Profile exported successfully! ($count tools saved)${RST}"
    echo -e "${OPTION} [→] Saved file: ${BOLD_WHITE}$backup_file${RST}"
}

import_profile() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo -e "${ERROR} [✗] Profile file not found: $file${RST}"
        exit 1
    fi

    echo -e "${INFO} [*] Reading environment profile: $file...${RST}"
    
    local tools_to_install=()
    while read -r target_cmd || [[ -n "$target_cmd" ]]; do
        [[ -z "$target_cmd" || "$target_cmd" =~ ^# ]] && continue
        
        # Match against database
        for entry in "${TOOLS[@]}"; do
            IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
            if [[ "$target_cmd" == "$cmd" ]]; then
                if ! command -v "$cmd" >/dev/null 2>&1; then
                    tools_to_install+=("$entry")
                fi
            fi
        done
    done < "$file"

    if [[ ${#tools_to_install[@]} -eq 0 ]]; then
        echo -e "${BOLD_GREEN} [✓] Everything in the profile is already installed!${RST}"
        return 0
    fi

    echo -e "${OPTION} [*] Found ${#tools_to_install[@]} missing tools. Installing...${RST}"
    for tool_entry in "${tools_to_install[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$tool_entry"
        install_pkg "$cmd" "$pkg" "$name"
    done
}
