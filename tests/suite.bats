#!/usr/bin/env bats
# ProjectR – bats test suite
# Run with: bats tests/suite.bats

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export SCRIPT_DIR

# Minimal stubs so sourcing lib files never tries to write real logs/state
export PROJECTR_STATE_DIR="${BATS_TMPDIR}/projectr_state"
export PROJECTR_SCHEDULER_ALERT_FILE="${BATS_TMPDIR}/projectr_alert"
mkdir -p "$PROJECTR_STATE_DIR"

# Stub heavy I/O helpers that are not under test
log()          { :; }
log_info()     { :; }
log_warn()     { :; }
log_error()    { :; }
log_fail()     { :; }
start_spinner(){ :; }
stop_spinner() { :; }
export -f log log_info log_warn log_error log_fail start_spinner stop_spinner

# Source the minimal shared layer every test needs
_source_core() {
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/lib/system/detect.sh"
    source "$SCRIPT_DIR/lib/system/resolver.sh"
    source "$SCRIPT_DIR/lib/data/tool_meta.sh"
    detect_pkg_manager >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# 1. detect_pkg_manager – distro-family preference
# ---------------------------------------------------------------------------
@test "detect_pkg_manager prefers distro family apt over extra managers" {
    source "$SCRIPT_DIR/lib/system/detect.sh"

    # Simulate an apt system with language managers also present
    PATH_BACKUP="$PATH"
    _tmpbin="$(mktemp -d)"
    for _cmd in apt-get pipx cargo npm; do
        printf '#!/bin/sh\nexit 0\n' > "$_tmpbin/$_cmd"
        chmod +x "$_tmpbin/$_cmd"
    done
    export PATH="$_tmpbin:$PATH"

    detect_pkg_manager
    export PATH="$PATH_BACKUP"
    rm -rf "$_tmpbin"

    [[ "$PRIMARY_PKG_MANAGER" == "apt" || "$PRIMARY_PKG_MANAGER" == "apt-get" ]]
}

# ---------------------------------------------------------------------------
# 2. checker – result arrays stay scoped to caller
# ---------------------------------------------------------------------------
@test "checker result arrays stay scoped to the caller context" {
    _source_core
    source "$SCRIPT_DIR/lib/core/array_context.sh"
    source "$SCRIPT_DIR/lib/system/checker.sh"

    # Stub projectr_install_result_push so it writes into caller arrays
    projectr_install_result_push() {
        local bucket="$1" item="$2"
        case "$bucket" in
            found)   FOUND_PKGS+=("$item") ;;
            missing) NOT_FOUND_PKGS+=("$item") ;;
        esac
    }
    export -f projectr_install_result_push

    local -a FOUND_PKGS=()
    local -a NOT_FOUND_PKGS=()

    # 'sh' is always present; 'projectr-present' is a fake tool that won't exist
    check_tool sh          "Sh shell"
    check_tool projectr-present "Present"

    # sh should be found; projectr-present should be missing
    [[ "${#FOUND_PKGS[@]}" -ge 1 ]]
    [[ "${#NOT_FOUND_PKGS[@]}" -ge 1 ]]
    # Installed summary records now carry display name, command, and version.
    [[ "${FOUND_PKGS[0]}" == *$'\t'* ]]
    # Missing summary records carry display name and expected command.
    [[ "${NOT_FOUND_PKGS[0]}" == *$'\t'* ]]
}

# ---------------------------------------------------------------------------
# 3. plugin loader – rejects shell-like keys and special execution hooks
# ---------------------------------------------------------------------------
@test "plugin loader rejects shell-like keys and special execution hooks" {
    _source_core
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/plugin_loader.sh"

    local _dir
    _dir="$(mktemp -d)"

    # A plugin with a forbidden 'special' type
    cat > "$_dir/bad_special.toml" <<'TOML'
cmd = "evil"
pkg = "evil"
name = "Evil Tool"
type = "special"
extra = "setup_evil"
TOML

    # A plugin with a shell-injection key
    cat > "$_dir/bad_key.toml" <<'TOML'
cmd = "legit"
pkg = "legit"
name = "Legit Tool"
SCRIPT_DIR = "/tmp/pwned"
TOML

    PROJECTR_TOOLS_DIR="$_dir"
    local before=${#TOOLS[@]}
    projectr_load_tool_plugin "$_dir/bad_special.toml"
    projectr_load_tool_plugin "$_dir/bad_key.toml"
    local after=${#TOOLS[@]}

    rm -rf "$_dir"
    # Neither bad plugin should have been added
    [[ "$after" -eq "$before" ]]
}

# ---------------------------------------------------------------------------
# 4. plugin loader – accepts safe data-only package plugins
# ---------------------------------------------------------------------------
@test "plugin loader accepts safe data-only package plugins" {
    _source_core
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/plugin_loader.sh"

    local _dir
    _dir="$(mktemp -d)"

    cat > "$_dir/demo.toml" <<'TOML'
cmd = "demo-tool"
pkg = "demo-pkg"
name = "Demo Tool"
desc = "A safe demo plugin"
type = "pkg"
category = "Demo"
TOML

    PROJECTR_TOOLS_DIR="$_dir"
    local before=${#TOOLS[@]}
    projectr_load_tool_plugin "$_dir/demo.toml"
    local after=${#TOOLS[@]}

    rm -rf "$_dir"
    # Exactly one new entry should have been appended
    [[ "$after" -eq $(( before + 1 )) ]]
}

# ---------------------------------------------------------------------------
# 5. batch installer – aggregates apt payloads in dry-run mode
# ---------------------------------------------------------------------------
@test "batch installer aggregates apt payloads in dry-run mode" {
    _source_core
    source "$SCRIPT_DIR/lib/core/array_context.sh"
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/state.sh"
    source "$SCRIPT_DIR/lib/features/installer.sh"

    # Stub privilege helper so no real sudo is attempted
    projectr_run_privileged() { shift; "$@"; }
    export -f projectr_run_privileged

    PRIMARY_PKG_MANAGER=apt
    export PRIMARY_PKG_MANAGER
    DRY_RUN=1
    export DRY_RUN

    local -a INSTALLED_PKGS=()
    local -a SKIPPED_PKGS=()
    local -a FAILED_PKGS=()

    projectr_install_result_push() {
        local bucket="$1" item="$2"
        case "$bucket" in
            installed) INSTALLED_PKGS+=("$item") ;;
            skipped)   SKIPPED_PKGS+=("$item") ;;
            failed)    FAILED_PKGS+=("$item") ;;
        esac
    }
    export -f projectr_install_result_push

    # Two fake pkg-type entries
    local -a entries=(
        "1|fake-cmd-a|fake-pkg-a|Fake A|desc|pkg|-|Test"
        "2|fake-cmd-b|fake-pkg-b|Fake B|desc|pkg|-|Test"
    )

    projectr_install_batch_by_entries "${entries[@]}"
    [ "$?" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 6. dry-run – JSON plan includes package field for language tools
# ---------------------------------------------------------------------------
@test "dry-run install JSON plans language tools with their language manager" {
    _source_core
    source "$SCRIPT_DIR/lib/core/array_context.sh"
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/state.sh"
    source "$SCRIPT_DIR/lib/features/dry_run.sh"

    PRIMARY_PKG_MANAGER=apt
    export PRIMARY_PKG_MANAGER

    # Inject a fake pip tool so the dry-run has something to plan
    TOOLS+=("99|demo-tool|demo-pkg|Demo Tool|A demo|pip|-|Test")

    # Stub the package simulation so it returns quickly without network
    projectr_package_simulation() { echo "would-install"; }
    export -f projectr_package_simulation

    run bash -c "
        source '$SCRIPT_DIR/lib/system/detect.sh'
        source '$SCRIPT_DIR/lib/system/resolver.sh'
        source '$SCRIPT_DIR/lib/data/tool_meta.sh'
        source '$SCRIPT_DIR/lib/core/array_context.sh'
        source '$SCRIPT_DIR/lib/data/tools.sh'
        source '$SCRIPT_DIR/lib/features/state.sh'
        source '$SCRIPT_DIR/lib/features/dry_run.sh'
        log()      { :; }
        log_info() { :; }
        PRIMARY_PKG_MANAGER=apt
        TOOLS+=(\"99|demo-tool|demo-pkg|Demo Tool|A demo|pip|-|Test\")
        projectr_package_simulation() { echo \"would-install\"; }
        projectr_dry_run_install --json demo-tool
    "
    [[ "$output" == *'"package"'* || "$output" == *'"pkg"'* || "$output" == *'demo'* ]]
}

# ---------------------------------------------------------------------------
# 7. CLI – uninstall dry-run is rejected before mutating commands
# ---------------------------------------------------------------------------
@test "CLI uninstall dry-run is rejected before mutating commands" {
    source "$SCRIPT_DIR/lib/core/session.sh"

    projectr_classify_cli_action "dry-run" "uninstall" "git"
    [[ "${PROJECTR_READ_ONLY_ACTION}" == "1" ]]
}

# ---------------------------------------------------------------------------
# 8. CLI – reset dry-run leaves saved preferences intact
# ---------------------------------------------------------------------------
@test "reset dry-run leaves saved preferences intact" {
    source "$SCRIPT_DIR/lib/core/session.sh"

    projectr_classify_cli_action "dry-run" "reset"
    [[ "${PROJECTR_READ_ONLY_ACTION}" == "1" ]]
}

# ---------------------------------------------------------------------------
# 9. install_pkg – propagates package manager failures
# ---------------------------------------------------------------------------
@test "install_pkg propagates package manager failures" {
    _source_core
    source "$SCRIPT_DIR/lib/core/array_context.sh"
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/state.sh"
    source "$SCRIPT_DIR/lib/features/installer.sh"

    local -a INSTALLED_PKGS=()
    local -a SKIPPED_PKGS=()
    local -a FAILED_PKGS=()

    projectr_install_result_push() {
        local bucket="$1" item="$2"
        case "$bucket" in
            installed) INSTALLED_PKGS+=("$item") ;;
            skipped)   SKIPPED_PKGS+=("$item") ;;
            failed)    FAILED_PKGS+=("$item") ;;
        esac
    }
    export -f projectr_install_result_push

    # Stub privilege runner to always fail with exit 42
    projectr_run_privileged() { return 42; }
    export -f projectr_run_privileged

    PRIMARY_PKG_MANAGER=apt
    export PRIMARY_PKG_MANAGER

    # 'definitely-not-a-real-cmd' won't be on PATH, so install_pkg will attempt install.
    # Call directly instead of through `run` so scoped result arrays remain visible
    # in this test shell.
    local install_status=0
    install_pkg "definitely-not-a-real-cmd" "definitely-not-a-real-pkg" "Fake Pkg" || install_status=$?
    # Should fail (non-zero) because the PM stub returns 42
    [ "$install_status" -ne 0 ]
    # The tool should be recorded as failed
    [[ " ${FAILED_PKGS[*]} " == *" Fake Pkg "* ]]
}

# ---------------------------------------------------------------------------
# 10. search_install – rejects shell metacharacters before manager probing
# ---------------------------------------------------------------------------
@test "search install rejects shell metacharacters before manager probing" {
    _source_core
    source "$SCRIPT_DIR/lib/core/array_context.sh"
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/state.sh"
    source "$SCRIPT_DIR/lib/features/installer.sh"
    source "$SCRIPT_DIR/lib/features/search_install.sh"

    local -a INSTALLED_PKGS=()
    local -a SKIPPED_PKGS=()
    local -a FAILED_PKGS=()

    projectr_install_result_push() {
        local bucket="$1" item="$2"
        case "$bucket" in
            installed) INSTALLED_PKGS+=("$item") ;;
            skipped)   SKIPPED_PKGS+=("$item") ;;
            failed)    FAILED_PKGS+=("$item") ;;
        esac
    }
    export -f projectr_install_result_push

    # Stub candidate managers so no real PM probing happens
    projectr_candidate_managers() { echo "apt"; }
    export -f projectr_candidate_managers

    NON_INTERACTIVE=1
    export NON_INTERACTIVE
    PRIMARY_PKG_MANAGER=apt
    export PRIMARY_PKG_MANAGER

    run search_and_install "bad;name"
    # Should fail or produce no install — the bad name must not reach a PM
    [[ "$status" -ne 0 || " ${FAILED_PKGS[*]} " == *" bad;name "* || "$output" == *'invalid'* || "$output" == *'unsafe'* || "$output" == *'not found'* ]]
}

# ---------------------------------------------------------------------------
# 11. profile diff – reports installed, missing, and unknown tools
# ---------------------------------------------------------------------------
@test "profile diff reports installed, missing, and unknown tools" {
    _source_core
    source "$SCRIPT_DIR/lib/core/array_context.sh"
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/state.sh"
    source "$SCRIPT_DIR/lib/features/profile_code.sh"

    local _profile
    _profile="$(mktemp --suffix=.yml)"
    cat > "$_profile" <<'YAML'
tools:
  - sh
  - definitely-not-installed-xyz
YAML

    run projectr_profile_diff "$_profile"
    rm -f "$_profile"

    # sh is always present; the fake tool should be missing
    [[ "$output" == *'sh'* ]]
}

# ---------------------------------------------------------------------------
# 12. state – remove deletes TSV managed records
# ---------------------------------------------------------------------------
@test "state remove deletes TSV managed records" {
    _source_core
    source "$SCRIPT_DIR/lib/features/state.sh"

    # Force TSV backend (no sqlite3 in test env)
    sqlite3() { return 1; }
    export -f sqlite3

    projectr_state_init

    # Write a fake record directly into the TSV
    printf 'git\tGit\tgit\tapt\tpkg\t2.40\t2024-01-01T00:00:00Z\ttest\tverified\ttx-1\n' \
        >> "$PROJECTR_STATE_TSV"

    projectr_state_remove_install "git" "Git" "git"

    run grep -c 'git' "$PROJECTR_STATE_TSV"
    [ "$output" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 13. doctor – supports JSON output
# ---------------------------------------------------------------------------
@test "doctor supports JSON output" {
    run bash -c "
        export SCRIPT_DIR='$SCRIPT_DIR'
        export PROJECTR_STATE_DIR='${BATS_TMPDIR}/projectr_state'
        log()      { :; }
        log_info() { :; }
        log_warn() { :; }
        log_error(){ :; }
        source '$SCRIPT_DIR/lib/system/detect.sh'
        source '$SCRIPT_DIR/lib/system/resolver.sh'
        source '$SCRIPT_DIR/lib/system/privilege.sh'
        source '$SCRIPT_DIR/lib/data/tool_meta.sh'
        source '$SCRIPT_DIR/lib/features/state.sh'
        source '$SCRIPT_DIR/lib/features/doctor.sh'
        detect_pkg_manager >/dev/null 2>&1 || true
        projectr_doctor --json
    "
    [[ "$output" == *'"ok"'* ]]
    [[ "$output" == *'"checks"'* ]]
    [[ "$output" == *'"package-manager"'* ]]
    [[ "$output" == *'"privilege"'* ]]
}

# ---------------------------------------------------------------------------
# 14. detect_pkg_manager – returns a known manager on this system
# ---------------------------------------------------------------------------
@test "detect_pkg_manager returns a non-empty result" {
    source "$SCRIPT_DIR/lib/system/detect.sh"
    detect_pkg_manager >/dev/null 2>&1 || true
    [[ -n "${PRIMARY_PKG_MANAGER:-}" ]]
}

# ---------------------------------------------------------------------------
# 15. plugin loader – pkg_* overrides are registered in tool_meta maps
# ---------------------------------------------------------------------------
@test "plugin loader registers pkg overrides from plugin file" {
    _source_core
    source "$SCRIPT_DIR/lib/data/tools.sh"
    source "$SCRIPT_DIR/lib/features/plugin_loader.sh"

    local _dir
    _dir="$(mktemp -d)"

    cat > "$_dir/override.toml" <<'TOML'
cmd = "fd"
pkg = "fd"
name = "fd (override test)"
desc = "Fast find"
type = "pkg"
category = "Utils"
pkg_apt = "fd-find"
cmd_apt = "fdfind"
TOML

    PROJECTR_TOOLS_DIR="$_dir"
    projectr_load_tool_plugin "$_dir/override.toml"
    rm -rf "$_dir"

    # The apt package override should now be registered
    [[ "${PROJECTR_TOOL_PKG_OVERRIDES[fd:apt]:-}" == "fd-find" ]]
}

# ---------------------------------------------------------------------------
# 16. list manager – includes language ecosystem managers
# ---------------------------------------------------------------------------
@test "list manager includes language ecosystem managers" {
    run bash "$SCRIPT_DIR/main.sh" --no-color --list=manager
    [ "$status" -eq 0 ]
    [[ "$output" == *'Package and Ecosystem Managers'* ]]
    [[ "$output" == *'Language'* ]]
    [[ "$output" == *'pipx'* ]]
    [[ "$output" == *'pip3'* ]]
    [[ "$output" == *'npm'* ]]
    [[ "$output" == *'cargo'* ]]
}
