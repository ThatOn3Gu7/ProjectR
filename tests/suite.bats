#!/usr/bin/env bats

setup() {
  export PROJECTR_TEST_ROOT="$BATS_TEST_TMPDIR/root"
  export SCRIPT_DIR="$PWD"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME" "$PROJECTR_TEST_ROOT/bin" "$PROJECTR_TEST_ROOT/tools.d"
  PATH="$PROJECTR_TEST_ROOT/bin:$PATH"
  export PATH
  INFO="" OPTION="" ERROR="" RST="" DIM="" BOLD_YELLOW="" BLUE=""
  export INFO OPTION ERROR RST DIM BOLD_YELLOW BLUE
  log() { :; }
  log_warn() { :; }
  log_info() { :; }
  log_fail() { :; }
  log_error() { :; }
  print_box() { :; }
  print_titled_box() { :; }
  safe_tput() { :; }
  sleep() { :; }
  source "$SCRIPT_DIR/lib/core/array_context.sh"
  source "$SCRIPT_DIR/lib/core/strict_mode.sh"
}

@test "detect_pkg_manager prefers distro family apt over extra managers" {
  cat >"$PROJECTR_TEST_ROOT/bin/apt" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  cat >"$PROJECTR_TEST_ROOT/bin/snap" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$PROJECTR_TEST_ROOT/bin/apt" "$PROJECTR_TEST_ROOT/bin/snap"
  PRETTY_NAME="Debian Test"
  ID=debian
  ID_LIKE=debian
  source "$SCRIPT_DIR/lib/system/detect.sh"

  run detect_pkg_manager
  [ "$status" -eq 0 ]
  [ "$output" = "apt" ]
}

@test "checker result arrays stay scoped to the caller context" {
  cat >"$PROJECTR_TEST_ROOT/bin/projectr-present" <<'SH'
#!/usr/bin/env bash
printf 'projectr-present 1.2.3\n'
SH
  chmod +x "$PROJECTR_TEST_ROOT/bin/projectr-present"
  TOOLS=("1|projectr-present|projectr-present|Present|desc|pkg|-|Test" "2|projectr-missing|projectr-missing|Missing|desc|pkg|-|Test")
  source "$SCRIPT_DIR/lib/system/checker.sh"

  FOUND_PKGS=(global-found)
  NOT_FOUND_PKGS=(global-missing)
  local -a FOUND_PKGS=()
  local -a NOT_FOUND_PKGS=()
  check_tool projectr-present Present
  check_tool projectr-missing Missing

  [ "${#FOUND_PKGS[@]}" -eq 1 ]
  [ "${FOUND_PKGS[0]}" = "projectr-present" ]
  [ "${#NOT_FOUND_PKGS[@]}" -eq 1 ]
  [ "${NOT_FOUND_PKGS[0]}" = "projectr-missing" ]
}

@test "plugin loader rejects shell-like keys and special execution hooks" {
  TOOLS=()
  PROJECTR_TOOLS_DIR="$PROJECTR_TEST_ROOT/tools.d"
  export PROJECTR_TOOLS_DIR
  source "$SCRIPT_DIR/lib/features/plugin_loader.sh"
  cat >"$PROJECTR_TOOLS_DIR/bad.toml" <<'TOML'
cmd = "evil"
pkg = "evil"
name = "Evil"
type = "special"
extra = "rm -rf /"
SCRIPT_DIR = "/tmp/hijack"
TOML

  run projectr_load_tool_plugins
  [ "$status" -eq 0 ]
  [ "${#TOOLS[@]}" -eq 0 ]
}

@test "plugin loader accepts safe data-only package plugins" {
  TOOLS=()
  PROJECTR_TOOLS_DIR="$PROJECTR_TEST_ROOT/tools.d"
  export PROJECTR_TOOLS_DIR
  source "$SCRIPT_DIR/lib/features/plugin_loader.sh"
  cat >"$PROJECTR_TOOLS_DIR/good.toml" <<'TOML'
cmd = "ripgrep"
pkg = "ripgrep"
name = "Ripgrep"
desc = "Fast search"
type = "pkg"
category = "Search"
TOML

  run projectr_load_tool_plugins
  [ "$status" -eq 0 ]
  [ "${#TOOLS[@]}" -eq 1 ]
  [[ "${TOOLS[0]}" == *"|ripgrep|ripgrep|Ripgrep|"* ]]
}

@test "batch installer aggregates apt payloads in dry-run mode" {
  source "$SCRIPT_DIR/lib/system/detect.sh"
  source "$SCRIPT_DIR/lib/features/post_install.sh"
  source "$SCRIPT_DIR/lib/features/snapshot.sh"
  source "$SCRIPT_DIR/lib/core/spinner.sh"
  source "$SCRIPT_DIR/lib/features/installer.sh"
  detect_pkg_manager() { echo apt; }
  detect_pkg_for_tool() { echo "$1"; }
  command() {
    if [ "$1" = "-v" ]; then return 1; fi
    builtin command "$@"
  }
  post_install_summary() { printf '%s\n' "installed:${INSTALLED_PKGS[*]} skipped:${SKIPPED_PKGS[*]} failed:${FAILED_PKGS[*]}"; }
  DRY_RUN=1
  PRIMARY_PKG_MANAGER=apt
  run projectr_install_batch_by_entries \
    "1|foo|foo-pkg|Foo|desc|pkg|-|Test" \
    "2|bar|bar-pkg|Bar|desc|pkg|-|Test"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Batch installed 2 package(s) via apt"* ]]
  [[ "$output" == *"installed:Foo Bar"* ]]
}

@test "dry-run install JSON plans language tools with their language manager" {
  TOOLS=("1|demo-cli|demo-pkg|Demo CLI|desc|npm|-|Test")
  source "$SCRIPT_DIR/lib/system/detect.sh"
  source "$SCRIPT_DIR/lib/features/dry_run.sh"
  detect_pkg_for_tool() { echo npm; }
  npm() { return 1; }

  run projectr_dry_run_install demo-cli --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"dry_run":true'* ]]
  [[ "$output" == *'"manager":"npm"'* ]]
  [[ "$output" == *'"package":"demo-pkg"'* ]]
}

@test "CLI uninstall dry-run is rejected before mutating commands" {
  TOOLS=("1|demo-tool|demo-pkg|Demo Tool|desc|pkg|-|Test")
  source "$SCRIPT_DIR/lib/core/cli.sh"
  run projectr_cli_uninstall_args demo-tool --dry-run
  [ "$status" -eq 2 ]
  [[ "$output" == *"no changes were made"* ]]
}

@test "reset dry-run leaves saved preferences intact" {
  source "$SCRIPT_DIR/lib/flags/flags.sh"
  mkdir -p "$HOME/.config/projectr"
  printf 'skip_sys_upgrade=do\n' > "$HOME/.config/projectr/session.conf"

  run _flag_reset --dry-run
  [ "$status" -eq 0 ]
  grep -q 'skip_sys_upgrade=do' "$HOME/.config/projectr/session.conf"
  [[ "$output" == *"no preferences were changed"* ]]
}
