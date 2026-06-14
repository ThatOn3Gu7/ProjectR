# Performance Optimization Notes

This document records the performance-focused review applied in the optimized workspace copy of ProjectR.

## Goals

The review focused on low-risk Bash performance improvements that preserve existing behaviour:

- make static CLI discovery commands (`--help`, `--version`) start faster;
- reduce repeated scans over the `TOOLS` registry;
- reduce repeated `command -v` probes in read-only views;
- avoid unnecessary command substitutions in hot loops;
- keep plugin loading, manager overrides, dry-runs, profile operations, and state verification compatible with the existing pipe-delimited registry format.

## Implemented optimizations

### Early help/version dispatch

`main.sh` now detects `--help`, `-h`, `help`, `--version`, `-v`, and `version` before the full runtime stack is loaded. These commands only source the small set of files required to print their output.

This avoids loading installer, uninstaller, scheduler, profile, state, TUI, and package-manager modules for static output.

### Lazy registry lookup index

`lib/data/tools.sh` now builds a lazy in-memory index for tool lookup by:

- command id;
- package id;
- display name.

The legacy `TOOLS` array remains the source of truth. The lookup index preserves first-match behaviour and is invalidated when plugins append new tools.

New helpers:

- `projectr_tools_index_build`
- `projectr_tools_index_invalidate`
- `projectr_tool_lookup_entry`
- `projectr_tool_lookup_cmd_entry`

### Cached command availability checks

`lib/core/strict_mode.sh` now exposes process-local command lookup caching:

- `projectr_command_exists`
- `projectr_command_path`
- `projectr_command_cache_clear`

Read-only flows use these helpers where safe to avoid repeatedly invoking `command -v` for the same binaries across hundreds of tools.

### Subshell-free metadata resolution helpers

`lib/data/tool_meta.sh` now includes `*_into` helpers that write resolved values into caller variables through `printf -v`. This keeps compatibility with existing stdout-returning helpers while avoiding command substitutions in loops.

New helpers:

- `projectr_tool_id_into`
- `projectr_registry_package_for_manager_into`
- `projectr_registry_cmd_for_manager_into`
- `projectr_effective_package_into`
- `projectr_effective_cmd_into`

### Single-pass category rendering

`project list categories` previously collected categories and then rescanned the entire registry for each category. `_flag_list_categories` now groups rows in one registry pass and then prints the grouped output.

### Cheaper version parsing

Read-only installed-tool views now parse the first version output line using Bash regular expressions instead of piping through `grep`, `head`, and `cut` where practical.

### Cached package manager detection, including `unknown`

`detect_pkg_manager` now records that detection has completed even when no supported manager is found. This prevents repeated full PATH scans on systems where the result is `unknown`.

## Validation performed

The following checks were run in the workspace:

```bash
find . -path './.git' -prune -o -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
bash -n main.sh setup.sh
bash main.sh --version
bash main.sh --no-color --version
bash main.sh --help
bash main.sh --no-color --help
bash main.sh --list=tools
bash main.sh --list=manager
bash main.sh --list=categories
bash main.sh --list=installed
bash main.sh audit --strict
bash main.sh dry-run git --json
bash main.sh doctor --json
```

Manual unit checks were also run for:

- registry lookup by command/display-name;
- cached package-manager detection;
- manager-specific metadata `*_into` helpers;
- plugin loading plus index invalidation.

## Benchmark snapshot

Approximate median timings from the review sandbox, measured with seven fresh Bash processes per command:

| Command | Original | Optimized | Result |
|---|---:|---:|---|
| `bash main.sh --version` | 0.064s | 0.006s | ~10x faster static version output |
| `bash main.sh --help` | 0.068s | 0.010s | ~6-7x faster static help output |
| `bash main.sh --list=categories` | 0.589s | 0.322s | ~45% faster category listing |
| `bash main.sh --list=installed` | 0.690s | 0.496s | ~28% faster installed listing |

Timings vary depending on shell, filesystem, PATH contents, installed tools, terminal, and machine load.

## Maintenance notes

- Keep the `TOOLS` array as the canonical registry unless a larger schema migration is planned.
- Call `projectr_tools_index_invalidate` whenever code appends, removes, or reorders registry entries after the index may have been built.
- Prefer `projectr_command_exists`/`projectr_command_path` for read-only checks. For immediate post-install or post-uninstall verification, direct `command -v` remains acceptable when fresh PATH state is required.
- Prefer `projectr_effective_cmd_into` and `projectr_effective_package_into` inside loops to avoid subshell overhead.
- Keep the fast path in `main.sh` limited to static/read-only commands that do not require lock acquisition, plugin loading, state initialization, or scheduler checks.
