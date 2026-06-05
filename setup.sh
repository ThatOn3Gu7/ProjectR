#!/usr/bin/env bash
set -euo pipefail

# ProjectR command installer
# Copies the repo to a hidden user-level app directory and creates a `project`
# launcher so ProjectR can be run from any working directory.
#
# Supports two modes:
#   1. LOCAL  — run from a cloned ProjectR checkout (original behaviour).
#   2. REMOTE — piped through curl/wget with no prior clone required:
#        curl -fsSL https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | sh
#        wget -qO- https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | sh
#
# In remote mode, setup clones ProjectR into $XDG_DATA_HOME/projectr (or
# ~/.local/share/projectr) and then runs the normal local setup against that
# fresh clone.

PROJECTR_REPO_URL="${PROJECTR_REPO_URL:-https://github.com/Thaton3gu7/ProjectR.git}"
PROJECT_NAME="ProjectR"
COMMAND_NAME="${PROJECTR_COMMAND_NAME:-project}"
DEFAULT_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/projectr"
DEFAULT_BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
INSTALL_DIR="${PROJECTR_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
BIN_DIR="${PROJECTR_BIN_DIR:-$DEFAULT_BIN_DIR}"
ADD_PATH=0
REMOTE_MODE=0

# ---------------------------------------------------------------------------
# Detect remote (piped) mode
# ---------------------------------------------------------------------------
# When the script is piped through curl/wget, BASH_SOURCE[0] is either empty,
# unset, or points to a path that doesn't actually contain ProjectR files.
# We use that to decide whether we need to clone the repo first.
# ---------------------------------------------------------------------------
_detect_source_dir() {
    local candidate="${BASH_SOURCE[0]:-}"
    if [[ -n "$candidate" ]]; then
        candidate="$(cd "$(dirname "$candidate")" 2>/dev/null && pwd -P)" || candidate=""
    fi

    if [[ -n "$candidate" && -f "$candidate/main.sh" && -d "$candidate/lib" ]]; then
        SOURCE_DIR="$candidate"
        REMOTE_MODE=0
    else
        REMOTE_MODE=1
        SOURCE_DIR=""
    fi
}

_detect_source_dir

info()    { printf '[*] %s\n' "$*"; }
success() { printf '[✓] %s\n' "$*"; }
warn()    { printf '[!] %s\n' "$*" >&2; }
fail()    { printf '[✗] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<USAGE
$PROJECT_NAME setup

Usage: bash setup.sh [options]

  One-shot remote install (no prior clone needed):
    curl -fsSL https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | sh
    wget -qO- https://raw.githubusercontent.com/Thaton3gu7/ProjectR/master/setup.sh | sh

Options:
  --command=<name>       Launcher command name (default: project)
  --install-dir=<path>   Hidden install location (default: ~/.local/share/projectr)
  --bin-dir=<path>       Directory for launcher (default: ~/.local/bin)
  --add-path             Add the bin dir to common shell rc files when missing
  -h, --help             Show this help

Environment overrides:
  PROJECTR_COMMAND_NAME  Same as --command
  PROJECTR_INSTALL_DIR   Same as --install-dir
  PROJECTR_BIN_DIR       Same as --bin-dir
  PROJECTR_REPO_URL      Git remote to clone (default: $PROJECTR_REPO_URL)

Examples:
  bash setup.sh         - To setup launcher in default mode
  project               - To run interactive mode via launcher name
  project --help        - To see this help menu
  project --install=git - Installs git non-interactively
  project --self-update - Updates ProjectR via github
USAGE
}

expand_path() {
    local path="$1"
    case "$path" in
        '~') printf '%s\n' "$HOME" ;;
        '~/'*) printf '%s/%s\n' "$HOME" "${path#~/}" ;;
        *) printf '%s\n' "$path" ;;
    esac
}

require_commands() {
    local missing=()
    local cmd
    for cmd in tar mktemp mkdir rm mv chmod dirname basename; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing required setup command(s): ${missing[*]}"
    fi
}

ensure_dir_with_fallback() {
    local requested="$1"
    local fallback="$2"
    local label="$3"

    if mkdir -p "$requested" 2>/dev/null; then
        printf '%s\n' "$requested"
        return 0
    fi

    warn "Could not create $label directory: $requested"
    warn "Falling back to: $fallback"

    if mkdir -p "$fallback" 2>/dev/null; then
        printf '%s\n' "$fallback"
        return 0
    fi

    fail "Could not create $label directory at either '$requested' or '$fallback'."
}

# ---------------------------------------------------------------------------
# Remote-mode: clone ProjectR into the install directory
# ---------------------------------------------------------------------------
clone_project_remote() {
    info "Remote mode detected — no local checkout found."
    info "Cloning $PROJECT_NAME from $PROJECTR_REPO_URL ..."

    # We need git or curl+tar for this
    if command -v git >/dev/null 2>&1; then
        _clone_with_git
    elif command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        _clone_with_archive
    else
        fail "Neither git nor curl/wget are available. Install git and retry."
    fi
}

_clone_with_git() {
    local clone_target="$INSTALL_DIR"

    # If there is already a clone there, try to update it
    if [[ -d "$clone_target/.git" ]]; then
        info "Existing clone found at $clone_target — pulling latest changes ..."
        git -C "$clone_target" pull --ff-only 2>/dev/null \
            || warn "Fast-forward pull failed; continuing with existing checkout."
    else
        # Remove any non-git remnants so the clone succeeds
        if [[ -d "$clone_target" ]]; then
            local backup="${clone_target}.bak.$$"
            mv "$clone_target" "$backup" || fail "Could not move old install directory."
            trap "rm -rf '$backup'" EXIT
        fi

        mkdir -p "$(dirname "$clone_target")" 2>/dev/null || true
        git clone --depth 1 "$PROJECTR_REPO_URL" "$clone_target" \
            || fail "git clone failed. Check your network and the repo URL."

        if [[ -n "${backup:-}" ]]; then
            rm -rf "$backup"
            trap - EXIT
        fi
    fi

    SOURCE_DIR="$clone_target"
}

_clone_with_archive() {
    # Derive a tarball URL from the git URL
    local archive_url="${PROJECTR_REPO_URL%.git}"
    archive_url="${archive_url}/archive/refs/heads/master.tar.gz"
    local tmp_archive tmp_extract

    tmp_archive="$(mktemp "${TMPDIR:-/tmp}/projectr-archive.XXXXXX.tar.gz")"
    tmp_extract="$(mktemp -d "${TMPDIR:-/tmp}/projectr-extract.XXXXXX")"
    trap "rm -rf '$tmp_archive' '$tmp_extract'" EXIT

    info "Downloading $PROJECT_NAME archive ..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$tmp_archive" "$archive_url" \
            || fail "Failed to download archive from $archive_url"
    else
        wget -qO "$tmp_archive" "$archive_url" \
            || fail "Failed to download archive from $archive_url"
    fi

    tar -xzf "$tmp_archive" -C "$tmp_extract" --strip-components=1 \
        || fail "Failed to extract archive."

    # Move extracted files into install dir
    if [[ -d "$INSTALL_DIR" ]]; then
        local backup="${INSTALL_DIR}.bak.$$"
        mv "$INSTALL_DIR" "$backup" || fail "Could not move old install directory."
    fi

    mkdir -p "$(dirname "$INSTALL_DIR")" 2>/dev/null || true
    mv "$tmp_extract" "$INSTALL_DIR" || fail "Could not move extracted files into $INSTALL_DIR"

    if [[ -n "${backup:-}" ]]; then
        rm -rf "$backup"
    fi

    rm -f "$tmp_archive"
    trap - EXIT

    SOURCE_DIR="$INSTALL_DIR"
}

write_metadata() {
    local metadata_file="$INSTALL_DIR/.projectr-install"
    {
        printf 'PROJECTR_SOURCE_DIR=%q\n' "$SOURCE_DIR"
        printf 'PROJECTR_INSTALL_DIR=%q\n' "$INSTALL_DIR"
        printf 'PROJECTR_BIN_DIR=%q\n' "$BIN_DIR"
        printf 'PROJECTR_COMMAND_NAME=%q\n' "$COMMAND_NAME"
        printf 'PROJECTR_INSTALLED_AT=%q\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
        printf 'PROJECTR_REMOTE_MODE=%q\n' "$REMOTE_MODE"
    } > "$metadata_file"
}

copy_project() {
    local install_parent tmp_dir backup_dir
    install_parent="$(dirname "$INSTALL_DIR")"

    # If setup is being run from the installed copy, avoid deleting the source while
    # this script is running. Users can rerun setup from their original checkout or
    # use the launcher's --self-update command when metadata points at that checkout.
    if [[ "$SOURCE_DIR" == "$(cd "$install_parent" && pwd -P)/$(basename "$INSTALL_DIR")" ]]; then
        info "Setup is running from the installed copy; skipping app-file refresh."
        return 0
    fi

    tmp_dir="$(mktemp -d "${install_parent}/projectr.XXXXXX")"
    backup_dir=""

    cleanup_tmp() { rm -rf "$tmp_dir"; }
    trap cleanup_tmp EXIT

    info "Copying app files from: $SOURCE_DIR"
    tar -C "$SOURCE_DIR" \
        --exclude='.git' \
        --exclude='./log/*.log' \
        --exclude='./log/*.tmp' \
        -cf - . | tar -C "$tmp_dir" -xf -

    if [[ -d "$INSTALL_DIR" ]]; then
        backup_dir="${INSTALL_DIR}.bak.$$"
        mv "$INSTALL_DIR" "$backup_dir" || fail "Could not move old install out of the way: $INSTALL_DIR"
    fi

    if mv "$tmp_dir" "$INSTALL_DIR"; then
        trap - EXIT
        if [[ -n "$backup_dir" ]]; then
            rm -rf "$backup_dir"
        fi
        return 0
    else
        warn "Install refresh failed while moving new files into place."
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
        [[ -n "$backup_dir" ]] && mv "$backup_dir" "$INSTALL_DIR" 2>/dev/null || true
        fail "Install refresh failed; previous install was restored if it existed."
    fi
}

write_launcher() {
    local launcher="$BIN_DIR/$COMMAND_NAME"

    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        printf 'PROJECTR_HOME=%q\n' "$INSTALL_DIR"
        printf 'PROJECTR_SOURCE_DIR=%q\n' "$SOURCE_DIR"
        printf 'PROJECTR_BIN_DIR=%q\n' "$BIN_DIR"
        printf 'PROJECTR_COMMAND_NAME=%q\n' "$COMMAND_NAME"
        echo 'export PROJECTR_LAUNCHER_NAME="$(basename "$0")"'
        echo ''
        echo 'case "${1:-}" in'
        echo '  --self-update|--projectr-update)'
        echo '    if [[ -d "$PROJECTR_SOURCE_DIR/.git" ]]; then'
        echo '      echo "[*] Pulling latest changes ..."'
        echo '      git -C "$PROJECTR_SOURCE_DIR" pull --ff-only || { echo "[!] Pull failed." >&2; exit 1; }'
        echo '    fi'
        echo '    if [[ -f "$PROJECTR_SOURCE_DIR/setup.sh" ]]; then'
        echo '      exec bash "$PROJECTR_SOURCE_DIR/setup.sh" --command="$PROJECTR_COMMAND_NAME" --install-dir="$PROJECTR_HOME" --bin-dir="$PROJECTR_BIN_DIR"'
        echo '    fi'
        echo '    echo "[!] Original ProjectR checkout was not found: $PROJECTR_SOURCE_DIR" >&2'
        echo '    echo "    Re-clone ProjectR or rerun setup.sh from a valid checkout." >&2'
        echo '    exit 1'
        echo '    ;;'
        echo '  --setup-info|--projectr-info)'
        echo '    echo "ProjectR launcher: $PROJECTR_LAUNCHER_NAME"'
        echo '    echo "Installed app:     $PROJECTR_HOME"'
        echo '    echo "Original checkout: $PROJECTR_SOURCE_DIR"'
        echo '    echo "Launcher dir:      $PROJECTR_BIN_DIR"'
        echo '    exit 0'
        echo '    ;;'
        echo 'esac'
        echo ''
        echo 'exec bash "$PROJECTR_HOME/main.sh" "$@"'
    } > "$launcher" || fail "Could not write launcher: $launcher"

    chmod +x "$launcher" || fail "Could not make launcher executable: $launcher"
}

maybe_add_path() {
    local do_add="$ADD_PATH"

    # In remote mode, always try to add PATH (the user expects a turnkey install)
    if (( REMOTE_MODE )); then
        do_add=1
    fi

    if (( ! do_add )) || [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        return 0
    fi

    local rc marker
    marker="export PATH=\"$BIN_DIR:\$PATH\""
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        [[ -e "$rc" || "$rc" == "$HOME/.bashrc" ]] || continue
        touch "$rc" || { warn "Could not update shell rc file: $rc"; continue; }
        if ! grep -F "$marker" "$rc" >/dev/null 2>&1; then
            printf '\n# ProjectR launcher\n%s\n' "$marker" >> "$rc" || warn "Could not append PATH update to: $rc"
        fi
    done
}

# ---------------------------------------------------------------------------
# Parse CLI arguments
# ---------------------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --command=*) COMMAND_NAME="${arg#--command=}" ;;
        --install-dir=*) INSTALL_DIR="${arg#--install-dir=}" ;;
        --bin-dir=*) BIN_DIR="${arg#--bin-dir=}" ;;
        --add-path) ADD_PATH=1 ;;
        -h|--help) usage; exit 0 ;;
        *) warn "Unknown setup option: $arg"; usage; exit 1 ;;
    esac
done

COMMAND_NAME="$(basename "$COMMAND_NAME")"
INSTALL_DIR="$(expand_path "$INSTALL_DIR")"
BIN_DIR="$(expand_path "$BIN_DIR")"

if [[ ! "$COMMAND_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
    fail "Invalid command name: $COMMAND_NAME"
fi

require_commands

# ---------------------------------------------------------------------------
# Remote mode: clone first, then proceed like a local setup
# ---------------------------------------------------------------------------
if (( REMOTE_MODE )); then
    info ""
    info "╔══════════════════════════════════════════════════╗"
    info "║   ProjectR — One-Shot Remote Installer          ║"
    info "╚══════════════════════════════════════════════════╝"
    info ""

    INSTALL_PARENT="$(dirname "$INSTALL_DIR")"
    INSTALL_PARENT="$(ensure_dir_with_fallback "$INSTALL_PARENT" "$HOME/.projectr-app" "install parent")"
    if [[ "$INSTALL_PARENT" != "$(dirname "$INSTALL_DIR")" ]]; then
        INSTALL_DIR="$INSTALL_PARENT/projectr"
    fi

    BIN_DIR="$(ensure_dir_with_fallback "$BIN_DIR" "$HOME/bin" "launcher bin")"

    clone_project_remote

    # After cloning, SOURCE_DIR is now set — verify it looks right
    if [[ ! -f "$SOURCE_DIR/main.sh" || ! -d "$SOURCE_DIR/lib" ]]; then
        fail "Clone succeeded but the repository doesn't look like a valid ProjectR checkout."
    fi

    chmod +x "$SOURCE_DIR/main.sh" 2>/dev/null || true
    write_metadata
    write_launcher
    maybe_add_path

    success "$PROJECT_NAME installed via remote one-shot setup."
    printf '    App files: %s\n' "$INSTALL_DIR"
    printf '    Launcher:  %s\n' "$BIN_DIR/$COMMAND_NAME"
    printf '    Source:    %s\n\n' "$SOURCE_DIR"
    cat <<DONE
Run:
    $COMMAND_NAME
    $COMMAND_NAME --help
    $COMMAND_NAME --install=git
    $COMMAND_NAME --self-update    # pull latest changes and refresh
    $COMMAND_NAME --setup-info     # show install/source paths
DONE

    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        cat <<PATH_NOTE

[!] $BIN_DIR is not currently in PATH for this shell.
    Run this once now:
        export PATH="$BIN_DIR:\$PATH"

    Or open a new terminal — your shell rc file has been updated.

    Then use: $COMMAND_NAME
PATH_NOTE
    fi

    exit 0
fi

# ---------------------------------------------------------------------------
# Local mode: original behaviour (run from a cloned checkout)
# ---------------------------------------------------------------------------
if [[ ! -f "$SOURCE_DIR/main.sh" || ! -d "$SOURCE_DIR/lib" ]]; then
    fail "setup.sh must be run from a valid ProjectR checkout."
fi

INSTALL_PARENT="$(dirname "$INSTALL_DIR")"
INSTALL_PARENT="$(ensure_dir_with_fallback "$INSTALL_PARENT" "$HOME/.projectr-app" "install parent")"
if [[ "$INSTALL_PARENT" != "$(dirname "$INSTALL_DIR")" ]]; then
    INSTALL_DIR="$INSTALL_PARENT/projectr"
fi

BIN_DIR="$(ensure_dir_with_fallback "$BIN_DIR" "$HOME/bin" "launcher bin")"

copy_project
chmod +x "$INSTALL_DIR/main.sh" 2>/dev/null || warn "Could not mark main.sh executable; launcher will still run it with bash."
write_metadata
write_launcher
maybe_add_path

success "$PROJECT_NAME command installed."
printf '    App files: %s\n' "$INSTALL_DIR"
printf '    Launcher:  %s\n' "$BIN_DIR/$COMMAND_NAME"
printf '    Source:    %s\n\n' "$SOURCE_DIR"
cat <<DONE
Run:
    $COMMAND_NAME
    $COMMAND_NAME --help
    $COMMAND_NAME --install=git
    $COMMAND_NAME --self-update    # refresh hidden app files from the original checkout
    $COMMAND_NAME --setup-info     # show install/source paths
DONE

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    cat <<PATH_NOTE

[!] $BIN_DIR is not currently in PATH for this shell.
    Run this once now:
        export PATH="$BIN_DIR:\$PATH"

    Or rerun setup with:
        bash setup.sh --add-path

    Then open a new terminal and use: $COMMAND_NAME
PATH_NOTE
fi
