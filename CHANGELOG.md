# Changelog

All notable changes to ProjectR are documented here.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added

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

### Changed

- Refactored user-facing messages to formal wording and introduced messaging helpers.
- Expanded README and docs with new capabilities (update, self-update, profile-related changes).
- Redesigned `docs/index.html` interface.
- Expanded CI validation coverage for new runtime and doctor behaviour.

### Fixed

- Resolved all identified shellcheck warnings and functional bugs across the codebase.
- Fixed styling in `view_tool_summary()` display output.
- Removed `apply_message_helpers.sh` and `apply_helpers.sh` that were accidentally committed.
