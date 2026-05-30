#!/usr/bin/env bash
set -euo pipefail

# ProjectR command installer
# Copies the repo to a hidden user-level app directory and creates a `project`
# launcher so ProjectR can be run from any working directory.

COMMAND_NAME="${PROJECTR_COMMAND_NAME:-project}"
INSTALL_DIR="${PROJECTR_INSTALL_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/projectr}"
BIN_DIR="${PROJECTR_BIN_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ADD_PATH=0

usage() {
    cat <<USAGE
ProjectR setup

Usage: bash setup.sh [options]

Options:
  --command=<name>       Launcher command name (default: project)
  --install-dir=<path>   Hidden install location (default: ~/.local/share/projectr)
  --bin-dir=<path>       Directory for launcher (default: ~/.local/bin)
  --add-path             Add the bin dir to common shell rc files when missing
  -h, --help             Show this help

Examples:
  bash setup.sh
  project
  project --help
  project --install=git
USAGE
}

for arg in "$@"; do
    case "$arg" in
        --command=*) COMMAND_NAME="${arg#--command=}" ;;
        --install-dir=*) INSTALL_DIR="${arg#--install-dir=}" ;;
        --bin-dir=*) BIN_DIR="${arg#--bin-dir=}" ;;
        --add-path) ADD_PATH=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "[!] Unknown setup option: $arg" >&2; usage; exit 1 ;;
    esac
done

if [[ ! "$COMMAND_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "[!] Invalid command name: $COMMAND_NAME" >&2
    exit 1
fi

if [[ ! -f "$SOURCE_DIR/main.sh" || ! -d "$SOURCE_DIR/lib" ]]; then
    echo "[!] setup.sh must be run from a ProjectR checkout." >&2
    exit 1
fi

INSTALL_PARENT="$(dirname "$INSTALL_DIR")"
mkdir -p "$INSTALL_PARENT" "$BIN_DIR"

# If setup is being run from the installed copy, avoid deleting the source while
# this script is running. Otherwise, refresh the hidden app copy atomically.
if [[ "$SOURCE_DIR" != "$(cd "$INSTALL_PARENT" && pwd -P)/$(basename "$INSTALL_DIR")" ]]; then
    TMP_DIR="$(mktemp -d "${INSTALL_PARENT}/projectr.XXXXXX")"
    cleanup() { rm -rf "$TMP_DIR"; }
    trap cleanup EXIT

    tar -C "$SOURCE_DIR" \
        --exclude='.git' \
        --exclude='./log/*.log' \
        --exclude='./log/*.tmp' \
        -cf - . | tar -C "$TMP_DIR" -xf -

    rm -rf "$INSTALL_DIR"
    mv "$TMP_DIR" "$INSTALL_DIR"
    trap - EXIT
fi

chmod +x "$INSTALL_DIR/main.sh" 2>/dev/null || true

LAUNCHER="$BIN_DIR/$COMMAND_NAME"
{
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    printf 'PROJECTR_HOME=%q\n' "$INSTALL_DIR"
    echo 'export PROJECTR_LAUNCHER_NAME="$(basename "$0")"'
    echo 'exec bash "$PROJECTR_HOME/main.sh" "$@"'
} > "$LAUNCHER"
chmod +x "$LAUNCHER"

if (( ADD_PATH )) && [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -e "$rc" || "$rc" == "$HOME/.bashrc" ]] || continue
        touch "$rc"
        if ! grep -F "export PATH=\"$BIN_DIR:\$PATH\"" "$rc" >/dev/null 2>&1; then
            printf '\n# ProjectR launcher\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$rc"
        fi
    done
fi

cat <<DONE
[✓] ProjectR command installed.
    App files: $INSTALL_DIR
    Launcher:  $LAUNCHER

Run:
    $COMMAND_NAME
    $COMMAND_NAME --help
    $COMMAND_NAME --install=git
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
