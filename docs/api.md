# ProjectR Bash Library API

ProjectR can now be used as both:

1. a normal CLI application (`bash main.sh`, `project install git`, etc.); and
2. a sourceable Bash library for other scripts.

The library entrypoint is:

```bash
source "/path/to/ProjectR/lib/projectr.sh"
```

This file is designed to be safe to source. It defines functions and loads the read-only registry API, but it does **not** start the menu, parse your script's arguments, acquire locks, install packages, or create ProjectR config/state/log files by default.

---

## Source-safety contract

Sourcing `lib/projectr.sh` must not:

- launch the interactive menu;
- call `exit` from your shell;
- parse the caller's `$@`;
- install, uninstall, update, repair, or upgrade anything;
- acquire the normal ProjectR runtime lock;
- create `~/.config/projectr/session.conf`;
- create `~/.local/state/projectr_v2`;
- create or append runtime logs by default.

It does set these variables for compatibility with existing ProjectR modules:

| Variable | Meaning |
|---|---|
| `PROJECTR_LIBRARY_LOADED=1` | Marks that the library entrypoint has been sourced. |
| `PROJECTR_LIBRARY_MODE=1` | Lets modules know they are being loaded from the library layer. |
| `PROJECTR_ROOT` | Absolute path to the ProjectR repository root. |
| `SCRIPT_DIR` | Same as `PROJECTR_ROOT`, kept for compatibility with existing modules. |
| `PROJECTR_API_VERSION` | Public API generation number. |
| `PROJECTR_VERSION` | ProjectR version string. |

---

## Quick start

```bash
#!/usr/bin/env bash
set -uo pipefail

source "/path/to/ProjectR/lib/projectr.sh"

projectr_init --no-plugins

printf 'ProjectR root: %s\n' "$(projectr_root)"
printf 'ProjectR version: %s\n' "$(projectr_version)"
printf 'Detected manager: %s\n' "$(projectr_detect_manager)"
printf 'Registered tools: %s\n' "$(projectr_tool_count)"

projectr_tool_get git name
projectr_tool_status git || true
```

---

## Initialization

### `projectr_init [options]`

Initializes optional discovery features. You do not need to call it for basic registry lookups, because `lib/projectr.sh` already loads the read-only registry layer.

Default behavior:

- detects the system package manager;
- loads data-only TOML plugins from `tools.d/`;
- does not initialize config/state/log storage.

Options:

| Option | Description |
|---|---|
| `--no-detect` | Skip package-manager detection. |
| `--plugins` | Load `tools.d/*.toml` plugins. This is the default. |
| `--no-plugins` | Do not load plugins. |
| `--state` | Load the state module and initialize state storage. This can create files under `~/.local/state/projectr_v2`. |
| `--config` | Load the config module and initialize config storage. This can create `~/.config/projectr/session.conf`. |
| `--logging` | Load the real logging module. Without this, log functions are no-op fallbacks in library mode. |
| `--no-color` | Keep ProjectR color variables empty/plain. |

Examples:

```bash
# Basic read-only initialization with plugins.
projectr_init

# Maximum source-safety: no plugins, no manager detection, no storage.
projectr_init --no-plugins --no-detect

# Opt into state/config storage explicitly.
projectr_init --state --config
```

---

## Module loading

### `projectr_library_load <module> [...]`

Loads optional ProjectR modules on demand.

Common modules:

| Module | Purpose |
|---|---|
| `registry` | Tool registry, metadata, detection, resolver. Loaded automatically. |
| `plugins` | TOML plugin loader. |
| `dry-run` | Install planner/dry-run module. |
| `profile` | Profile parser, profile diff, profile dry-run support. |
| `state` | State database/TSV helpers. |
| `install` | Installer stack. Mutating functions become available. |
| `uninstall` | Uninstaller stack. Mutating functions become available. |
| `full` | Loads the full library-accessible stack. |

Example:

```bash
source ./lib/projectr.sh
projectr_library_load dry-run profile state
```

The loader is idempotent: loading the same module multiple times is safe.

To inspect loaded modules:

```bash
projectr_library_modules
```

---

## Root/version helpers

### `projectr_root`

Prints the ProjectR repository root.

```bash
root="$(projectr_root)"
```

### `projectr_version`

Prints the ProjectR version string.

```bash
version="$(projectr_version)"
```

### `projectr_api_version`

Prints the library API version.

```bash
api_version="$(projectr_api_version)"
```

---

## Package-manager detection

### `projectr_detect_manager`

Prints the primary detected package manager.

```bash
manager="$(projectr_detect_manager)"
```

Typical output:

```text
apt
```

### `projectr_detect_managers`

Prints all detected package managers, one per line.

```bash
projectr_detect_managers
```

### `projectr_detect_language_manager <type>`

Detects a package manager for a language ecosystem.

Examples:

```bash
projectr_detect_language_manager npm
projectr_detect_language_manager pipx
projectr_detect_language_manager cargo
projectr_detect_language_manager gem
```

### `projectr_manager_candidates`

Prints candidate managers in ProjectR's resolver order.

```bash
projectr_manager_candidates
```

---

## Tool registry API

The source of truth is still the legacy `TOOLS` array in `lib/data/tools.sh`:

```text
NUM|CMD|PKG|NAME|DESC|TYPE|EXTRA|CAT
```

The library exposes indexed lookup helpers so callers do not need to manually scan that array.

### `projectr_tool_count`

Prints the number of registered tools.

```bash
projectr_tool_count
```

### `projectr_tool_entries`

Prints raw registry entries, one per line.

```bash
projectr_tool_entries
```

### `projectr_tool_lookup <target>`

Looks up a tool by command id, package id, or display name.

```bash
projectr_tool_lookup git
projectr_tool_lookup Git
projectr_tool_lookup ripgrep
```

Example output:

```text
1|git|git|Git|Distributed version control system|pkg|-|Dev
```

Exit status:

- `0` if found;
- non-zero if not found.

### `projectr_tool_lookup_cmd <cmd>`

Looks up a tool by command id only.

```bash
projectr_tool_lookup_cmd git
```

Use this when you do **not** want package/display-name fallback matching.

### `projectr_entry_field <entry> <field>`

Extracts one field from a raw registry entry.

Supported field names:

| Field aliases | Meaning |
|---|---|
| `num`, `number`, `id` | Numeric menu id. |
| `cmd`, `command` | Command/binary id. |
| `pkg`, `package` | Package id. |
| `name`, `display` | Display name. |
| `desc`, `description` | Description. |
| `type` | Install type, such as `pkg`, `pipx`, `special`. |
| `extra`, `hook` | Extra hook/special installer field. |
| `cat`, `category` | Category. |

Example:

```bash
entry="$(projectr_tool_lookup git)"
projectr_entry_field "$entry" name
projectr_entry_field "$entry" category
```

### `projectr_tool_get <target> <field>`

Shortcut for lookup + field extraction.

```bash
projectr_tool_get git name
projectr_tool_get git package
projectr_tool_get git category
```

### `projectr_tool_json <target>`

Prints one registry entry as JSON.

```bash
projectr_tool_json git
```

Example output:

```json
{"num":1,"cmd":"git","package":"git","name":"Git","description":"Distributed version control system","type":"pkg","extra":"-","category":"Dev"}
```

### `projectr_tool_list [options]`

Lists registry entries.

Options:

| Option | Description |
|---|---|
| `--format=tsv` | Tab-separated fields. Default. |
| `--format=plain` | Human-readable columns. |
| `--format=json` | JSON array. |
| `--format=commands` | Command ids only. |
| `--format=names` | Display names only. |
| `--category=<name>` | Filter by category. Also supports `--category <name>`. |
| `--type=<type>` | Filter by install type. Also supports `--type <type>`. |

Examples:

```bash
projectr_tool_list --format=plain --category Dev
projectr_tool_list --format=json --type=pkg
projectr_tool_list --format=commands | sort
```

### `projectr_tool_categories`

Prints unique categories in registry order.

```bash
projectr_tool_categories
```

---

## Effective command/package API

Some distributions use different package names or binary names. For example, Debian/Ubuntu often package `fd` as `fd-find` and expose the binary as `fdfind`.

### `projectr_tool_effective_cmd <target> [manager]`

Prints the command name ProjectR should check for a target under a manager.

```bash
projectr_tool_effective_cmd fd apt
# fdfind
```

If manager is omitted, ProjectR uses the detected primary package manager.

### `projectr_tool_effective_package <target> [manager]`

Prints the package name ProjectR should install for a target under a manager.

```bash
projectr_tool_effective_package fd apt
# fd-find
```

### `projectr_tool_installed <target> [manager]`

Returns success if the effective command is on `PATH`.

```bash
if projectr_tool_installed git; then
  echo "git is available"
fi
```

### `projectr_tool_path <target> [manager]`

Prints the path to the effective command if installed.

```bash
projectr_tool_path git
```

### `projectr_tool_status <target> [manager]`

Prints status as TSV:

```text
installed<TAB>effective-command<TAB>path
missing<TAB>effective-command<TAB>-
```

Example:

```bash
projectr_tool_status git || true
```

---

## Plugin API

### `projectr_load_plugins`

Loads TOML plugins from `PROJECTR_TOOLS_DIR` or the repository's `tools.d/` directory.

```bash
PROJECTR_TOOLS_DIR="$HOME/.config/projectr/tools.d"
projectr_load_plugins
```

Plugin loading invalidates the lazy registry index automatically, so plugin tools can be looked up immediately:

```bash
projectr_load_plugins
projectr_tool_lookup my-plugin-tool
```

---

## Dry-run/planning API

### `projectr_plan_install <target...> [--json]`

Generates an install plan using the existing ProjectR dry-run engine.

```bash
projectr_plan_install git
projectr_plan_install git --json
projectr_plan_install git curl jq --json
```

This function does not install packages.

### `projectr_plan_profile <file> [--json]`

Generates a dry-run plan from a profile file.

```bash
projectr_plan_profile projectr.yml --json
```

### `projectr_profile_diff_api <args>`

Wrapper around ProjectR's profile diff feature.

```bash
projectr_profile_diff_api --profile projectr.yml
projectr_profile_diff_api --profile projectr.yml --json
```

---

## State API

State functions are explicit because they can initialize files under ProjectR's state directory.

### `projectr_state_records_api`

Loads the state module and prints recorded installs.

```bash
projectr_state_records_api
```

### `projectr_state_verify_api`

Loads the state module and verifies recorded installs.

```bash
projectr_state_verify_api
```

If you want state initialized during startup:

```bash
projectr_init --state
```

---

## Mutating API

The library can call ProjectR's installer/uninstaller, but these functions mutate the machine. They are intentionally not loaded or run at source time.

### `projectr_install_tool <target...>`

Installs one or more tools by registry target.

```bash
projectr_plan_install git --json
projectr_install_tool git
```

### `projectr_uninstall_tool <target...>`

Uninstalls one or more tools by registry target.

```bash
NON_INTERACTIVE=1 projectr_uninstall_tool git
```

Notes:

- Use `projectr_plan_install` before installing in automation.
- Special installers may still prompt, because their original behavior is interactive.
- Uninstall flows may prompt unless `NON_INTERACTIVE=1` is set.
- Package-manager privilege requirements still apply.

---

## Example scripts

### List missing developer tools

```bash
#!/usr/bin/env bash
set -uo pipefail

source ./lib/projectr.sh
projectr_init --no-plugins

while IFS=$'\t' read -r num cmd pkg name desc type extra category; do
  [[ "$category" == "Dev" ]] || continue
  if ! projectr_tool_installed "$cmd"; then
    printf '%s\t%s\t%s\n' "$cmd" "$pkg" "$name"
  fi
done < <(projectr_tool_list --format=tsv)
```

### Generate a JSON install plan

```bash
#!/usr/bin/env bash
set -uo pipefail

source ./lib/projectr.sh
projectr_init --no-plugins

projectr_plan_install git curl jq --json
```

### Use ProjectR as a registry database

```bash
#!/usr/bin/env bash
set -uo pipefail

source ./lib/projectr.sh

projectr_tool_list --format=json --category OSINT
```

---

## Stability rules for maintainers

Public API names should be stable once documented here. Internal helper names should use one of these patterns:

```text
projectr__internal_name
_projectr_internal_name
```

Public functions should follow these rules:

1. Do not call `exit`; return a status instead.
2. Print data to stdout.
3. Print diagnostics to stderr.
4. Avoid source-time writes.
5. Keep mutating behavior explicit in the function name or documentation.
6. Prefer TSV or JSON for scriptable output.
7. Keep legacy CLI behavior in `main.sh` untouched unless intentionally refactoring the CLI.

---

## Testing the library

Run:

```bash
bash tests/library_smoke.sh
```

The smoke test verifies that:

- `lib/projectr.sh` can be sourced;
- sourcing does not create config/state files;
- registry lookup works;
- manager-specific overrides work;
- JSON helpers emit valid JSON when `python3` is available;
- plugin loading updates the lazy registry index;
- dry-run planning is callable from the library.
