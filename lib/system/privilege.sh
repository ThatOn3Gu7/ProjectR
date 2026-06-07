#!/usr/bin/env bash
# Root/rootless privilege abstraction.

projectr_manager_needs_root() {
    case "$1" in
        apt|apt-get|dnf|yum|pacman|zypper|apk|emerge|xbps|eopkg|urpmi|slackpkg|macports|bsd-pkg|pkg_add|snap) return 0 ;;
        flatpak) return 1 ;;
        pkg|brew|nix|guix|winget|choco|scoop|pip|pip3|pipx|npm|yarn|pnpm|bun|gem|cargo|go|composer) return 1 ;;
        *) return 1 ;;
    esac
}

projectr_preferred_escalator() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        printf '%s\n' root
    elif command -v sudo >/dev/null 2>&1; then
        printf '%s\n' sudo
    elif command -v doas >/dev/null 2>&1; then
        printf '%s\n' doas
    else
        printf '%s\n' none
    fi
}

projectr_privilege_status() {
    local manager="$1" tool
    if ! projectr_manager_needs_root "$manager"; then
        printf 'rootless\tno elevation required\n'
        return 0
    fi

    tool=$(projectr_preferred_escalator)
    case "$tool" in
        root) printf 'ok\talready running as root\n' ;;
        sudo)
            if sudo -n true 2>/dev/null; then
                printf 'ok\tsudo available (passwordless)\n'
            else
                printf 'warn\tsudo available (password may be required)\n'
            fi
            ;;
        doas)
            if doas -n true 2>/dev/null; then
                printf 'ok\tdoas available (passwordless)\n'
            else
                printf 'warn\tdoas available (password may be required)\n'
            fi
            ;;
        *) printf 'missing\tno sudo/doas available for privileged package manager\n' ;;
    esac
}

projectr_run_privileged() {
    local manager="$1"
    shift
    if ! projectr_manager_needs_root "$manager"; then
        "$@"
        return $?
    fi

    case "$(projectr_preferred_escalator)" in
        root) "$@" ;;
        sudo) sudo "$@" ;;
        doas) doas "$@" ;;
        *)
            echo -e "${ERROR:-}[!] This action needs elevated privileges for manager '$manager', but no sudo/doas helper is available.${RST:-}" >&2
            return 1
            ;;
    esac
}
