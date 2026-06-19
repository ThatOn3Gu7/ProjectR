#!/usr/bin/env bash
# shellcheck disable=SC1090
# ProjectR library smoke tests.
#
# This script intentionally does not require bats. It verifies that the public
# sourceable library entrypoint can be used from a plain Bash script without
# triggering CLI/runtime side effects.

set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_PLUGIN_DIR="$(mktemp -d)"
FAILURES=0

cleanup() {
  rm -rf "$TMP_HOME" "$TMP_PLUGIN_DIR"
}
trap cleanup EXIT

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

pass() {
  printf '[PASS] %s\n' "$*"
}

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$label"
  else
    fail "$label: expected '$expected', got '$actual'"
  fi
}

assert_success() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

# Use an isolated HOME so source-safety checks can detect accidental config,
# state, or log creation.
export HOME="$TMP_HOME"
export PROJECTR_TOOLS_DIR="$TMP_PLUGIN_DIR"

# shellcheck source=../lib/projectr.sh
source "$PROJECT_ROOT/lib/projectr.sh"

assert_eq "$PROJECT_ROOT" "$(projectr_root)" "projectr_root reports repository root"
assert_eq "1.4" "$(projectr_version)" "projectr_version reports version"
assert_eq "240" "$(projectr_tool_count)" "base registry has expected tool count before plugins"

if [[ -e "$HOME/.config/projectr/session.conf" ]]; then
  fail "sourcing lib/projectr.sh created config unexpectedly"
else
  pass "sourcing lib/projectr.sh does not create config"
fi

if [[ -e "$HOME/.local/state/projectr" ]]; then
  fail "sourcing lib/projectr.sh created state unexpectedly"
else
  pass "sourcing lib/projectr.sh does not create state"
fi

assert_eq "Git" "$(projectr_tool_get git name)" "projectr_tool_get resolves display name"
assert_eq "fd-find" "$(projectr_tool_effective_package fd apt)" "manager package override works"
assert_eq "fdfind" "$(projectr_tool_effective_cmd fd apt)" "manager command override works"

if command -v python3 >/dev/null 2>&1; then
  projectr_tool_json git | python3 -m json.tool >/dev/null 2>&1 &&
    pass "projectr_tool_json emits valid JSON" ||
    fail "projectr_tool_json emits invalid JSON"
  projectr_tool_list --format=json --category=Dev | python3 -m json.tool >/dev/null 2>&1 &&
    pass "projectr_tool_list --format=json emits valid JSON" ||
    fail "projectr_tool_list --format=json emits invalid JSON"
else
  projectr_tool_json git | grep -q '"cmd":"git"' &&
    pass "projectr_tool_json contains git command" ||
    fail "projectr_tool_json missing git command"
fi

# Plugin loading should append to the registry and invalidate/rebuild the lazy
# index so the new tool is immediately discoverable.
cat >"$TMP_PLUGIN_DIR/demo.toml" <<'TOML'
cmd = "demo-tool"
pkg = "demo-pkg"
name = "Demo Tool"
desc = "A safe demo plugin"
type = "pkg"
category = "Demo"
TOML

projectr_load_plugins
assert_eq "241" "$(projectr_tool_count)" "plugin loading appends one tool"
assert_eq "Demo Tool" "$(projectr_tool_get demo-tool name)" "plugin tool is indexed after load"

# projectr_init should be explicit and safe. This call loads no storage modules.
projectr_init --no-plugins --no-detect
if [[ -e "$HOME/.config/projectr/session.conf" || -e "$HOME/.local/state/projectr" ]]; then
  fail "projectr_init --no-plugins --no-detect created storage unexpectedly"
else
  pass "projectr_init without storage options is side-effect free"
fi

# Dry-run planner should be callable from the library. Use git because it is in
# the base registry and normally present in development/test environments.
if command -v git >/dev/null 2>&1; then
  if command -v python3 >/dev/null 2>&1; then
    projectr_plan_install git --json | python3 -m json.tool >/dev/null 2>&1 &&
      pass "projectr_plan_install emits valid JSON" ||
      fail "projectr_plan_install emits invalid JSON"
  else
    projectr_plan_install git --json | grep -q '"dry_run":true' &&
      pass "projectr_plan_install emits dry-run JSON marker" ||
      fail "projectr_plan_install missing dry-run JSON marker"
  fi
else
  printf '[SKIP] git not present; skipping projectr_plan_install smoke\n'
fi

if [[ $FAILURES -eq 0 ]]; then
  printf '[PASS] library smoke tests completed successfully\n'
  exit 0
fi

printf '[FAIL] library smoke tests completed with %d failure(s)\n' "$FAILURES" >&2
exit 1
