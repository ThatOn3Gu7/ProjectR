#!/bin/bash
# shellcheck disable=all

# ── Globals set by detect_pkg_manager ──
PRIMARY_PKG_MANAGER=""
DETECTED_PKG_MANAGERS=()

# ── detect_pkg_manager ───
detect_pkg_manager() {
  # Return cached result if already detected
  if [[ -n "${PRIMARY_PKG_MANAGER:-}" && "${PRIMARY_PKG_MANAGER}" != "unknown" ]]; then
    echo "$PRIMARY_PKG_MANAGER"
    return 0
  fi

  DETECTED_PKG_MANAGERS=()

  # PATCH 2: Parse /etc/os-release for ID_LIKE before scanning commands.
  # This means on distros like Pop!_OS (ID_LIKE="ubuntu debian"), Mint, or
  # Raspbian we correctly prioritise apt even if multiple managers are present.
  # Behaviour lifted from universal-environment-detection.sh (_ud_parse_os_release_file
  # + _ud_add_native_priority_for_family). We only read ID and ID_LIKE here —
  # no extra deps, no eval, no subshell needed.
  local os_id="" os_like=""
  if [[ -r /etc/os-release ]]; then
    while IFS='=' read -r key val || [[ -n "$key" ]]; do
      # strip quotes the shell way — no eval
      val="${val#\"}"
      val="${val%\"}"
      val="${val#\'}"
      val="${val%\'}"
      case "$key" in
      ID) os_id="${val,,}" ;; # lowercase
      ID_LIKE) os_like="${val,,}" ;;
      esac
    done </etc/os-release
  fi

  # Derive a priority manager from the OS family so the right tool comes first
  # even when multiple package managers happen to be installed on the same box.
  local family_pm=""
  local _id
  for _id in $os_id $os_like; do
    case "$_id" in
    debian | ubuntu | linuxmint | raspbian | pop | pop_os | elementary | kali | parrot | zorin | mx | devuan | neon)
      family_pm="apt"
      break
      ;;
    fedora | rhel | centos | rocky | almalinux | ol | oracle | amzn | amazon)
      family_pm="dnf"
      break
      ;;
    arch | manjaro | endeavouros | artix | garuda)
      family_pm="pacman"
      break
      ;;
    opensuse* | sles | suse)
      family_pm="zypper"
      break
      ;;
    alpine)
      family_pm="apk"
      break
      ;;
    void)
      family_pm="xbps"
      break
      ;;
    gentoo | funtoo)
      family_pm="emerge"
      break
      ;;
    nixos)
      family_pm="nix"
      break
      ;;
    darwin | macos)
      family_pm="brew"
      break
      ;;
    esac
  done

  local candidates=(
    # Android
    "pkg|pkg" # Termux — checked via $PREFIX below too
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
    fi
  done

  # If nothing was detected at all
  if [[ ${#DETECTED_PKG_MANAGERS[@]} -eq 0 ]]; then
    PRIMARY_PKG_MANAGER="unknown"
    DETECTED_PKG_MANAGERS+=("unknown")
    echo "$PRIMARY_PKG_MANAGER"
    return
  fi

  # Set PRIMARY_PKG_MANAGER: prefer the family-derived one if it was detected,
  # otherwise fall back to the first one found by the command scan.
  # This is the core of PATCH 2 — without it, a Debian box with both apt and
  # snap installed could end up with snap as primary just because of scan order.
  if [[ -n "$family_pm" ]]; then
    local m
    for m in "${DETECTED_PKG_MANAGERS[@]}"; do
      if [[ "$m" == "$family_pm" ]]; then
        PRIMARY_PKG_MANAGER="$family_pm"
        break
      fi
    done
  fi
  # Fallback: if family match wasn't in detected list, use first detected
  if [[ -z "$PRIMARY_PKG_MANAGER" ]]; then
    PRIMARY_PKG_MANAGER="${DETECTED_PKG_MANAGERS[0]}"
  fi

  echo "$PRIMARY_PKG_MANAGER"
}

# ── detect_pkg_for_tool ───
# Returns the best available manager for a given language ecosystem.
# Arg $1: "pip" | "npm" | "gem" | "cargo" | "go" | "composer" | "system"
detect_pkg_for_tool() {
  local tool_type="${1:-system}"

  case "$tool_type" in
  pipx)
    if command -v pipx >/dev/null 2>&1; then echo "pipx"; else echo "none"; fi
    ;;
  pip | pip3)
    if command -v "$tool_type" >/dev/null 2>&1; then
      echo "$tool_type"
    elif command -v pipx >/dev/null 2>&1; then
      echo "pipx"
    elif command -v pip3 >/dev/null 2>&1; then
      echo "pip3"
    elif command -v pip >/dev/null 2>&1; then
      echo "pip"
    else
      echo "none"
    fi
    ;;
  npm | yarn | pnpm | bun)
    if command -v "$tool_type" >/dev/null 2>&1; then
      echo "$tool_type"
    elif command -v npm >/dev/null 2>&1; then
      echo "npm"
    elif command -v yarn >/dev/null 2>&1; then
      echo "yarn"
    elif command -v pnpm >/dev/null 2>&1; then
      echo "pnpm"
    elif command -v bun >/dev/null 2>&1; then
      echo "bun"
    else
      echo "none"
    fi
    ;;
  gem)
    command -v gem >/dev/null 2>&1 && echo "gem" || echo "none"
    ;;
  cargo)
    command -v cargo >/dev/null 2>&1 && echo "cargo" || echo "none"
    ;;
  go)
    command -v go >/dev/null 2>&1 && echo "go" || echo "none"
    ;;
  composer)
    command -v composer >/dev/null 2>&1 && echo "composer" || echo "none"
    ;;
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
