#!/usr/bin/env bash
# -- export_profile function --
export_profile() {
    if [[ ${#TOOLS[@]} -eq 0 ]]; then
        echo -e "${ERROR} [✗] TOOLS array is empty — nothing to export.${RST}"
        return 1
    fi

    local backup_file="projectr_profile_$(date +%F).txt"

    if [[ ! -w "$(pwd)" ]]; then
        echo -e "${ERROR} [✗] Cannot write to current directory: $(pwd)${RST}"
        return 1
    fi

    echo -e "${INFO} [*] Scanning system for installed ProjectR tools...${RST}"

    local count=0
    > "$backup_file" || {
        echo -e "${ERROR} [✗] Failed to create profile file: $backup_file${RST}"
        return 1
    }

    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "$cmd" >> "$backup_file"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo -e "${BOLD_YELLOW} [!] No tools currently installed — profile file not saved.${RST}"
        rm -f "$backup_file"
        return 0
    fi

    echo -e "${BOLD_GREEN} [✓] Profile exported! ($count tools saved)${RST}"
    echo -e "${OPTION} [→] Saved to: ${BOLD_WHITE}$backup_file${RST}"
}
# -- import_profile function --
import_profile() {
    local file="$1"

    [[ -z "$file" ]] && { echo -e "${ERROR} [✗] No profile file specified.${RST}"; return 1; }
    [[ ! -f "$file" ]] && { echo -e "${ERROR} [✗] Profile file not found: $file${RST}"; return 1; }
    [[ ! -r "$file" ]] && { echo -e "${ERROR} [✗] Profile file is not readable: $file${RST}"; return 1; }

    echo -e "${INFO} [*] Reading environment profile: $file...${RST}"

    local tools_to_install=()
    local line_num=0 skipped=0

    while read -r target_cmd || [[ -n "$target_cmd" ]]; do
        ((line_num++))
        [[ -z "$target_cmd" || "$target_cmd" =~ ^# ]] && continue

        # Reject anything with spaces or shell-unsafe characters
        if [[ "$target_cmd" =~ [[:space:]] || "$target_cmd" =~ [^a-zA-Z0-9_.-] ]]; then
            echo -e "${BOLD_YELLOW} [!] Line $line_num: invalid entry '$target_cmd' — skipping.${RST}"
            ((skipped++)); continue
        fi

        local matched=0
        for entry in "${TOOLS[@]}"; do
            IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
            if [[ "$target_cmd" == "$cmd" ]]; then
                matched=1
                command -v "$cmd" >/dev/null 2>&1 || tools_to_install+=("$entry")
            fi
        done

        if [[ $matched -eq 0 ]]; then
            echo -e "${BOLD_YELLOW} [!] Line $line_num: '$target_cmd' not in tool list — skipping.${RST}"
            ((skipped++))
        fi
    done < "$file"

    [[ $skipped -gt 0 ]] && echo -e "${BOLD_YELLOW} [!] $skipped line(s) skipped (unknown or invalid).${RST}"

    if [[ ${#tools_to_install[@]} -eq 0 ]]; then
        echo -e "${BOLD_GREEN} [✓] Everything in the profile is already installed!${RST}"
        return 0
    fi

    echo -e "${OPTION} [*] Found ${#tools_to_install[@]} missing tools. Installing...${RST}"
    local failed=0
    for tool_entry in "${tools_to_install[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$tool_entry"
        install_pkg "$cmd" "$pkg" "$name" || ((failed++))
    done

    [[ $failed -gt 0 ]] && echo -e "${ERROR} [!] $failed tool(s) failed to install.${RST}" && return 1
    return 0
}
