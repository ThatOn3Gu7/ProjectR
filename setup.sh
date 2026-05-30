#!/usr/bin/env bash
set -euo pipefail

# ProjectR command installer
# Copies the repo to a hidden user-level app directory and creates a `project`
# launcher so ProjectR can be run from any working directory.

PROJECT_NAME="ProjectR"
COMMAND_NAME="${PROJECTR_COMMAND_NAME:-project}"
DEFAULT_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/projectr"
DEFAULT_BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
INSTALL_DIR="${PROJECTR_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
BIN_DIR="${PROJECTR_BIN_DIR:-$DEFAULT_BIN_DIR}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ADD_PATH=0

info() { printf '[*] %s\n' "$*"; }
success() { printf '[✓] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
fail() { printf '[✗] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<USAGE
$PROJECT_NAME setup

Usage: bash setup.sh [options]

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

Examples:
  bash setup.sh
  project
  project --help
  project --install=git
  project --self-update
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

write_metadata() {
    local metadata_file="$INSTALL_DIR/.projectr-install"
    {
        printf 'PROJECTR_SOURCE_DIR=%q\n' "$SOURCE_DIR"
        printf 'PROJECTR_INSTALL_DIR=%q\n' "$INSTALL_DIR"
        printf 'PROJECTR_BIN_DIR=%q\n' "$BIN_DIR"
        printf 'PROJECTR_COMMAND_NAME=%q\n' "$COMMAND_NAME"
        printf 'PROJECTR_INSTALLED_AT=%q\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
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
    if (( ! ADD_PATH )) || [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        return 0
    fi

    local rc marker
    marker="export PATH=\"$BIN_DIR:\$PATH\""
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -e "$rc" || "$rc" == "$HOME/.bashrc" ]] || continue
        touch "$rc" || { warn "Could not update shell rc file: $rc"; continue; }
        if ! grep -F "$marker" "$rc" >/dev/null 2>&1; then
            printf '\n# ProjectR launcher\n%s\n' "$marker" >> "$rc" || warn "Could not append PATH update to: $rc"
        fi
    done
}

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

if [[ ! -f "$SOURCE_DIR/main.sh" || ! -d "$SOURCE_DIR/lib" ]]; then
    fail "setup.sh must be run from a valid ProjectR checkout."
fi

require_commands

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
    $COMMAND_NAME --setup-info      # show install/source paths
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
