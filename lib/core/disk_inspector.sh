#!/usr/bin/env bash
# -- disj space checker --
assert_disk_space() {
    local available_space

    # Guard: df itself could fail on non-standard systems
    if ! available_space=$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $4}'); then
        echo -e "${BOLD_YELLOW} ⚠️ [DISK WARNING] Could not run df — skipping disk check.${RST}"
        ask " [*] Continue without disk space verification?" "n" || exit 1
        return 0
    fi

    # Guard: output must be a valid integer
    if [[ -z "$available_space" || ! "$available_space" =~ ^[0-9]+$ ]]; then
        echo -e "${BOLD_YELLOW} ⚠️ [DISK WARNING] Disk space output was unreadable.${RST}"
        ask " [*] Continue anyway?" "n" || exit 1
        return 0
    fi

    if (( available_space < 2500 )); then
        echo -e "${BOLD_YELLOW} ⚠️ [DISK WARNING] Low disk space! Available: ${available_space}MB.${RST}"
        if ! ask " [*] Bypass warning and proceed?" "n"; then
            echo -e "${ERROR} [✗] Halting due to low storage.${RST}"
            exit 1
        fi
    fi
}
