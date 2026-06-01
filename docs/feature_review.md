# ProjectR feature and database review

This review focuses on ProjectR's tool database (`lib/data/tools.sh`) and the install/uninstall logic that consumes it.

## Inspiration from comparable projects

- **chezmoi**: machine-specific templates, encrypted secrets, password-manager integrations, dry-run/apply workflow, and repeatable bootstrap flows.
- **Dotbot**: small declarative config, idempotent runs, simple plugin model, and low dependency footprint.
- **Modern dotfiles bootstraps**: profile-based package groups, multi-manager installation, health checks, and CI-friendly validation.

## High-impact feature ideas

1. **Registry audit in CI** — now started with `projectr audit --strict`; wire it into GitHub Actions so invalid tool entries cannot merge.
2. **Richer tool metadata** — add optional fields for homepage, aliases, supported managers, install notes, and post-install verification command.
3. **Declarative profiles v2** — support machine roles like `laptop`, `server`, `termux`, and `workstation` with include/exclude rules.
4. **Dotfile/template setup** — add a safe templating layer for shell rc files, Git config, Neovim, tmux, and SSH snippets.
5. **Secret-safe configuration** — integrate optional secret references rather than storing tokens or private config in plaintext.
6. **First-run recommendations** — recommend presets based on detected OS, RAM/disk, package manager, and existing installed tools.
7. **Package availability cache** — preflight every selected tool against the detected manager before starting an install batch.
8. **Better rollback state** — record package versions and managers consistently so undo can explain exactly what it will remove.
9. **Plugin trust policy** — allow signed/community plugin registries, but keep local plugins sandboxed from arbitrary special installers by default.
10. **Machine-readable reports** — provide JSON output for `doctor`, `audit`, `verify`, and install summaries for automation.

## Bugs and small improvements found

- The registry had an unsupported `lang` type for Asciiquarium, which meant several dispatch paths could silently skip it.
- `pipx`, `pip3`, `yarn`, and similar language-specific entries were not consistently detected because the language-manager detector only handled broad families.
- Non-interactive uninstall only handled `pip` language tools, leaving `pipx`, `cargo`, `gem`, `npm`, and `yarn` entries without a correct uninstall path.
- Install dispatch logic was duplicated across interactive, non-interactive, search, preset, and repair flows, which made future database changes risky.
- Detected package managers such as `xbps`, `guix`, `eopkg`, `urpmi`, `slackpkg`, `macports`, `bsd-pkg`, and `pkg_add` were missing from the main installer despite being detected elsewhere.

## Implemented in this pass

- Added a central install dispatcher and reused it across the main installation paths.
- Added a central uninstall dispatcher and reused it for non-interactive and menu-driven uninstall paths.
- Fixed the invalid Asciiquarium registry type.
- Improved language manager detection for exact tool types such as `pipx`, `pip3`, and `yarn`.
- Added `projectr audit [--strict]` to validate IDs, required fields, supported types, duplicates, and special installer references.

## References used for feature inspiration

- chezmoi feature overview: https://www.chezmoi.io/what-does-chezmoi-do/
- chezmoi homepage: https://www.chezmoi.io/
- Dotbot package/project overview: https://pypi.org/project/dotbot/
