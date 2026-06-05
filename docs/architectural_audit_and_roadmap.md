# ProjectR Enterprise Architecture Audit and Expansion Roadmap

This document captures a hardening pass plus future expansion design for ProjectR's Bash-native package-management abstraction layer.

## Research anchors

- `bats-core` is the de-facto Bash Automated Testing System and is explicitly intended for Bash/UNIX program tests: <https://github.com/bats-core/bats-core>.
- OpenSSF Scorecard, SLSA, and provenance/attestation workflows provide a mature vocabulary for supply-chain quality gates: <https://github.com/ossf/scorecard> and <https://openssf.org/blog/2022/11/16/openssf-expands-supply-chain-integrity-efforts-with-s2c2f/>.
- The Update Framework (TUF) models update-system defenses against compromised repositories/keys, stale metadata, and malicious update metadata: <https://theupdateframework.com/about/> and <https://theupdateframework.io/metadata>.
- Reproducible Builds documents deterministic build practice as a route to independently verifiable artifacts: <https://reproducible-builds.org/docs/>.

## Part 1 — Strict code review and edge-case defluxing

### 1. Global state contamination versus namerefs

**Risk.** `INSTALLED_PKGS`, `SKIPPED_PKGS`, `FAILED_PKGS`, `FOUND_PKGS`, and `NOT_FOUND_PKGS` were process-global arrays. Re-entering installer/checker flows from nested menus could leak stale state into the next summary.

**Implemented design.** ProjectR now loads `lib/core/array_context.sh`, which centralizes array mutation behind `projectr_array_push` and `projectr_install_result_push`. The helper uses Bash 4.3+ namerefs (`local -n`) when available and a validated `eval` fallback for older Bash. Callers such as `install_all`, `install_preset_by_names`, and `check_all_tools` declare `local -a` arrays, and Bash dynamic scoping lets lower-level functions update the active local context without changing globals.

**Pure-function blueprint.** New installer/checker code should follow this pattern:

```bash
install_some_context() {
  local -a INSTALLED_PKGS=() SKIPPED_PKGS=() FAILED_PKGS=()
  projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
  local status=$?
  post_install_summary
  return "$status"
}
```

For functions that must not rely on dynamic scoping, pass an array name and mutate it through `projectr_array_push`:

```bash
collect_missing_tools() {
  local out_array="$1" entry cmd name
  for entry in "${TOOLS[@]}"; do
    IFS='|' read -r _ cmd _ name _ _ _ _ <<< "$entry"
    command -v "$cmd" >/dev/null 2>&1 || projectr_array_push "$out_array" "$name"
  done
}
```

### 2. Bulletproof asynchronous spinner containment

**Risk.** The old spinner launched a background loop and only killed it through explicit `stop_spinner` calls. SIGINT/SIGTERM/EXIT during a package command could leave the spinner writing to the terminal.

**Implemented design.** `lib/core/spinner.sh` now installs scoped traps when a spinner starts, records any pre-existing traps, and restores them after `stop_spinner`. `projectr_spinner_cleanup` kills, waits for, and unsets `SPINNER_PID`, clears the current line, and restores the cursor. INT/TERM/HUP/EXIT paths call cleanup before delegating to previous handlers.

**Guardrail.** Any long-running operation that starts a spinner must either call `stop_spinner` or allow process exit/signal traps to do it. Do not start nested spinners; `start_spinner` remains idempotent when `SPINNER_PID` is already set.

### 3. Subshell variable isolation in TUI pipes

**Risk.** `cat <<EOF | rainbow` runs the left-hand side in a pipeline subshell. Any future assignment embedded into that segment would be lost.

**Implemented design.** The banner now uses `rainbow <<"EOF"`, executing the `rainbow` shell function in the parent shell with a redirection instead of a pipeline. The same rule should apply to every UI transformer:

```bash
# Preferred: function receives stdin without a pipeline subshell.
rainbow <<'EOF'
...
EOF

# Preferred when generated content is needed.
rainbow < <(generate_banner_text)
```

### 4. `errexit` strategy boundaries

**Risk.** Global `set -e` is brittle in a package manager wrapper because non-zero status is frequently expected data: probing optional binaries, dry-run simulation failures, package-manager cache misses, and retry decisions.

**Implemented design.** ProjectR now has `lib/core/strict_mode.sh` with explicit wrappers:

- `projectr_require "label" cmd args...` for hard boundaries.
- `projectr_try cmd args...` for status-preserving conditionals.
- `projectr_optional cmd args...` for probes whose failure should be quiet.
- `projectr_command_exists bin` for dependency checks.

**Blueprint.** Keep `set -uo pipefail`; do not enable global `set -e`. Instead:

```bash
if projectr_try apt-cache show "$pkg" >/dev/null 2>&1; then
  : "package exists"
else
  log_warn "apt metadata missing for $pkg" "resolver"
fi

projectr_require "sync package metadata" pkg_update || return $?
```

## Part 2 — Enterprise feature blueprints

### 1. Automated regression and virtual environment testing

**Implemented seed.** `tests/suite.bats` introduces BATS coverage for package-manager detection, scoped arrays, plugin sandbox validation, and batch dry-run aggregation.

**Expansion architecture.** Add a `tests/fixtures/bin` command shim layer for `apt-get`, `pacman`, `pip`, and `cargo`. Each shim appends JSONL/TSV events to `$BATS_TEST_TMPDIR/events.log` and exits with a controlled status. Container tests can then run the same suite under Debian, Arch, Alpine, and Termux-like prefixes.

**Docker matrix algorithm.**

1. Build tiny images with BATS and ProjectR mounted read-only.
2. Inject fake package-manager binaries early in `PATH` for deterministic tests.
3. Source `detect.sh`, `tools.sh`, and `installer.sh` directly.
4. Run `projectr_install_batch_by_entries` in `DRY_RUN=1` and shim-backed real mode.
5. Assert exit codes, event-log payloads, binary-name normalization, and state writes.

**Coexistence guardrails.** Tests must not call real `sudo`, must set `SCRIPT_DIR`, must redirect state into `$BATS_TEST_TMPDIR`, and must source individual libraries rather than launching the interactive menu unless the test is explicitly an end-to-end TUI test.

### 2. Parallel dependency and batch package upgrades

**Implemented seed.** `projectr_install_batch_by_entries` groups selected entries by native package manager or language manager, then submits one payload per group. If a group fails, it falls back to existing per-tool installers.

**Architecture.** Batch aggregation has three phases:

1. **Normalize:** parse `TOOLS` entries into `(cmd,pkg,name,type)` records and skip binaries already present.
2. **Group:** map `pkg` type to `$PRIMARY_PKG_MANAGER`; map language ecosystems through `detect_pkg_for_tool`.
3. **Execute:** call `projectr_batch_command_for_group "$manager" "${pkgs[@]}"`, stream output into a temporary log, and update scoped result arrays.

**Progress coexistence.** The batch executor uses the existing spinner and `projectr_log_file_excerpt`; a future progress-bar integration should read the temp log in chunks and transform lines into package-level progress events without parsing manager internals as hard truth.

**Guardrails.** Never mix system package managers and language package managers in one invocation. Never batch `special` installers. Always fall back to per-tool installs when a batch manager returns non-zero.

### 3. Filesystem snapshot rollback hooks

**Implemented seed.** `lib/features/snapshot.sh` detects `timeshift`, Btrfs root filesystems, and ZFS root datasets. `PROJECTR_ENABLE_SNAPSHOTS=1` enables pre-install checkpoints for `install_all`, preset installs, and batch installs. Snapshot metadata is recorded in SQLite or TSV state.

**Rollback integration blueprint.** Extend `rollback_last_session` to query the most recent `snapshots` row with status `created`. Ask for confirmation before destructive system rollback. Dispatch by driver:

- `timeshift`: `sudo timeshift --restore --snapshot "$id"`.
- Btrfs: bootloader-aware rollback is needed; do not blindly replace `/` from a running system. Emit distro-specific instructions or integrate with Snapper when available.
- ZFS: `sudo zfs rollback -r "dataset@$id"` only after warning about descendant snapshots and data loss.

**Guardrails.** Snapshot creation is opt-in, best-effort, and non-fatal. The installer continues if no driver exists. Rollback must never auto-execute filesystem reverts without explicit confirmation.

### 4. Strict TOML/YAML plugin sandboxing

**Implemented seed.** The TOML plugin loader now treats plugins as data only. It rejects unsupported keys, unsafe metacharacters, `special` types, and `extra` hooks. It validates that files are regular readable `*.toml` files inside the configured plugin directory.

**Future YAML architecture.** Add a `projectr_plugin_parse_yaml` shim that supports only flat scalar keys. Prefer `python -c` with a safe parser if present, but keep an Awk fallback. Feed parsed key/value records into the same validation boundary; never source plugin files.

**Guardrails.** Plugin data may append a tool entry but may not assign core variables, mutate `SCRIPT_DIR`, install signal traps, define shell functions, write outside `$PROJECTR_TOOLS_DIR`, or register executable hooks.

## Part 3 — One-year roadmap

### Advanced network optimizations and smart downloader mirrors

**Core philosophy.** A package wrapper is only as fast and reliable as its metadata/download path. Mirror latency, stale metadata, captive portals, and partial downloads dominate perceived quality.

**Codebase integration.** Add `lib/system/mirrors.sh` with `projectr_mirror_probe`, `projectr_mirror_rank`, and `projectr_manager_set_mirror_hint`. It should interact with `require_internet`, `pkg_update`, `dry_run`, and logging. Store mirror scores in `$PROJECTR_STATE_DIR/mirror_cache.tsv` with TTLs.

**Algorithm.** Probe candidate mirrors with HEAD/range requests, measure DNS+connect+TTFB, reject mirrors with expired TLS or wrong content length, rank by median latency, then hand off to native manager configuration only when ProjectR owns a temporary config overlay.

**Shell sketch.**

```bash
projectr_probe_url() {
  local url="$1" out status ms
  out=$(curl -fsSIL --connect-timeout 2 --max-time 5 -w '%{http_code} %{time_starttransfer}' -o /dev/null "$url") || return 1
  status=${out%% *}; ms=${out##* }
  [[ "$status" =~ ^2|3 ]] || return 1
  printf '%s\t%s\n' "$ms" "$url"
}
```

**Coexistence guardrails.** Do not rewrite permanent apt/pacman/brew config by default. Prefer environment variables or temporary config files. Cache network decisions with TTL. Keep offline behavior deterministic.

### Dynamic hardware architecture optimization and cross-compilation fallbacks

**Core philosophy.** CLI tools increasingly ship per-architecture artifacts. ProjectR should exploit native binaries when safe and fall back to source builds only when reproducible and resource-aware.

**Codebase integration.** Add `lib/system/arch.sh` to normalize `uname -m`, libc family, OS, Termux prefix, and CPU features. Feed normalized triples into package resolution, plugin validation, and dry-run output.

**Algorithm.** Normalize `x86_64/aarch64/armv7l`, detect glibc versus musl, detect Rosetta/WSL/Termux, then select package-manager-native install first, verified release artifact second, language-manager source build third.

**Coexistence guardrails.** Never compile large Rust/Go packages on low-memory devices unless the user opts in. Maintain a per-tool `build_cost` field. Respect existing master array fields by adding optional metadata instead of changing the pipe-delimited core schema immediately.

### Cryptographic verification, supply-chain security, and integrity auditing

**Core philosophy.** A wrapper spanning many ecosystems must defend against dependency confusion, stale mirrors, compromised plugin data, and unsigned release artifacts. TUF-style freshness and role separation, OpenSSF/SLSA-style provenance, and reproducible-build checks are the right design vocabulary.

**Codebase integration.** Add `lib/security/verify.sh` with `projectr_verify_checksum`, `projectr_verify_signature`, `projectr_verify_provenance`, and `projectr_score_tool_source`. Extend state rows with `source_url`, `checksum`, `signature_status`, `provenance_status`, and `sbom_path` when available.

**Algorithm.**

1. Prefer native package-manager signatures.
2. For direct release artifacts, require hash pinning and optional Sigstore/minisign/GPG verification.
3. Record verification result in state.
4. For plugins, require a trust policy: local-only, signed-only, or quarantine.
5. Periodically audit installed tools with OpenSSF Scorecard/SBOM data when source repositories are known.

**Coexistence guardrails.** Verification failure should block direct-download installs but should not second-guess package managers that already enforce repo signatures unless the user enables paranoid mode. Do not download keys over unauthenticated channels and immediately trust them.

### Intelligent TUI performance, memory-footprint caching, and terminal state restoration

**Core philosophy.** A highly customized raw-terminal TUI must be fast, reversible, and respectful of the user's terminal state. Performance problems often come from repeated formatting, repeated `tput`, and rendering more rows than visible.

**Codebase integration.** Add `lib/core/terminal_state.sh` with `projectr_terminal_enter`, `projectr_terminal_restore`, and `projectr_render_cache_get`. Integrate with `prompts.sh`, `display.sh`, `spinner.sh`, and `show_main_menu`.

**Algorithm.** Cache terminal capabilities once per session, pre-render visible menu rows into an array keyed by terminal width/theme/page, render only dirty lines on selection movement, and install an EXIT trap that restores cursor, echo, alternate-screen state, and color reset.

**Coexistence guardrails.** Keep a plain-output mode for CI and dumb terminals. Avoid non-POSIX terminal assumptions unless `$TERM` capability checks pass. Treat terminal restoration as idempotent so spinner cleanup and menu cleanup can both call it safely.
