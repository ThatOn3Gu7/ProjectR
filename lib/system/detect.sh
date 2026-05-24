#!/bin/bash

# ── Globals set by detect_pkg_manager ────────────────────────────────────────
# PRIMARY_PKG_MANAGER : the single best system PM to use for installs
# DETECTED_PKG_MANAGERS : array of ALL system PMs found on this machine
PRIMARY_PKG_MANAGER=""
DETECTED_PKG_MANAGERS=()

# ── detect_pkg_manager ────────────────────────────────────────────────────────
# Finds every system package manager available, stores them all in
# DETECTED_PKG_MANAGERS, and picks the best one as PRIMARY_PKG_MANAGER.
# Language-specific managers (pip, npm, gem, cargo…) are intentionally
# excluded — use detect_pkg_for_tool for those.
detect_pkg_manager() {
    DETECTED_PKG_MANAGERS=()

    # ── Priority-ordered list: id | check-command ────────────────────────
    # Format: "id|cmd"  — id is what we store, cmd is what we test with
    # `command -v`.  Listed best-first so the first hit becomes PRIMARY.
    local candidates=(
        # Android
        "pkg|pkg"               # Termux — checked via $PREFIX below too
        # Debian / Ubuntu family
        "apt|apt"
        "apt-get|apt-get"
        # Arch family
        "pacman|pacman"
        # Fedora / RHEL family
        "dnf|dnf"
        "yum|yum"
        # openSUSE
        "zypper|zypper"
        # Alpine
        "apk|apk"
        # Gentoo
        "emerge|emerge"
        # Void Linux
        "xbps|xbps-install"
        # NixOS
        "nix|nix"
        # GNU Guix
        "guix|guix"
        # Solus
        "eopkg|eopkg"
        # Mageia
        "urpmi|urpmi"
        # Slackware
        "slackpkg|pkgtool"
        # macOS
        "brew|brew"
        "macports|port"
        # FreeBSD
        "bsd-pkg|pkg"
        # OpenBSD
        "pkg_add|pkg_add"
        # Windows (WSL / Git Bash / Cygwin)
        "winget|winget.exe"
        "choco|choco.exe"
        "scoop|scoop"
        # Universal Linux extras
        "flatpak|flatpak"
        "snap|snap"
    )

    # Special-case Termux first: $PREFIX is the reliable signal.
    # Without this, FreeBSD's `pkg` and Termux's `pkg` would collide.
    if [ -n "${PREFIX:-}" ] && [[ "$PREFIX" == *termux* ]]; then
        DETECTED_PKG_MANAGERS+=("pkg")
        PRIMARY_PKG_MANAGER="pkg"
        # Still scan for extras (flatpak etc.) that could co-exist
    fi

    for entry in "${candidates[@]}"; do
        local id="${entry%%|*}"
        local cmd="${entry##*|}"

        # Skip pkg if we already added it for Termux above
        if [[ "$id" == "pkg" && "$PRIMARY_PKG_MANAGER" == "pkg" ]]; then
            continue
        fi

        if command -v "$cmd" >/dev/null 2>&1; then
            DETECTED_PKG_MANAGERS+=("$id")
            # First found (highest priority) becomes the primary
            if [[ -z "$PRIMARY_PKG_MANAGER" ]]; then
                PRIMARY_PKG_MANAGER="$id"
            fi
        fi
    done

    # If nothing was detected at all
    if [[ -z "$PRIMARY_PKG_MANAGER" ]]; then
        PRIMARY_PKG_MANAGER="unknown"
        DETECTED_PKG_MANAGERS+=("unknown")
    fi

    # Echo the primary so callers that do PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}" still work
    echo "$PRIMARY_PKG_MANAGER"
}


# ── detect_pkg_for_tool ───────────────────────────────────────────────────────
# Returns the best available manager for a given language ecosystem.
# Arg $1: "pip" | "npm" | "gem" | "cargo" | "go" | "composer" | "system"
detect_pkg_for_tool() {
    local tool_type="${1:-system}"

    case "$tool_type" in
        pip)
            if   command -v pipx >/dev/null 2>&1; then echo "pipx"
            elif command -v pip3 >/dev/null 2>&1; then echo "pip3"
            elif command -v pip  >/dev/null 2>&1; then echo "pip"
            else echo "none"
            fi
            ;;
        npm)
            if   command -v npm  >/dev/null 2>&1; then echo "npm"
            elif command -v yarn >/dev/null 2>&1; then echo "yarn"
            elif command -v pnpm >/dev/null 2>&1; then echo "pnpm"
            elif command -v bun  >/dev/null 2>&1; then echo "bun"
            else echo "none"
            fi
            ;;
        gem)
            command -v gem   >/dev/null 2>&1 && echo "gem"   || echo "none" ;;
        cargo)
            command -v cargo >/dev/null 2>&1 && echo "cargo" || echo "none" ;;
        go)
            command -v go    >/dev/null 2>&1 && echo "go"    || echo "none" ;;
        composer)
            command -v composer >/dev/null 2>&1 && echo "composer" || echo "none" ;;
        system)
            # Caller wants the system PM — run full detection if not done yet
            [[ -z "$PRIMARY_PKG_MANAGER" ]] && detect_pkg_manager >/dev/null
            echo "$PRIMARY_PKG_MANAGER"
            ;;
        *)
            # Unknown type — fall back to system PM
            [[ -z "$PRIMARY_PKG_MANAGER" ]] && detect_pkg_manager >/dev/null
            echo "$PRIMARY_PKG_MANAGER"
            ;;
    esac
}
