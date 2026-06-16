# Changelog

All notable changes to ProjectR are documented here.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

ProjectR is available on [GitHub](https://github.com/ThatOn3Gu7/ProjectR) and [GitLab](https://gitlab.com/Thaton3gu7/ProjectR).

---

## [Unreleased]

### Added

- Source-safe Bash library entrypoint at `lib/projectr.sh`, exposing ProjectR as a reusable API without starting the CLI or mutating user files at source time.
- Public library APIs for registry lookup, package-manager detection, manager-aware command/package resolution, install planning, profile diffing, state verification, and explicit install/uninstall wrappers.
- Library documentation in `docs/api.md` and a staged design roadmap in `docs/library_roadmap.md`.
- Runnable library examples in `examples/library_list_tools.sh` and `examples/library_dry_run.sh`.
- `tests/library_smoke.sh` to verify source safety, JSON output, plugin index invalidation, and dry-run planning from the library API.
- Performance optimization documentation in `docs/performance_optimization.md`, including validation commands, benchmark snapshot, and maintenance notes.
- Fast read-only startup path in `main.sh` for `--help`, `-h`, `help`, `--version`, `-v`, and `version`.
- Lazy tool registry lookup index in `lib/data/tools.sh` for command/package/display-name resolution.
- Process-local command lookup cache helpers in `lib/core/strict_mode.sh`: `projectr_command_exists`, `projectr_command_path`, and `projectr_command_cache_clear`.
- Loop-friendly `*_into` metadata helpers in `lib/data/tool_meta.sh` to avoid repeated command substitutions during registry scans.
- `view_tool_summary()` function in `lib/system/checker.sh` to display installed and missing tools at a glance after inspection.
- Interactive info modals and tactile cursor animations to `docs/index.html`.
- Separate `_show_help_panel()` function in `setup.sh` for the interactive menu help overlay.
- Repo trust checks — trusted remote validation for setup and update paths (`lib/security/verify.sh`).
- Plugin metadata support with safer overrides and compatibility checks (`lib/features/plugin_loader.sh`).
- Declarative profile config support, allowing profiles to drive extra setup behaviour for configured tools (`lib/features/profile_code.sh`, `lib/features/profile_manager.sh`).
- Scheduler support exposed through doctor and CLI (`lib/system/scheduler.sh`).
- Manager-aware install logic — install, uninstall, dry-run, and rollback now use manager-specific resolution (`lib/features/installer.sh`, `lib/features/uninstaller.sh`, `lib/features/dry_run.sh`).
- Unified runtime startup routing CLI and interactive runs through the same session and lock flow.
- Improved update and refresh flow supporting both git checkouts and installed launcher copies.
- Improved search install resolution using the shared manager resolver.
- MIT License.
- GitLab CI pipeline (`.gitlab-ci.yml`) with shellcheck, bats, and script validation stages.
- `CONTRIBUTING.md` with setup, testing, and contribution guidelines for both GitHub and GitLab.
- `docs/modules.md` per-module reference for all scripts under `lib/`.

### Changed

- Expanded `project --list=manager` / `project list manager` to show native, universal, and language ecosystem managers such as `pipx`, `pip3`, `npm`, `cargo`, `gem`, `go`, and `composer` in one table.
- Updated the library `projectr_detect_managers` helper to report all ProjectR-discoverable managers, including language ecosystem managers, instead of only native package managers.
- Enhanced the interactive tool inspection summary so installed tools are shown with display name, expected command, and detected version.
- Optimized `project list categories` to group category rows in a single registry pass instead of rescanning all tools once per category.
- Updated tool lookup flows in CLI, dry-run, install, uninstall, profile, search, checker, and state modules to use indexed registry helpers where available.
- Updated read-only installed-tool/version checks to use cached command probes and lighter Bash-native version parsing where practical.
- Updated `detect_pkg_manager` to cache completed detection, including `unknown`, avoiding repeated scans on unsupported systems.
- Refactored user-facing messages to formal wording and introduced messaging helpers.
- Expanded README and docs with new capabilities (update, self-update, profile-related changes).
- Redesigned `docs/index.html` interface.
- Expanded CI validation coverage for new runtime and doctor behaviour.

### Fixed

- Resolved all identified shellcheck warnings and functional bugs across the codebase.
- Fixed styling in `view_tool_summary()` display output.
- Removed `apply_message_helpers.sh` and `apply_helpers.sh` that were accidentally committed.
