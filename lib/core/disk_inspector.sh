#!/usr/bin/env bash
# shellcheck disable=all
# -- disj space checker --
assert_disk_space() {
    local cache_dir
    case "${PRIMARY_PKG_MANAGER:-}" in
        apt|apt-get) cache_dir="/var/cache/apt" ;;
        pacman)      cache_dir="/var/cache/pacman/pkg" ;;
        dnf|yum)     cache_dir="/var/cache/dnf" ;;
        *)           cache_dir="$HOME" ;;
    esac

    local home_space cache_space available_space

    if ! home_space=$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $4}'); then
        echo -e "${BOLD_YELLOW} ⚠️ [DISK WARNING] Could not run df — skipping disk check.${RST}"
        ask " [*] Continue without disk space verification?" "n" || exit 1
        return 0
    fi

    cache_space=$(df -m "$cache_dir" 2>/dev/null | awk 'NR==2 {print $4}')

    # Use the smaller of the two (or just home_space if cache_dir check failed)
    if [[ "$home_space" =~ ^[0-9]+$ && "$cache_space" =~ ^[0-9]+$ ]]; then
        available_space=$(( home_space < cache_space ? home_space : cache_space ))
    else
        available_space="${home_space:-0}"
    fi

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
