# Module Reference

This document describes every module under `lib/` and its purpose.

ProjectR is available on [GitHub](https://github.com/ThatOn3Gu7/ProjectR) and [GitLab](https://gitlab.com/Thaton3gu7/ProjectR).

Additional documentation added by recent architecture work:

- [`api.md`](api.md) documents the source-safe Bash library API exposed through `lib/projectr.sh`.
- [`library_roadmap.md`](library_roadmap.md) explains the roadmap and design rules for making ProjectR usable as a library.
- [`performance_optimization.md`](performance_optimization.md) documents the startup, registry-indexing, command-cache, and validation changes.

---

## `lib/projectr.sh` — Source-safe library entrypoint

`lib/projectr.sh` exposes ProjectR as a reusable Bash library. It is safe to source from external scripts and loads only the minimal read-only registry/detection layer by default. Optional modules such as plugins, dry-run planning, profile parsing, state, installer, and uninstaller support are lazy-loaded through `projectr_library_load` or public wrapper functions.

The public API includes registry helpers (`projectr_tool_lookup`, `projectr_tool_list`, `projectr_tool_get`), manager helpers (`projectr_detect_manager`, `projectr_tool_effective_package`), planning helpers (`projectr_plan_install`), state wrappers, and explicit mutating wrappers (`projectr_install_tool`, `projectr_uninstall_tool`). See [`api.md`](api.md) for complete usage.

---

## `lib/core/` — Core Utilities

Foundational helpers used across the entire codebase.

| Script | Description |
|---|---|
| `array_context.sh` | Utilities for passing and manipulating arrays across function boundaries in Bash. |
| `cli.sh` | Command-line helper layer for routing command arguments; now uses the lazy tool lookup index when resolving tool names. |
| `colours.sh` | ANSI colour and formatting constants used for consistent terminal output styling. |
| `disk_inspector.sh` | Inspects available disk space and reports warnings when thresholds are exceeded before installs. |
| `display.sh` | High-level display helpers (banners, section headers, formatted tables) built on top of `colours.sh`. |
| `logging.sh` | Structured logging to `log/` with severity levels (INFO, WARN, ERROR, DEBUG). |
| `progress_bar.sh` | Renders an animated progress bar in the terminal during long-running operations. |
| `prompts.sh` | Interactive user prompt helpers (yes/no confirmations, text input, selection menus). |
| `session.sh` | Session state management — tracks the current run context and enforces single-instance locking. |
| `spinner.sh` | Displays an animated spinner for operations that do not have measurable progress. |
| `strict_mode.sh` | Strict-mode helper wrappers plus process-local command lookup caching via `projectr_command_exists` and `projectr_command_path`. |

---

## `lib/data/` — Data & Configuration

Static data definitions and runtime configuration.

| Script | Description |
|---|---|
| `config.sh` | Central configuration — defines paths, defaults, and environment variables used project-wide. |
| `tool_meta.sh` | Manager-specific package and command override registry; includes stdout-returning helpers and `*_into` helpers for loop-friendly resolution without subshell command substitutions. |
| `tools.sh` | Master list of all supported tools and package identifiers; includes the lazy registry index used for command/package/display-name lookup. |

---

## `lib/features/` — Feature Modules

High-level features exposed through the CLI and interactive menu.

| Script | Description |
|---|---|
| `configurator.sh` | Applies per-tool configuration files after installation. |
| `doctor.sh` | Runs a health check across installed tools and the runtime environment, reporting issues. |
| `dry_run.sh` | Simulates install/uninstall operations without making changes; uses indexed tool lookup and cached command checks for faster plans. |
| `installer.sh` | Handles tool installation using the resolved package manager; preset and batch paths now use indexed registry/metadata helpers. |
| `plugin_loader.sh` | Discovers, validates, and loads data-only TOML plugin definitions from `tools.d/`; invalidates the registry index after appending plugin tools. |
| `post_install.sh` | Runs post-installation hooks (shell rc patching, PATH updates, symlink creation). |
| `presets.sh` | Manages named tool presets — curated groups of tools that can be installed together. |
| `profile_code.sh` | Parses profile-as-code files and produces profile diffs; uses indexed lookups and manager-aware command checks. |
| `profile_manager.sh` | Manages profile export/import workflows; export/import paths use cached command checks and indexed registry lookups. |
| `search_install.sh` | Searches for a tool by name and resolves the correct install path via the shared manager resolver. |
| `snapshot.sh` | Creates and restores snapshots of the current tool installation state. |
| `special_setup.sh` | Handles tools that require non-standard, bespoke setup steps outside the normal install flow. |
| `state.sh` | Persists, queries, verifies, and repairs installation state; registry matching and command-path checks now use indexed/cached helpers where safe. |
| `sync.sh` | Synchronises the local tool state against a remote or shared configuration source. |
| `tool_audit.sh` | Audits installed tools for outdated versions, missing dependencies, or policy violations. |
| `undo_engine.sh` | Records reversible operations and provides rollback capability for installs and config changes. |
| `uninstaller.sh` | Handles tool removal using the resolved package manager, with manager-aware metadata helper resolution and optional config cleanup. |

---

## `lib/flags/` — CLI Flags

| Script | Description |
|---|---|
| `flags.sh` | Central CLI/subcommand dispatcher and read-only list renderers; optimized list/category/install/uninstall target resolution with cached/indexed helpers. |

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
| `checker.sh` | Checks which tools are installed or missing, using cached command lookups during full scans, and exposes `view_tool_summary()` with installed-tool versions plus missing-tool command names. |
| `daemon_checker.sh` | Detects and reports on background daemons or services required by managed tools. |
| `dependencies.sh` | Resolves and installs system-level dependencies required before a tool can be set up. |
| `detect.sh` | Detects the current OS, distribution, architecture, shell environment, and package manager; caches completed detection including `unknown` results. |
| `network.sh` | Checks network connectivity and validates reachability of required remote endpoints. |
| `privilege.sh` | Handles privilege escalation (sudo/doas) and checks for required permissions before operations. |
| `resolver.sh` | Resolves the appropriate package manager for the current system and exposes candidate native/language managers for search, library, and manager-list features. |
| `scheduler.sh` | Manages scheduled tasks (cron/systemd timers) for automated tool updates and health checks. |
