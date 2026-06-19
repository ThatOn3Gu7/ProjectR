# ProjectR
<div align="center">
  
![Bash](https://img.shields.io/badge/Bash-4.4%2B-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Termux-0078D4?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![Tools](https://img.shields.io/badge/Tools-240%2B-a855f7?style=flat-square)

</div>

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
- **Registry audit checks** for validating tool IDs, install types, duplicates, and special installer references.
- **Presets** for installing curated groups of tools.
- **Install-by-name search** that can look in ProjectR's registry first and then search supported managers.
- **Uninstall workflows** for system packages and language ecosystem packages.
- **Dry-run, registry audit, and undo support** for safer testing, review, and rollback.
- **Profile export/import** to recreate installed ProjectR-managed tools later.
- **Structured logging and session history** for troubleshooting, including command starts, successes, failures, exit codes, and diagnostic output tails.
- **Connectivity, dependency, and disk checks** before heavier install operations.
- **Special setup helpers** for tools that need more than a package install, such as Neovim, Zsh/Oh My Zsh, and code-server.
- **Doctor command** (`project doctor`) for health checks of the environment, package‑manager detection, and required privileges, with optional `--json` output.
- **Verify and repair** (`project verify`, `project repair`) to check installed tools on `$PATH` and reinstall missing non‑special tools.
- **State database** (`~/.local/state/projectr/state.db`) tracking installed tools; queryable via `project list state`.
- **Self‑update** (`project --self-update` or `project update`) to refresh the hidden installed copy or update the git checkout.
- **Scheduler integration** and background job handling via related flags.
- **Plugin system** allowing custom tool definitions via TOML files placed in `tools.d/`.
- **Undo** (`project --undo`) to roll back the last recorded install session.
- **Log retrieval** (`project --log`, `project --log=N`) to view recent install logs.
- **Lock file** (`~/.config/projectr/tmp/project.lock`) preventing concurrent runs.


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

## Performance notes

This build includes a focused performance pass for read-only and lookup-heavy paths:

- `project --help` and `project --version` use an early fast path in `main.sh`, so they no longer load every installer, scheduler, profile, and TUI module before printing static information.
- Tool lookup by command, package name, or display name is backed by a lazy registry index in `lib/data/tools.sh`. The pipe-delimited `TOOLS` array remains the source of truth, and the index is rebuilt automatically when plugin tools are appended.
- Repeated command availability probes in list, dry-run, checker, state verification, and profile export flows use a process-local command lookup cache from `lib/core/strict_mode.sh` where safe.
- Manager-specific command/package overrides can now be resolved through `*_into` helper functions in `lib/data/tool_meta.sh`, reducing subshell command substitutions inside loops.
- `project list categories` groups rows in one pass instead of rescanning the full registry once per category.
- Version parsing in read-only inspection paths now uses Bash pattern matching instead of spawning extra `grep`, `head`, and `cut` processes.

Approximate median timings from the review sandbox, 7 fresh processes per command:

| Command | Original | Optimized | Notes |
|---|---:|---:|---|
| `bash main.sh --version` | 0.064s | 0.006s | Early fast path. |
| `bash main.sh --help` | 0.068s | 0.010s | Early fast path. |
| `bash main.sh --list=categories` | 0.589s | 0.322s | Single-pass grouping and cached command checks. |
| `bash main.sh --list=installed` | 0.690s | 0.496s | Cached command checks and cheaper version parsing. |

Timings vary by shell, filesystem, installed tools, and terminal environment; use them as directional validation rather than absolute guarantees.

---

## Use ProjectR as a Bash library

ProjectR can now be sourced by other Bash scripts through a stable, source-safe API:

```bash
source "/path/to/ProjectR/lib/projectr.sh"

projectr_init --no-plugins
projectr_detect_manager
projectr_tool_lookup git
projectr_tool_get git name
projectr_tool_status git || true
projectr_plan_install git --json
```

The library entrypoint is intentionally different from `main.sh`:

- `main.sh` is the CLI application and may dispatch commands or enter the interactive menu.
- `lib/projectr.sh` is the reusable API layer and does not parse your script arguments, start the menu, install packages, acquire locks, or create config/state/log files just by being sourced.

Useful API areas include:

- registry lookups: `projectr_tool_lookup`, `projectr_tool_get`, `projectr_tool_list`, `projectr_tool_json`;
- package-manager detection: `projectr_detect_manager`, `projectr_detect_managers`, `projectr_detect_language_manager`;
- manager-aware metadata: `projectr_tool_effective_cmd`, `projectr_tool_effective_package`, `projectr_tool_installed`;
- planning: `projectr_plan_install`, `projectr_plan_profile`;
- explicit mutating wrappers: `projectr_install_tool`, `projectr_uninstall_tool`.

Full documentation is available in [`docs/api.md`](docs/api.md), and runnable examples live in `examples/`:

```bash
bash examples/library_list_tools.sh
bash examples/library_dry_run.sh git curl jq
bash tests/library_smoke.sh
```

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

`project --self-update` reruns the original checkout's `setup.sh` with the same command name, install directory, and launcher directory. In current v2 behavior it runs in a non-interactive refresh mode, so the setup menu does not appear during self-update.

When you run `project update` from an installed launcher copy, ProjectR now refreshes the hidden installed app too. It prefers the original git checkout when it still exists, and falls back to updating the installed copy directly from the configured GitHub repo URL when needed.

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
project diff --profile projectr.yml
project list tools
project doctor --json

# Equivalent flag style
project --install git
project --install=git
project --profile projectr.yml
project --list tools
project --list=tools
project --dry-run git --json
project --diff-profile projectr.yml --json
project --doctor --json
project audit --strict
```

### Logging and troubleshooting

ProjectR writes a structured troubleshooting log to `log/install.log` in the project directory. The log records CLI dispatches, startup context, install/uninstall command starts, successes, failures, exit codes, durations, doctor/audit results, dry-run plans, and the tail of command output when failures happen.

```bash
project --log
project --log=100
```

Logs rotate automatically when they grow large, keeping recent rotated files beside `install.log`.

### Tool database audit

ProjectR's built-in tool database can be checked without installing anything:

```bash
project audit
project audit --strict
```

The audit validates required fields, duplicate IDs or names, supported install types, and special installer functions. Use `--strict` in CI to fail on warnings as well as errors.

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

Preview how a profile compares with the current machine before installing it:

```bash
project diff --profile projectr.yml
project --diff-profile=projectr.yml --json
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

`project doctor` checks PATH, core dependencies, package manager detection, privilege capabilities, scheduler status, state database support, and log writability. Add `--json` for CI or bug reports.

`project update` now has two behaviors:

- **inside a real git checkout**: it performs a fast-forward git update and prints a git-log summary of applied commits.
- **from an installed launcher copy**: it refreshes the hidden installed app directory. It prefers the original checkout if it still exists, and otherwise falls back to the configured GitHub repo URL.


| Flag | What it does |
| --- | --- |
| `-h`, `--help` | Show available flags and examples. |
| `-v`, `--version` | Print the ProjectR version. |
| `--list <target>`, `--list=<target>` | Show `tools`, `installed`, `categories`, `manager`, or `state`. |
| `--search <name>`, `--search=<name>` | Search ProjectR and supported package managers for a package name. |
| `--install <name>`, `--install=<name>` | Install a tool non-interactively. |
| `--source <manager>`, `--source=<manager>` | Force a specific install/search source manager when supported. |
| `--uninstall <name>`, `--uninstall=<name>` | Uninstall a tool non-interactively. |
| `--log`, `--log <n>`, `--log=<n>` | Print recent install log lines. |
| `--reset` | Clear saved ProjectR preferences. |
| `--export` | Export a profile of currently installed ProjectR tools. |
| `--export-lock` | Export a richer YAML lockfile with versions and managers. |
| `--import <file>`, `--import=<file>` | Install tools listed in an exported profile. |
| `--diff-profile <file>`, `--diff-profile=<file>` | Compare a YAML/TOML profile with the current machine. |
| `--doctor [--json]` | Run health checks, optionally as JSON for CI/bug reports. |
| `--dry-run [tool\|all] [--json]` | Simulate package changes without installing anything. |
| `--undo` | Undo the last recorded ProjectR install session. |

Launcher-only helper flags:

| Flag | What it does |
| --- | --- |
| `--self-update`, `--projectr-update` | Refresh the hidden installed copy in non-interactive mode. |
| `update`, `--update` | Update the current git checkout, or refresh the installed copy when run from the launcher. |
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
- Language ecosystems: `pip`, `pip3`, `pipx`, `npm`, `yarn`, `pnpm`, `bun`, `gem`, `cargo`, `go`, `composer`, plus recognized ecosystem tools such as `uv`, `poetry`, `pipenv`, `conda`, `mamba`, `bundler`, `luarocks`, `dotnet`, `nuget`, `opam`, `cabal`, `stack`, `mix`, and `rebar3`

Check your current system with:

```bash
project --list=manager
```

The manager list now shows native system managers, universal app managers, and language ecosystem managers in one table. That means commands such as `pip3`, `pipx`, `npm`, `cargo`, `gem`, `go`, and `composer` are visible when present, even though ProjectR still keeps the OS-native manager as the primary install source for normal system packages. Some extra ecosystem tools are listed for environment visibility even when they are not yet first-class ProjectR install sources.

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

Released under the MIT License.
