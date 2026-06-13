# Module Reference

This document describes every module under `lib/` and its purpose.

ProjectR is available on [GitHub](https://github.com/ThatOn3Gu7/ProjectR) and [GitLab](https://gitlab.com/Thaton3gu7/ProjectR).

---

## `lib/core/` — Core Utilities

Foundational helpers used across the entire codebase.

| Script | Description |
|---|---|
| `array_context.sh` | Utilities for passing and manipulating arrays across function boundaries in Bash. |
| `cli.sh` | Command-line argument parsing and dispatch — routes flags and subcommands to the correct handler. |
| `colours.sh` | ANSI colour and formatting constants used for consistent terminal output styling. |
| `disk_inspector.sh` | Inspects available disk space and reports warnings when thresholds are exceeded before installs. |
| `display.sh` | High-level display helpers (banners, section headers, formatted tables) built on top of `colours.sh`. |
| `logging.sh` | Structured logging to `log/` with severity levels (INFO, WARN, ERROR, DEBUG). |
| `progress_bar.sh` | Renders an animated progress bar in the terminal during long-running operations. |
| `prompts.sh` | Interactive user prompt helpers (yes/no confirmations, text input, selection menus). |
| `session.sh` | Session state management — tracks the current run context and enforces single-instance locking. |
| `spinner.sh` | Displays an animated spinner for operations that do not have measurable progress. |
| `strict_mode.sh` | Enables Bash strict mode (`set -euo pipefail`) and sets up global error traps. |

---

## `lib/data/` — Data & Configuration

Static data definitions and runtime configuration.

| Script | Description |
|---|---|
| `config.sh` | Central configuration — defines paths, defaults, and environment variables used project-wide. |
| `tool_meta.sh` | Metadata registry for individual tools (version constraints, homepage, description, dependencies). |
| `tools.sh` | Master list of all supported tools and their associated package manager identifiers. |

---

## `lib/features/` — Feature Modules

High-level features exposed through the CLI and interactive menu.

| Script | Description |
|---|---|
| `configurator.sh` | Applies per-tool configuration files after installation. |
| `doctor.sh` | Runs a health check across installed tools and the runtime environment, reporting issues. |
| `dry_run.sh` | Simulates install/uninstall operations without making any real changes to the system. |
| `installer.sh` | Handles tool installation using the resolved package manager for the current system. |
| `plugin_loader.sh` | Discovers, validates, and loads external plugin scripts from `tools.d/`. |
| `post_install.sh` | Runs post-installation hooks (shell rc patching, PATH updates, symlink creation). |
| `presets.sh` | Manages named tool presets — curated groups of tools that can be installed together. |
| `profile_code.sh` | Generates and applies shell profile code snippets for configured tools. |
| `profile_manager.sh` | Manages declarative profile configs that drive extra setup behaviour per tool. |
| `search_install.sh` | Searches for a tool by name and resolves the correct install path via the shared manager resolver. |
| `snapshot.sh` | Creates and restores snapshots of the current tool installation state. |
| `special_setup.sh` | Handles tools that require non-standard, bespoke setup steps outside the normal install flow. |
| `state.sh` | Persists and queries the installation state of each tool (installed, pending, failed). |
| `sync.sh` | Synchronises the local tool state against a remote or shared configuration source. |
| `tool_audit.sh` | Audits installed tools for outdated versions, missing dependencies, or policy violations. |
| `undo_engine.sh` | Records reversible operations and provides rollback capability for installs and config changes. |
| `uninstaller.sh` | Handles tool removal using the resolved package manager, with optional config cleanup. |

---

## `lib/flags/` — CLI Flags

| Script | Description |
|---|---|
| `flags.sh` | Defines and parses all supported CLI flags, making them available as variables to other modules. |

---

## `lib/security/` — Security

| Script | Description |
|---|---|
| `verify.sh` | Validates trusted remote sources and performs integrity checks before executing remote content. |

---

## `lib/sub_menus/` — Interactive Sub-menus

TUI sub-menu screens rendered within the interactive mode.

| Script | Description |
|---|---|
| `presets_menu.sh` | Interactive menu for browsing, selecting, and applying tool presets. |
| `uninstall_menu.sh` | Interactive menu for selecting and confirming tools to uninstall. |

---

## `lib/system/` — System Layer

Low-level system detection, dependency management, and scheduling.

| Script | Description |
|---|---|
| `checker.sh` | Checks which tools are installed or missing and exposes `view_tool_summary()` for a consolidated report. |
| `daemon_checker.sh` | Detects and reports on background daemons or services required by managed tools. |
| `dependencies.sh` | Resolves and installs system-level dependencies required before a tool can be set up. |
| `detect.sh` | Detects the current OS, distribution, architecture, and shell environment. |
| `network.sh` | Checks network connectivity and validates reachability of required remote endpoints. |
| `privilege.sh` | Handles privilege escalation (sudo/doas) and checks for required permissions before operations. |
| `resolver.sh` | Resolves the appropriate package manager (apt, brew, dnf, pacman, etc.) for the current system. |
| `scheduler.sh` | Manages scheduled tasks (cron/systemd timers) for automated tool updates and health checks. |
