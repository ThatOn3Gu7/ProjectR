#!/usr/bin/env bash
# shellcheck disable=all
# -----------------------------------------------------------------------------
# ProjectR Bash Library Entrypoint
# -----------------------------------------------------------------------------
#
# This file is the public, source-safe API surface for ProjectR.
#
# Why it exists:
#   main.sh is an application entrypoint. It loads the full runtime, prepares
#   locks/session state, dispatches CLI flags, and may enter the interactive menu.
#   That is exactly what a CLI should do, but it is NOT what another shell script
#   wants when it says:
#
#       source /path/to/ProjectR/lib/projectr.sh
#
#   A library entrypoint must be boring and predictable: define functions, expose
#   data helpers, and avoid surprising side effects.
#
# Source-safety contract:
#   Sourcing this file must not:
#     - start the interactive menu;
#     - parse the caller's "$@";
#     - call exit from the caller's shell;
#     - install, uninstall, upgrade, or mutate packages;
#     - acquire ProjectR's runtime lock;
#     - create config/state/log files by default.
#
# What it DOES do:
#   - resolves PROJECTR_ROOT and SCRIPT_DIR for existing modules;
#   - loads the minimal registry/detection helpers needed for read-only APIs;
#   - exposes stable wrapper functions with predictable stdout/status behavior;
#   - lazy-loads heavier modules only when an API function needs them.
#
# Design rule for future maintainers:
#   If a function can mutate the user's machine, make that behavior explicit in
#   the function name/docs and never run it during source-time initialization.
# -----------------------------------------------------------------------------

# ProjectR is a Bash project. If someone tries to source this from sh/dash, fail
# politely. Use return when sourced; fall back to exit when executed directly.
if [[ -z "${BASH_VERSION:-}" ]]; then
  printf '%s\n' "ProjectR library requires Bash." >&2
  return 2 2>/dev/null || exit 2
fi

# Idempotency: sourcing a library twice should be harmless. The existing symbols
# remain available and we avoid re-sourcing modules unnecessarily.
if [[ "${PROJECTR_LIBRARY_LOADED:-0}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi

declare -g PROJECTR_LIBRARY_LOADED=1
declare -g PROJECTR_LIBRARY_MODE=1
declare -g PROJECTR_API_VERSION="${PROJECTR_API_VERSION:-1}"
declare -g PROJECTR_VERSION="${PROJECTR_VERSION:-1.4}"

# Resolve the repository root from this file's location. Keep SCRIPT_DIR for
# compatibility with the rest of ProjectR's modules, which historically use it
# as the root anchor.
declare -g PROJECTR_LIBRARY_FILE="${BASH_SOURCE[0]}"
declare -g PROJECTR_LIB_DIR
PROJECTR_LIB_DIR="$(cd "$(dirname "$PROJECTR_LIBRARY_FILE")" && pwd)"
declare -g PROJECTR_ROOT
PROJECTR_ROOT="$(cd "$PROJECTR_LIB_DIR/.." && pwd)"
declare -g SCRIPT_DIR="$PROJECTR_ROOT"
export SCRIPT_DIR

# A tiny internal status printer. Public library functions should generally keep
# stdout machine-readable; diagnostics go to stderr.
projectr__api_error() {
  printf 'projectr: %s\n' "$*" >&2
}

# Existing feature modules call log/log_info/log_warn/etc. In CLI mode those are
# provided by lib/core/logging.sh. In source-only library mode we define no-op
# fallbacks so read-only modules can be loaded without creating log files.
if ! declare -f log >/dev/null 2>&1; then log() { :; }; fi
if ! declare -f log_info >/dev/null 2>&1; then log_info() { :; }; fi
if ! declare -f log_ok >/dev/null 2>&1; then log_ok() { :; }; fi
if ! declare -f log_warn >/dev/null 2>&1; then log_warn() { :; }; fi
if ! declare -f log_error >/dev/null 2>&1; then log_error() { :; }; fi
if ! declare -f log_fail >/dev/null 2>&1; then log_fail() { :; }; fi

# Some modules print colored messages if these variables exist. Keep them empty
# until the caller explicitly loads colors or a UI/runtime module.
for projectr__color_var in \
  RST BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE \
  BOLD_BLACK BOLD_RED BOLD_GREEN BOLD_YELLOW BOLD_BLUE BOLD_PURPLE BOLD_CYAN BOLD_WHITE \
  BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_PURPLE BRIGHT_CYAN BRIGHT_WHITE \
  BOLD_BRIGHT_BLACK BOLD_BRIGHT_RED BOLD_BRIGHT_GREEN BOLD_BRIGHT_YELLOW BOLD_BRIGHT_BLUE BOLD_BRIGHT_PURPLE BOLD_BRIGHT_CYAN BOLD_BRIGHT_WHITE \
  BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_PURPLE BG_CYAN BG_WHITE \
  BG_BRIGHT_BLACK BG_BRIGHT_RED BG_BRIGHT_GREEN BG_BRIGHT_YELLOW BG_BRIGHT_BLUE BG_BRIGHT_PURPLE BG_BRIGHT_CYAN BG_BRIGHT_WHITE \
  BOLD DIM ITALIC UNDERLINE BLINK REVERSE HIDDEN STRIKETHROUGH BRIGHT_MAGENTA INFO OPTION ERROR BARR; do
  if [[ -z "${!projectr__color_var+x}" ]]; then
    printf -v "$projectr__color_var" '%s' ''
  fi
done
unset projectr__color_var

# Module loader state. Associative arrays are already required elsewhere in
# ProjectR, so the library API also assumes Bash 4+.
declare -gA PROJECTR_LIBRARY_SOURCED=()

projectr_library_source_file() {
  # Source a ProjectR file once and remember it by a stable key.
  # Usage: projectr_library_source_file "data/tools" "$PROJECTR_ROOT/lib/data/tools.sh"
  local key="${1:-}" file="${2:-}"
  [[ -n "$key" && -n "$file" ]] || {
    projectr__api_error "projectr_library_source_file requires <key> <file>"
    return 2
  }
  [[ -n "${PROJECTR_LIBRARY_SOURCED[$key]+set}" ]] && return 0
  [[ -f "$file" ]] || {
    projectr__api_error "missing ProjectR module: $file"
    return 1
  }
  # shellcheck source=/dev/null
  source "$file" || return $?
  PROJECTR_LIBRARY_SOURCED[$key]=1
}

projectr_library_disable_color() {
  # Public helper for callers that want guaranteed plain output after loading
  # color-aware modules.
  export NO_COLOR=1
  local var
  for var in \
    RST BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE \
    BOLD_BLACK BOLD_RED BOLD_GREEN BOLD_YELLOW BOLD_BLUE BOLD_PURPLE BOLD_CYAN BOLD_WHITE \
    ULINE_BLACK ULINE_RED ULINE_GREEN ULINE_YELLOW ULINE_BLUE ULINE_PURPLE ULINE_CYAN ULINE_WHITE \
    BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_PURPLE BG_CYAN BG_WHITE \
    BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_PURPLE BRIGHT_CYAN BRIGHT_WHITE \
    BOLD_BRIGHT_BLACK BOLD_BRIGHT_RED BOLD_BRIGHT_GREEN BOLD_BRIGHT_YELLOW BOLD_BRIGHT_BLUE BOLD_BRIGHT_PURPLE BOLD_BRIGHT_CYAN BOLD_BRIGHT_WHITE \
    BG_BRIGHT_BLACK BG_BRIGHT_RED BG_BRIGHT_GREEN BG_BRIGHT_YELLOW BG_BRIGHT_BLUE BG_BRIGHT_PURPLE BG_BRIGHT_CYAN BG_BRIGHT_WHITE \
    BOLD DIM ITALIC UNDERLINE BLINK REVERSE HIDDEN STRIKETHROUGH \
    BRIGHT_MAGENTA INFO OPTION ERROR BARR; do
    printf -v "$var" '%s' ''
  done
}

projectr_library_load() {
  # Lazy module loader for optional API layers.
  #
  # Supported names are intentionally friendly aliases. This function is public
  # because external scripts may want to opt into more capabilities explicitly:
  #
  #   projectr_library_load plugins dry-run state
  #
  # Loading a module should only define functions. Expensive/mutating actions are
  # still behind explicit API calls such as projectr_state_init or
  # projectr_install_tool.
  local module
  for module in "$@"; do
    case "$module" in
      core)
        projectr_library_source_file core/strict_mode "$PROJECTR_ROOT/lib/core/strict_mode.sh" || return $?
        projectr_library_source_file core/array_context "$PROJECTR_ROOT/lib/core/array_context.sh" || return $?
        ;;
      colors|colours|ui-colors)
        projectr_library_source_file core/colours "$PROJECTR_ROOT/lib/core/colours.sh" || return $?
        [[ -n "${NO_COLOR:-}" || "${PROJECTR_NO_COLOR:-0}" == "1" ]] && projectr_library_disable_color
        ;;
      display)
        projectr_library_load colors || return $?
        projectr_library_source_file core/display "$PROJECTR_ROOT/lib/core/display.sh" || return $?
        ;;
      logging)
        projectr_library_source_file core/logging "$PROJECTR_ROOT/lib/core/logging.sh" || return $?
        ;;
      config)
        # config.sh historically calls config_init at source time. Preserve CLI
        # behavior by default, but suppress auto-init for library loading.
        local projectr__old_auto="${PROJECTR_CONFIG_AUTO_INIT-__unset__}"
        PROJECTR_CONFIG_AUTO_INIT=0 projectr_library_source_file data/config "$PROJECTR_ROOT/lib/data/config.sh" || return $?
        if [[ "$projectr__old_auto" == "__unset__" ]]; then
          unset PROJECTR_CONFIG_AUTO_INIT
        else
          PROJECTR_CONFIG_AUTO_INIT="$projectr__old_auto"
        fi
        ;;
      detection|detect)
        projectr_library_source_file system/detect "$PROJECTR_ROOT/lib/system/detect.sh" || return $?
        ;;
      resolver|managers)
        projectr_library_load detection || return $?
        projectr_library_source_file system/resolver "$PROJECTR_ROOT/lib/system/resolver.sh" || return $?
        ;;
      registry|tools)
        projectr_library_load core detection resolver || return $?
        projectr_library_source_file data/tool_meta "$PROJECTR_ROOT/lib/data/tool_meta.sh" || return $?
        projectr_library_source_file data/tools "$PROJECTR_ROOT/lib/data/tools.sh" || return $?
        ;;
      plugins|plugin-loader)
        projectr_library_load registry || return $?
        projectr_library_source_file features/plugin_loader "$PROJECTR_ROOT/lib/features/plugin_loader.sh" || return $?
        ;;
      dry-run|dryrun|planner)
        projectr_library_load registry || return $?
        projectr_library_source_file features/dry_run "$PROJECTR_ROOT/lib/features/dry_run.sh" || return $?
        ;;
      profile|profiles)
        projectr_library_load registry dry-run || return $?
        projectr_library_source_file features/profile_code "$PROJECTR_ROOT/lib/features/profile_code.sh" || return $?
        projectr_library_source_file features/profile_manager "$PROJECTR_ROOT/lib/features/profile_manager.sh" || return $?
        ;;
      state)
        projectr_library_load registry || return $?
        projectr_library_source_file features/state "$PROJECTR_ROOT/lib/features/state.sh" || return $?
        ;;
      spinner)
        projectr_library_load display || return $?
        projectr_library_source_file core/spinner "$PROJECTR_ROOT/lib/core/spinner.sh" || return $?
        ;;
      prompts)
        projectr_library_load display || return $?
        projectr_library_source_file core/prompts "$PROJECTR_ROOT/lib/core/prompts.sh" || return $?
        ;;
      privilege)
        projectr_library_load colors || return $?
        projectr_library_source_file system/privilege "$PROJECTR_ROOT/lib/system/privilege.sh" || return $?
        ;;
      install|installer)
        projectr_library_load colors display logging core privilege state spinner || return $?
        projectr_library_source_file features/snapshot "$PROJECTR_ROOT/lib/features/snapshot.sh" || return $?
        projectr_library_source_file features/post_install "$PROJECTR_ROOT/lib/features/post_install.sh" || return $?
        projectr_library_source_file features/special_setup "$PROJECTR_ROOT/lib/features/special_setup.sh" || return $?
        projectr_library_source_file features/installer "$PROJECTR_ROOT/lib/features/installer.sh" || return $?
        ;;
      uninstall|uninstaller)
        projectr_library_load colors display logging core privilege state spinner prompts || return $?
        projectr_library_source_file features/special_setup "$PROJECTR_ROOT/lib/features/special_setup.sh" || return $?
        projectr_library_source_file features/uninstaller "$PROJECTR_ROOT/lib/features/uninstaller.sh" || return $?
        ;;
      full)
        projectr_library_load registry plugins dry-run profile state install uninstall || return $?
        ;;
      *)
        projectr__api_error "unknown library module '$module'"
        return 2
        ;;
    esac
  done
}

# Load the minimal read-only API immediately. This is safe and has no writes.
projectr_library_load registry || return $?

projectr_init() {
  # Initialize optional library services. This is intentionally explicit.
  #
  # Defaults:
  #   - detect package manager;
  #   - load local TOML plugins from tools.d/;
  #   - do not initialize config/state/log files.
  #
  # Options:
  #   --no-detect      Skip package manager detection.
  #   --plugins        Load tools.d/*.toml plugins (default).
  #   --no-plugins     Do not load plugins.
  #   --state          Load state module and initialize state storage.
  #   --config         Load config module and initialize config storage.
  #   --logging        Load real logging module; otherwise log functions are no-op.
  #   --no-color       Keep ProjectR color variables empty/plain.
  local detect=1 plugins=1 state=0 config=0 logging=0 arg
  for arg in "$@"; do
    case "$arg" in
      --no-detect) detect=0 ;;
      --plugins) plugins=1 ;;
      --no-plugins) plugins=0 ;;
      --state) state=1 ;;
      --config) config=1 ;;
      --logging) logging=1 ;;
      --no-color) export PROJECTR_NO_COLOR=1 NO_COLOR=1; projectr_library_disable_color ;;
      -h|--help)
        cat <<'EOF'
Usage: projectr_init [--no-detect] [--plugins|--no-plugins] [--state] [--config] [--logging] [--no-color]

Initializes optional ProjectR library services. Sourcing lib/projectr.sh already
loads the safe registry/detection helpers; this function opts into discovery and
optional storage/logging modules.
EOF
        return 0
        ;;
      *)
        projectr__api_error "unknown projectr_init option '$arg'"
        return 2
        ;;
    esac
  done

  if [[ $logging -eq 1 ]]; then
    projectr_library_load logging || return $?
  fi
  if [[ $detect -eq 1 ]]; then
    detect_pkg_manager >/dev/null 2>&1 || true
  fi
  if [[ $plugins -eq 1 ]]; then
    projectr_load_plugins || return $?
  fi
  if [[ $config -eq 1 ]]; then
    projectr_library_load config || return $?
    config_init
  fi
  if [[ $state -eq 1 ]]; then
    projectr_library_load state || return $?
    projectr_state_init
  fi
  declare -g PROJECTR_INITIALIZED=1
}

projectr_api_help() {
  cat <<'EOF'
ProjectR Bash API quick reference

Source:
  source /path/to/ProjectR/lib/projectr.sh

Initialize optional discovery/plugins:
  projectr_init
  projectr_init --no-plugins

Registry:
  projectr_tool_lookup git
  projectr_tool_get git name
  projectr_tool_list --format=tsv
  projectr_tool_list --format=json --category Dev
  projectr_tool_categories

Managers:
  projectr_detect_manager
  projectr_detect_managers
  projectr_detect_language_manager npm

Planning:
  projectr_plan_install git --json
  projectr_plan_profile projectr.yml --json

State/mutation modules are lazy-loaded and explicit:
  projectr_state_records_api
  projectr_install_tool git
  projectr_uninstall_tool git

For full documentation, see docs/api.md.
EOF
}

projectr_root() { printf '%s\n' "$PROJECTR_ROOT"; }
projectr_version() { printf '%s\n' "$PROJECTR_VERSION"; }
projectr_api_version() { printf '%s\n' "$PROJECTR_API_VERSION"; }

projectr_library_modules() {
  local key
  for key in "${!PROJECTR_LIBRARY_SOURCED[@]}"; do
    printf '%s\n' "$key"
  done | sort
}

projectr_json_escape() {
  local value="${1-}"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\t'/\\t}
  value=${value//$'\r'/\\r}
  value=${value//$'\n'/\\n}
  printf '%s' "$value"
}

projectr_detect_manager() { detect_pkg_manager; }

projectr_detect_managers() {
  # Return every manager ProjectR can currently discover for this machine,
  # including native managers plus language/ecosystem managers such as pipx,
  # pip3, npm, cargo, gem, go, and composer.
  projectr_library_load resolver || return $?
  projectr_candidate_managers
}

projectr_detect_language_manager() {
  local type="${1:-system}"
  detect_pkg_for_tool "$type"
}

projectr_manager_candidates() {
  projectr_library_load resolver || return $?
  projectr_candidate_managers
}

projectr_tool_count() { printf '%s\n' "${#TOOLS[@]}"; }

projectr_tool_entries() {
  printf '%s\n' "${TOOLS[@]}"
}

projectr_tool_lookup() {
  local target="${1:-}"
  [[ -n "$target" ]] || {
    projectr__api_error "projectr_tool_lookup requires a target"
    return 2
  }
  projectr_tool_lookup_entry "$target"
}

projectr_tool_lookup_cmd() {
  local target="${1:-}"
  [[ -n "$target" ]] || {
    projectr__api_error "projectr_tool_lookup_cmd requires a command id"
    return 2
  }
  projectr_tool_lookup_cmd_entry "$target"
}

projectr_entry_field() {
  # Extract one field from a raw TOOLS entry.
  # Field names: num, cmd, pkg, name, desc, type, extra, category/cat
  local entry="${1:-}" field="${2:-}"
  local num cmd pkg name desc type extra cat
  [[ -n "$entry" && -n "$field" ]] || {
    projectr__api_error "projectr_entry_field requires <entry> <field>"
    return 2
  }
  IFS='|' read -r num cmd pkg name desc type extra cat <<<"$entry"
  case "$field" in
    num|number|id) printf '%s\n' "$num" ;;
    cmd|command) printf '%s\n' "$cmd" ;;
    pkg|package) printf '%s\n' "$pkg" ;;
    name|display) printf '%s\n' "$name" ;;
    desc|description) printf '%s\n' "$desc" ;;
    type) printf '%s\n' "$type" ;;
    extra|hook) printf '%s\n' "$extra" ;;
    cat|category) printf '%s\n' "$cat" ;;
    *)
      projectr__api_error "unknown tool field '$field'"
      return 2
      ;;
  esac
}

projectr_tool_get() {
  local target="${1:-}" field="${2:-}" entry
  [[ -n "$target" && -n "$field" ]] || {
    projectr__api_error "projectr_tool_get requires <target> <field>"
    return 2
  }
  entry=$(projectr_tool_lookup "$target") || return $?
  projectr_entry_field "$entry" "$field"
}

projectr_entry_json() {
  local entry="${1:-}"
  local num cmd pkg name desc type extra cat
  [[ -n "$entry" ]] || return 1
  IFS='|' read -r num cmd pkg name desc type extra cat <<<"$entry"
  printf '{"num":%s,"cmd":"%s","package":"%s","name":"%s","description":"%s","type":"%s","extra":"%s","category":"%s"}' \
    "$(projectr_json_escape "$num")" \
    "$(projectr_json_escape "$cmd")" \
    "$(projectr_json_escape "$pkg")" \
    "$(projectr_json_escape "$name")" \
    "$(projectr_json_escape "$desc")" \
    "$(projectr_json_escape "$type")" \
    "$(projectr_json_escape "$extra")" \
    "$(projectr_json_escape "$cat")"
}

projectr_tool_json() {
  local target="${1:-}" entry
  entry=$(projectr_tool_lookup "$target") || return $?
  projectr_entry_json "$entry"
  printf '\n'
}

projectr_tool_categories() {
  local entry num cmd pkg name desc type extra cat
  local -A seen=()
  for entry in "${TOOLS[@]}"; do
    IFS='|' read -r num cmd pkg name desc type extra cat <<<"$entry"
    [[ -n "${seen[$cat]+set}" ]] && continue
    seen[$cat]=1
    printf '%s\n' "$cat"
  done
}

projectr_tool_list() {
  # List registry entries in a script-friendly way.
  #
  # Formats:
  #   --format=tsv       num<TAB>cmd<TAB>pkg<TAB>name<TAB>desc<TAB>type<TAB>extra<TAB>category
  #   --format=plain     human-readable columns
  #   --format=json      JSON array
  #   --format=commands  command ids only
  #   --format=names     display names only
  local format="tsv" category="" type_filter=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --format=*) format="${1#--format=}" ;;
      --format)
        shift
        [[ $# -gt 0 ]] || {
          projectr__api_error "--format requires a value"
          return 2
        }
        format="$1"
        ;;
      --category=*) category="${1#--category=}" ;;
      --category)
        shift
        [[ $# -gt 0 ]] || {
          projectr__api_error "--category requires a value"
          return 2
        }
        category="$1"
        ;;
      --type=*) type_filter="${1#--type=}" ;;
      --type)
        shift
        [[ $# -gt 0 ]] || {
          projectr__api_error "--type requires a value"
          return 2
        }
        type_filter="$1"
        ;;
      --help|-h)
        cat <<'EOF'
Usage: projectr_tool_list [--format=tsv|plain|json|commands|names] [--category=<name>] [--type=<type>]
EOF
        return 0
        ;;
      *)
        projectr__api_error "unknown projectr_tool_list option '$1'"
        return 2
        ;;
    esac
    shift
  done

  case "$format" in
    tsv|plain|commands|names|json) ;;
    *)
      projectr__api_error "unknown list format '$format'"
      return 2
      ;;
  esac

  local entry num cmd pkg name desc type extra cat first=1
  [[ "$format" == "json" ]] && printf '['
  for entry in "${TOOLS[@]}"; do
    IFS='|' read -r num cmd pkg name desc type extra cat <<<"$entry"
    [[ -n "$category" && "$cat" != "$category" ]] && continue
    [[ -n "$type_filter" && "$type" != "$type_filter" ]] && continue
    case "$format" in
      tsv)
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$num" "$cmd" "$pkg" "$name" "$desc" "$type" "$extra" "$cat"
        ;;
      plain)
        printf '%3s  %-18s %-22s %-10s %s\n' "$num" "$cmd" "$pkg" "$type" "$name"
        ;;
      commands)
        printf '%s\n' "$cmd"
        ;;
      names)
        printf '%s\n' "$name"
        ;;
      json)
        [[ $first -eq 0 ]] && printf ','
        first=0
        projectr_entry_json "$entry"
        ;;
      *)
        projectr__api_error "unknown list format '$format'"
        [[ "$format" == "json" ]] && printf ']\n'
        return 2
        ;;
    esac
  done
  [[ "$format" == "json" ]] && printf ']\n'
  return 0
}

projectr_tool_effective_cmd() {
  local target="${1:-}" manager="${2:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}" entry cmd tool_id effective_cmd
  entry=$(projectr_tool_lookup "$target") || return $?
  IFS='|' read -r _ cmd _ _ _ _ _ _ <<<"$entry"
  projectr_tool_id_into tool_id "$cmd"
  projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$manager"
  printf '%s\n' "$effective_cmd"
}

projectr_tool_effective_package() {
  local target="${1:-}" manager="${2:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}" entry cmd pkg tool_id effective_pkg
  entry=$(projectr_tool_lookup "$target") || return $?
  IFS='|' read -r _ cmd pkg _ _ _ _ _ <<<"$entry"
  projectr_tool_id_into tool_id "$cmd"
  projectr_effective_package_into effective_pkg "$tool_id" "$pkg" "$manager"
  printf '%s\n' "$effective_pkg"
}

projectr_tool_installed() {
  local target="${1:-}" manager="${2:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}" effective_cmd
  effective_cmd=$(projectr_tool_effective_cmd "$target" "$manager") || return $?
  projectr_command_exists "$effective_cmd"
}

projectr_tool_path() {
  local target="${1:-}" manager="${2:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}" effective_cmd
  effective_cmd=$(projectr_tool_effective_cmd "$target" "$manager") || return $?
  projectr_command_path "$effective_cmd"
}

projectr_tool_status() {
  local target="${1:-}" manager="${2:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}" effective_cmd
  effective_cmd=$(projectr_tool_effective_cmd "$target" "$manager") || return $?
  if projectr_command_exists "$effective_cmd"; then
    printf 'installed	%s	%s\n' "$effective_cmd" "$(projectr_command_path "$effective_cmd")"
  else
    printf 'missing	%s	-\n' "$effective_cmd"
    return 1
  fi
}

projectr_load_plugins() {
  projectr_library_load plugins || return $?
  projectr_load_tool_plugins
}

projectr_plan_install() {
  projectr_library_load dry-run || return $?
  projectr_dry_run_install "$@"
}

projectr_plan_profile() {
  projectr_library_load profile || return $?
  local file="${1:-}"
  shift || true
  projectr_dry_run_profile "$file" "$@"
}

projectr_profile_diff_api() {
  projectr_library_load profile || return $?
  projectr_profile_diff "$@"
}

projectr_state_records_api() {
  projectr_library_load state || return $?
  projectr_state_records
}

projectr_state_verify_api() {
  projectr_library_load state || return $?
  projectr_verify_state
}

projectr_install_tool() {
  # Mutating API. This intentionally loads the installer stack and then delegates
  # to existing ProjectR install functions. Use projectr_plan_install first when
  # embedding this in automation.
  projectr_library_load install || return $?
  local target entry cmd pkg name desc type extra cat rc status=0
  local -a INSTALLED_PKGS=() SKIPPED_PKGS=() FAILED_PKGS=()
  [[ $# -gt 0 ]] || {
    projectr__api_error "projectr_install_tool requires at least one target"
    return 2
  }
  for target in "$@"; do
    entry=$(projectr_tool_lookup "$target") || {
      projectr__api_error "unknown tool '$target'"
      status=1
      continue
    }
    IFS='|' read -r _ cmd pkg name desc type extra cat <<<"$entry"
    projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
    rc=$?
    [[ $rc -ne 0 ]] && status=$rc
  done
  return "$status"
}

projectr_uninstall_tool() {
  # Mutating API. Confirmation prompts still happen unless the caller sets
  # NON_INTERACTIVE=1 or uses wrappers around ask_confirm.
  projectr_library_load uninstall || return $?
  local target entry cmd pkg name desc type extra cat rc status=0
  [[ $# -gt 0 ]] || {
    projectr__api_error "projectr_uninstall_tool requires at least one target"
    return 2
  }
  for target in "$@"; do
    entry=$(projectr_tool_lookup "$target") || {
      projectr__api_error "unknown tool '$target'"
      status=1
      continue
    }
    IFS='|' read -r _ cmd pkg name desc type extra cat <<<"$entry"
    projectr_uninstall_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
    rc=$?
    [[ $rc -ne 0 ]] && status=$rc
  done
  return "$status"
}

# If someone executes this file directly, print a helpful message instead of
# silently doing nothing. The library is meant to be sourced.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  projectr_api_help
fi
