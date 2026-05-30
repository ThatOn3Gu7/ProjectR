# ProjectR

ProjectR is a modular Bash terminal setup assistant. It gives you an interactive menu and command-line flags for installing, uninstalling, inspecting, and backing up common terminal tools across many Linux-style environments.

It is designed to stay readable and hackable: the main menu lives in `main.sh`, tool data lives in one registry file, and features are split into small scripts under `lib/`.

---

## What ProjectR does

ProjectR helps turn a fresh terminal into a usable workspace by combining:

- **Interactive installer menu** for picking tools by number.
- **Global `project` command setup** so the tool can be launched from any directory.
- **Non-interactive flags** for automation and quick installs.
- **Package manager detection** for Debian/Ubuntu, Termux, Arch, Fedora/RHEL, openSUSE, Alpine, Void, Gentoo, Nix, Guix, macOS/Homebrew, BSD-style systems, Windows package managers, Flatpak, and Snap.
- **Tool registry** with developer tools, minimal essentials, fun terminal apps, and OSINT utilities.
- **Presets** for installing curated groups of tools.
- **Install-by-name search** that can look in ProjectR's registry first and then search supported managers.
- **Uninstall workflows** for system packages and language ecosystem packages.
- **Dry-run and undo support** for safer testing and rollback.
- **Profile export/import** to recreate installed ProjectR-managed tools later.
- **Logging and session history** for troubleshooting.
- **Connectivity, dependency, and disk checks** before heavier install operations.
- **Special setup helpers** for tools that need more than a package install, such as Neovim, Zsh/Oh My Zsh, and code-server.

---

## Requirements

ProjectR is a Bash project and expects a normal Unix-like shell environment.

Required basics:

- Bash, preferably Bash 4+
- Standard shell utilities such as `tar`, `mkdir`, `mktemp`, `chmod`, `grep`, `sed`, and `awk`
- `curl` or `wget` for network checks and remote installers
- `ping` for connectivity checks
- Internet access for package installs
- A supported package manager for system package installs

Optional tools improve the experience:

- `whiptail` for a nicer preset menu
- `fzf` for fuzzy interactive search
- `lolcat` for rainbow menu output
- `sudo`/`doas` where your package manager needs elevated privileges

ProjectR is intended to work in minimal environments too, including Termux-style mobile terminals.

---

## Quick start

Clone the repo and run ProjectR directly:

```bash
git clone https://github.com/ThatOn3Gu7/ProjectR.git
cd ProjectR
bash main.sh
```

You can also run flags directly from the repo:

```bash
bash main.sh --help
bash main.sh --list=tools
bash main.sh --install=git
```

---

## Install the global `project` command

If you want ProjectR to behave more like a normal terminal command, run the setup script once from the cloned repo:

```bash
git clone https://github.com/ThatOn3Gu7/ProjectR.git
cd ProjectR
bash setup.sh
```

By default, setup will:

1. Copy ProjectR's app files into a hidden user app directory: `~/.local/share/projectr`.
2. Create a launcher command at: `~/.local/bin/project`.
3. Keep the original checkout path in install metadata so the launcher can refresh itself later.

After setup, you can run ProjectR from any directory:

```bash
project
project --help
project --install=git
project --list=tools
```

### Does `~/.local/share/projectr` update automatically?

No. ProjectR does **not** auto-sync on every run. That avoids surprising users by copying work-in-progress files or making every command slower.

To refresh the hidden installed copy after changing or pulling updates in your original cloned repo, use either of these:

```bash
# from anywhere, if you installed the launcher
project --self-update

# or from the original ProjectR checkout
bash setup.sh
```

`project --self-update` reruns the original checkout's `setup.sh` with the same command name, install directory, and launcher directory.

You can inspect where the launcher points with:

```bash
project --setup-info
```

### What if `~/.local` does not exist?

That is okay. `setup.sh` creates the needed directories with `mkdir -p`.

If the normal locations cannot be created, setup falls back to:

- install parent fallback: `~/.projectr-app/projectr`
- launcher fallback: `~/bin/project`

If both the normal path and fallback path fail, setup exits with an error instead of leaving a half-installed command.

### PATH setup

If `~/.local/bin` is not already in your `PATH`, run this once in your current shell:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

To have setup append that PATH line to common shell rc files, run:

```bash
bash setup.sh --add-path
```

Open a new terminal after using `--add-path`.

### Setup customization

You can choose another command name or install location:

```bash
bash setup.sh --command=projectr
bash setup.sh --install-dir="$HOME/.projectr"
bash setup.sh --bin-dir="$HOME/bin"
```

Environment variables work too:

```bash
PROJECTR_COMMAND_NAME=projectr bash setup.sh
PROJECTR_INSTALL_DIR="$HOME/.projectr" PROJECTR_BIN_DIR="$HOME/bin" bash setup.sh
```

---

## Command-line flags

ProjectR supports both professional subcommands and the original flags. These commands are available through either `bash main.sh ...` or the installed `project ...` launcher, and the same actions can be called with space-separated or equals-style flags.

```bash
# Command style
project install git
project install --profile projectr.yml
project install git --dry-run --json
project list tools
project doctor

# Equivalent flag style
project --install git
project --install=git
project --profile projectr.yml
project --list tools
project --list=tools
project --dry-run git --json
project --doctor
```

### Configuration as code

Commit a `projectr.yml` with your dotfiles or team bootstrap repo:

```yaml
tools:
  - git
  - curl
  - tmux
```

TOML is also supported:

```toml
tools = ["git", "curl", "tmux"]
```

Install the profile with:

```bash
project install --profile=projectr.yml
```

### Dry-run simulation

Use `project dry-run install <tool>` (or `project install <tool> --dry-run`) to get a planned change table without installing anything. Add `--json` for CI systems:

```bash
project dry-run install git --json
```

### Local state, verify, and repair

Successful installs are recorded in `~/.local/state/projectr/state.db` when `sqlite3` is available, with a TSV fallback otherwise. Use `project list state` to inspect the database, `project verify` to check managed tools on `PATH`, and `project repair` to reinstall missing non-special tools.

### Plugin tool definitions

Drop TOML files into `tools.d/*.toml` to extend ProjectR without editing `lib/data/tools.sh`:

```toml
cmd = "ripgrep"
pkg = "ripgrep"
name = "Ripgrep"
desc = "Fast recursive search"
type = "pkg"
extra = "-"
category = "Dev"
```

### Doctor and update

`project doctor` checks PATH, core dependencies, package manager detection, state database support, and log writability. `project update` runs a fast-forward git update and prints a clean git-log summary of any commits that were applied; if nothing changed, it explains that the checkout was already current.


| Flag | What it does |
| --- | --- |
| `-h`, `--help` | Show available flags and examples. |
| `-v`, `--version` | Print the ProjectR version. |
| `--list <target>`, `--list=<target>` | Show `tools`, `installed`, `categories`, `manager`, or `state`. |
| `--search <name>`, `--search=<name>` | Search ProjectR and supported package managers for a package name. |
| `--install <name>`, `--install=<name>` | Install a tool non-interactively. |
| `--uninstall <name>`, `--uninstall=<name>` | Uninstall a tool non-interactively. |
| `--log`, `--log <n>`, `--log=<n>` | Print recent install log lines. |
| `--reset` | Clear saved ProjectR preferences. |
| `--export` | Export a profile of currently installed ProjectR tools. |
| `--import <file>`, `--import=<file>` | Install tools listed in an exported profile. |
| `--dry-run [tool\|all] [--json]` | Simulate package changes without installing anything. |
| `--undo` | Undo the last recorded ProjectR install session. |

Launcher-only helper flags:

| Flag | What it does |
| --- | --- |
| `--self-update`, `--projectr-update` | Refresh the hidden installed copy from the original checkout. |
| `--setup-info`, `--projectr-info` | Show launcher, install, source, and bin paths. |

Examples:

```bash
project --list tools
project --list=tools
project --list manager
project --install tmux
project --install=tmux
project --uninstall tmux
project --search=rg
project --export
project --import=projectr_profile_2026-05-30.txt
project --undo
```

---

## Interactive menu

Running ProjectR without flags opens the main menu:

```bash
project
# or
bash main.sh
```

From the menu you can:

- Install individual tools by number.
- Enter several numbers separated by spaces for multi-install.
- Install all tools.
- Open the preset menu.
- Inspect installed tools.
- Open the uninstall menu.
- Search/install by package name.
- Exit cleanly with ProjectR's goodbye screen.

ProjectR uses a lock file under `~/.config/projectr/tmp/project.lock` so two ProjectR sessions do not run at the same time.

---

## Tool categories

The master tool registry is in `lib/data/tools.sh`. Current categories include:

- **Min**: baseline terminal essentials such as Curl, Wget, Htop, Python, Nano, Duf, Lsd, and Broot.
- **Dev**: developer workflow tools such as Git, OpenSSH, Ranger, Neovim, Croc, Fzf, Zoxide, Zsh, Yazi, Tmux, Lazygit, Node.js, GitHub CLI, code-server, and Pipx.
- **Fun**: terminal toys and visual tools such as Sl, Cbonsai, Asciinema, Asciiquarium, Wttr, Ani-cli, Pipes.sh, and Tty-clock.
- **OSINT**: tools such as Holehe.

To see the live list from your checkout:

```bash
project --list=tools
project --list=categories
```

---

## Presets

ProjectR includes curated presets for quick setup:

- **Minimal**: a smaller essential terminal environment.
- **Developer**: a fuller professional/developer-oriented workspace.
- **Fun**: terminal entertainment and visual tools.

Open presets from the interactive menu or use the preset menu entry. If `whiptail` is installed, ProjectR can show a dialog-style preset picker; otherwise it uses a text fallback.

---

## Package manager support

ProjectR detects package managers and chooses the best primary manager for the current OS family. It prioritizes native managers so, for example, Debian/Ubuntu-family systems prefer `apt` even if extra managers like Snap are also installed.

Known manager families include:

- Termux: `pkg`
- Debian/Ubuntu: `apt`, `apt-get`
- Arch: `pacman`
- Fedora/RHEL: `dnf`, `yum`
- openSUSE: `zypper`
- Alpine: `apk`
- Gentoo: `emerge`
- Void: `xbps`
- Nix/Guix: `nix`, `guix`
- Solus/Mageia/Slackware: `eopkg`, `urpmi`, `slackpkg`
- macOS/BSD: `brew`, `port`, BSD package tools
- Windows-style managers: `winget`, `choco`, `scoop`
- Universal app sources: `flatpak`, `snap`
- Language ecosystems: `pip`, `pip3`, `pipx`, `npm`, `yarn`, `pnpm`, `bun`, `gem`, `cargo`, `go`, `composer`

Check your current system with:

```bash
project --list=manager
```

---

## Safety and troubleshooting

ProjectR includes several guardrails:

- **Connectivity checks** before startup and bulk install paths.
- **Dependency checks** for required helper commands.
- **Disk-space checks** before larger preset installs.
- **Single-session lock** to avoid two installer sessions running together.
- **Install logging** under the ProjectR app/log directory.
- **Session history** so `--undo` can roll back the previous recorded installation session.
- **Dry-run mode** for checking install logic before making changes.
- **Setup rollback** when refreshing the hidden app copy fails: the previous install is restored if possible.
- **Setup fallbacks** if the default install or launcher directories cannot be created.

Useful troubleshooting commands:

```bash
project --setup-info
project --log
project --log=100
project --list=manager
project --dry-run --install=git
project --undo
```

---

## Profiles: export and import

Use profiles when you want to recreate a terminal setup later:

```bash
project --export
project --import=projectr_profile_2026-05-30.txt
```

Export scans the ProjectR registry and writes the commands it finds installed. Import reads that file, skips unknown/invalid lines, and installs missing registered tools.

---

## Project layout

```text
ProjectR/
├── main.sh                         # Entry point and main interactive menu
├── setup.sh                        # Optional global command installer
├── lib/
│   ├── core/                       # UI, colours, prompts, logging, spinner, progress
│   ├── data/                       # Config and master tool registry
│   ├── features/                   # Install, uninstall, search, presets, sync, profiles, undo
│   ├── flags/                      # Command-line flag dispatcher
│   ├── sub_menus/                  # Preset and uninstall menus
│   └── system/                     # OS/package-manager/dependency/network checks
└── log/                            # Runtime logs/session files in a repo checkout
```

When installed globally, runtime app files live under the chosen hidden install directory, while user preferences live under `~/.config/projectr`.

---

## Development notes

- Add or edit tools in `lib/data/tools.sh`.
- Keep tool entries in the existing pipe-delimited format: `NUM|CMD|PKG|NAME|DESC|TYPE|EXTRA|CAT`.
- Put reusable UI helpers in `lib/core/`.
- Put OS/package-manager logic in `lib/system/`.
- Put user-facing features in `lib/features/`.
- After changing files in your original checkout, run `project --self-update` or `bash setup.sh` to refresh the hidden installed copy.

---

## License

No license file is currently included. Add one before distributing ProjectR broadly.
