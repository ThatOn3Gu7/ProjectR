# ProjectR Library Roadmap

This document explains the plan used to turn ProjectR from a CLI-only Bash application into a reusable Bash library without breaking the existing CLI.

## Design principle

ProjectR should be two things at once:

```text
ProjectR CLI application:
  main.sh
  setup.sh
  project install git
  project doctor

ProjectR Bash library:
  source lib/projectr.sh
  projectr_tool_lookup git
  projectr_plan_install git --json
```

The CLI can be interactive and user-facing. The library must be boring, stable, predictable, and source-safe.

---

## Phase 1 — Source-safe entrypoint

Status: implemented.

Added:

```text
lib/projectr.sh
```

Responsibilities:

- resolve `PROJECTR_ROOT`;
- set `SCRIPT_DIR` for compatibility;
- load the minimal read-only registry stack;
- define no-op logging fallbacks in library mode;
- expose public API helpers;
- avoid config/state/log writes at source time.

Source safety is tested by:

```text
tests/library_smoke.sh
```

---

## Phase 2 — Public registry API

Status: implemented.

Public functions include:

```text
projectr_tool_count
projectr_tool_entries
projectr_tool_lookup
projectr_tool_lookup_cmd
projectr_entry_field
projectr_tool_get
projectr_tool_json
projectr_tool_list
projectr_tool_categories
```

The library uses the optimized lazy registry index from `lib/data/tools.sh`, so consumers do not need to manually scan the `TOOLS` array.

---

## Phase 3 — Manager-aware API

Status: implemented.

Public functions include:

```text
projectr_detect_manager
projectr_detect_managers
projectr_detect_language_manager
projectr_manager_candidates
projectr_tool_effective_cmd
projectr_tool_effective_package
projectr_tool_installed
projectr_tool_path
projectr_tool_status
```

These functions make ProjectR useful as a package-manager abstraction layer, not just a menu-driven installer.

---

## Phase 4 — Planner/profile/state API

Status: implemented.

Public wrappers include:

```text
projectr_plan_install
projectr_plan_profile
projectr_profile_diff_api
projectr_state_records_api
projectr_state_verify_api
```

State is explicit because it can create files under ProjectR's state directory.

---

## Phase 5 — Mutating API

Status: implemented with guardrails.

Public wrappers include:

```text
projectr_install_tool
projectr_uninstall_tool
```

These functions are not loaded or executed at source time. They lazy-load the installer/uninstaller stacks and delegate to the existing ProjectR implementation.

Recommended usage:

```bash
projectr_plan_install git --json
projectr_install_tool git
```

---

## Phase 6 — Documentation and examples

Status: implemented.

Added:

```text
docs/api.md
examples/library_list_tools.sh
examples/library_dry_run.sh
tests/library_smoke.sh
```

Updated:

```text
README.md
CHANGELOG.md
docs/modules.md
```

---

## Future improvements

These are intentionally left as future work so the initial library layer stays stable and easy to review.

### 1. API versioning policy

Add a documented stability policy:

```text
PROJECTR_API_VERSION=1
```

Potential rules:

- patch/minor ProjectR releases may add functions;
- existing public functions keep output contracts within an API generation;
- breaking API changes require `PROJECTR_API_VERSION=2`.

### 2. Namespacing cleanup

Gradually move internal helpers toward one of these patterns:

```text
projectr__internal_helper
_projectr_internal_helper
```

Keep documented public functions stable.

### 3. More structured JSON APIs

Add JSON output for more functions:

```text
projectr_detect_managers --json
projectr_tool_status --json
projectr_state_records_api --json
```

### 4. Library-specific Bats tests

If `bats` is available, add Bats coverage in addition to `tests/library_smoke.sh`.

Suggested tests:

- source is idempotent;
- source creates no files;
- unknown tool returns non-zero;
- plugin loading invalidates the registry index;
- JSON output is parseable;
- mutating APIs are not loaded until requested.

### 5. Optional package metadata schema

The current registry remains pipe-delimited for compatibility. In the future, ProjectR can add a richer metadata layer without replacing `TOOLS` immediately.

Potential metadata:

```text
homepage
license
source_url
checksum
build_cost
supported_arches
library_tags
```

### 6. External consumer examples

Add examples showing ProjectR embedded in other scripts:

- bootstrap a dev machine;
- audit missing tools in CI;
- generate Markdown tables from the registry;
- create a profile from installed commands;
- compare two machines.

---

## Definition of done for “ProjectR as a library”

A ProjectR release should feel library-ready when all of these are true:

- `source lib/projectr.sh` is safe and idempotent;
- public functions are documented in `docs/api.md`;
- read-only functions do not create files;
- mutating functions are explicit and lazy-loaded;
- examples are copy-paste runnable;
- tests verify source safety;
- CLI behavior remains unchanged.

The current implementation satisfies the initial version of this definition.
