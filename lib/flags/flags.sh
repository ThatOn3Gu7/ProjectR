#!/bin/bash
# shellcheck disable=SC2034,SC2088,SC2064,SC2178,SC2188,SC1090
# -- for safely sourcing files --
_FLAGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(cd "$_FLAGS_DIR/../.." && pwd)"

# Central flag dispatcher — called before the main interactive loop.
# Each --flag or --flag=value is handled here and exits immediately.
parse_flags() {
  # flags.sh is the one dispatcher for both modern commands and legacy flags.
  # Feature-specific implementation still lives in lib/core or lib/features,
  # but every CLI argument is routed from this function.
  [[ $# -eq 0 ]] && return 0
  local args=() arg idx source_next=""
  for ((idx = 1; idx <= $#; idx++)); do
    arg="${!idx}"
    if [[ -n "$source_next" ]]; then
      export PROJECTR_INSTALL_MANAGER_OVERRIDE="$arg"
      source_next=""
      continue
    fi
    case "$arg" in
    --no-color)
      export PROJECTR_NO_COLOR=1
      if declare -f projectr_disable_color >/dev/null 2>&1; then
        projectr_disable_color
      fi
      ;;
    --quiet)
      export PROJECTR_QUIET=1
      ;;
    --source)
      source_next=1
      ;;
    --source=*)
      export PROJECTR_INSTALL_MANAGER_OVERRIDE="${arg#--source=}"
      ;;
    *) args+=("$arg") ;;
    esac
  done

  # If only global display flags were provided, continue into interactive mode.
  [[ ${#args[@]} -eq 0 ]] && return 0
  set -- "${args[@]}"
  log INFO "CLI dispatch: $*" "cli"

  case "$1" in
  --version | -v | version)
    echo -e "${OPTION}projectr ${BOLD_WHITE}v1.4${RST}"
    exit 0
    ;;

  --help | -h | help)
    if declare -f projectr_cli_help >/dev/null 2>&1; then
      projectr_cli_help
      exit 0
    fi
    ;;

  install | --install)
    shift
    projectr_cli_install_args "$@"
    exit $?
    ;;

  --install=*)
    local first_target="${1#--install=}"
    shift
    projectr_cli_install_args "$first_target" "$@"
    exit $?
    ;;

  uninstall | --uninstall)
    shift
    projectr_cli_uninstall_args "$@"
    exit $?
    ;;

  --uninstall=*)
    local first_target="${1#--uninstall=}"
    shift
    projectr_cli_uninstall_args "$first_target" "$@"
    exit $?
    ;;

  search | --search)
    shift
    [[ -n "${1:-}" ]] || {
      echo -e "${ERROR}[ℹ] search requires a name.${RST}"
      log_error "search command missing required name" "cli"
      exit 1
    }
    _flag_search "$1"
    exit $?
    ;;

  --search=*)
    _flag_search "${1#--search=}"
    exit $?
    ;;

  list | --list)
    shift
    projectr_cli_list_arg "${1:-tools}"
    exit $?
    ;;

  --list=*)
    projectr_cli_list_arg "${1#--list=}"
    exit $?
    ;;

  dry-run | --dry-run)
    shift
    case "${1:-}" in
    "")
      projectr_dry_run_install
      ;;
    install)
      shift
      projectr_dry_run_install "$@"
      ;;
    reset | --reset)
      shift
      _flag_reset --dry-run "$@"
      ;;
    upgrade | --upgrade)
      shift
      projectr_cli_upgrade_args --dry-run "$@"
      ;;
    repair | --repair)
      shift
      projectr_dry_run_repair "$@"
      ;;
    --profile)
      shift
      projectr_dry_run_profile "$@"
      ;;
    --profile=*)
      local profile_path="${1#--profile=}"
      shift
      projectr_dry_run_profile "$profile_path" "$@"
      ;;
    *)
      projectr_dry_run_install "$@"
      ;;
    esac
    exit $?
    ;;

  --profile)
    shift
    projectr_cli_install_args --profile "$@"
    exit $?
    ;;

  --profile=*)
    projectr_install_profile "${1#--profile=}"
    exit $?
    ;;

  log | --log)
    shift
    _flag_log "${1:-20}"
    exit $?
    ;;

  --log=*)
    _flag_log "${1#--log=}"
    exit $?
    ;;

  reset | --reset)
    shift
    _flag_reset "$@"
    exit $?
    ;;

  export | --export)
    export_profile
    exit $?
    ;;

  export-lock | --export-lock)
    export_profile_lock
    exit $?
    ;;

  import | --import)
    shift
    [[ -n "${1:-}" ]] || {
      echo -e "${ERROR}[ℹ] import requires a file path.${RST}"
      log_error "import command missing file path" "cli"
      exit 1
    }
    import_profile "$1"
    exit $?
    ;;

  --import=*)
    import_profile "${1#--import=}"
    exit $?
    ;;

  undo | --undo)
    rollback_last_session
    exit $?
    ;;

  upgrade | --upgrade)
    shift
    projectr_cli_upgrade_args "$@"
    exit $?
    ;;

  update | --update | self-update | --self-update | projectr-update | --projectr-update)
    projectr_run_update
    exit $?
    ;;

  doctor | --doctor)
    shift
    projectr_doctor "$@"
    exit $?
    ;;

  diff | profile-diff)
    shift
    projectr_profile_diff "$@"
    exit $?
    ;;

  --diff-profile)
    shift
    projectr_profile_diff --profile "$@"
    exit $?
    ;;

  --diff-profile=*)
    local diff_profile_path="${1#--diff-profile=}"
    shift
    projectr_profile_diff --profile "$diff_profile_path" "$@"
    exit $?
    ;;

  audit | --audit)
    shift
    projectr_audit_tools "$@"
    exit $?
    ;;

  verify | --verify)
    projectr_verify_state
    exit $?
    ;;

  repair | --repair)
    shift
    if [[ "${1:-}" == "--dry-run" ]]; then
      shift
      projectr_dry_run_repair "$@"
    else
      projectr_repair_state
    fi
    exit $?
    ;;

  scheduler | --scheduler)
    shift
    projectr_cli_scheduler_args "$@"
    exit $?
    ;;

  completions | --completions)
    shift
    [[ "${1:-}" == "bash" ]] || {
      echo "Only bash completions are currently supported."
      exit 1
    }
    projectr_completions_bash
    exit 0
    ;;

  --* | -*)
    echo -e "${ERROR}[ℹ] Unknown flag: ${BOLD_WHITE}$1${RST}"
    log_error "Unknown flag: $1" "cli"
    echo -e "${INFO}[*] Run ${BOLD_WHITE}${PROJECTR_LAUNCHER_NAME:-./main.sh} --help or -h${RST}${INFO} to see available flags.${RST}"
    exit 1
    ;;

  *)
    echo -e "${ERROR}[ℹ] Unknown command: ${BOLD_WHITE}$1${RST}"
    log_error "Unknown command: $1" "cli"
    echo -e "${INFO}[*] Run ${BOLD_WHITE}${PROJECTR_LAUNCHER_NAME:-./main.sh} --help or -h${RST}${INFO} to see available commands.${RST}"
    exit 1
    ;;
  esac
}

_flag_list_tools() {

  echo ""
  # ── Header ──
  echo -e "${BOLD}${OPTION} [*] Available Tools for install ${RST}"
  echo ""

  # ── Table ───
  printf "  ${BOLD_WHITE}%-4s  %-16s  %-40s${RST}\n" \
    "Num" "Name" "Description"
  local sep
  printf -v sep '%*s' 66 ''
  sep=${sep// /─}
  printf "  ${DIM}%s${RST}\n" "$sep"

  # Data
  local entry num cmd pkg name desc type extra cat disp_desc
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    disp_desc="$desc"
    ((${#disp_desc} > 40)) && disp_desc="${disp_desc:0:37}..."
    printf "  ${BARR}%-4s${RST}  ${OPTION}%-16s${RST}  ${DIM}%-40s${RST}\n" \
      "$num" "$name" "$disp_desc"
  done

  # ── Summary ───
  echo ""
  printf "  ${DIM}%s${RST}\n" "$sep"
  echo -e "  ${DIM}Total:${RST}  ${BOLD_WHITE}${#TOOLS[@]}${RST} tools available"
  echo ""
}
# --list=manager : shows all known package managers, their status and OS support
_flag_list_manager() {
  # ── OS/platform detection ───
  local detected_os="Unknown"
  local detected_pm uname_s
  detected_pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
  uname_s=$(uname -s 2>/dev/null || printf 'Unknown')

  if [ -n "${PREFIX:-}" ] && [[ "$PREFIX" == *termux* ]]; then
    detected_os="Termux (Android)"
  elif [[ "$uname_s" == "Darwin" ]]; then
    detected_os="macOS"
  elif [[ -f /etc/os-release ]]; then
    detected_os=$(. /etc/os-release && echo "${PRETTY_NAME:-Linux}")
  elif [[ "$uname_s" == *"MINGW"* ]] || [[ "$uname_s" == *"CYGWIN"* ]]; then
    detected_os="Windows (WSL/Cygwin)"
  else
    detected_os="Linux"
  fi

  # ── Manager registry ───
  # Format: id|display|scope|platform/ecosystem|command-to-check
  #
  # Native managers are used as ProjectR's PRIMARY_PKG_MANAGER. Universal app
  # managers and language/ecosystem managers are also listed because ProjectR can
  # use several of them for search/install flows, but they are intentionally not
  # promoted to primary system manager status.
  local managers=(
    "apt|apt|Native|Linux (Debian/Ubuntu)|apt"
    "apt-get|apt-get|Native|Linux (Debian/Ubuntu)|apt-get"
    "pacman|pacman|Native|Linux (Arch)|pacman"
    "dnf|dnf|Native|Linux (Fedora/RHEL)|dnf"
    "yum|yum|Native|Linux (CentOS/RHEL)|yum"
    "zypper|zypper|Native|Linux (openSUSE)|zypper"
    "apk|apk|Native|Linux (Alpine)|apk"
    "emerge|emerge|Native|Linux (Gentoo)|emerge"
    "xbps|xbps-install|Native|Linux (Void)|xbps-install"
    "nix|nix|Native|Linux/macOS (NixOS)|nix"
    "guix|guix|Native|Linux (GNU Guix)|guix"
    "eopkg|eopkg|Native|Linux (Solus)|eopkg"
    "urpmi|urpmi|Native|Linux (Mageia)|urpmi"
    "slackpkg|slackpkg|Native|Linux (Slackware)|pkgtool"
    "pkg|pkg (Termux)|Native|Termux (Android)|pkg"
    "brew|brew|Native|macOS / Linux|brew"
    "macports|port|Native|macOS|port"
    "bsd-pkg|pkg (FreeBSD)|Native|FreeBSD|pkg"
    "pkg_add|pkg_add|Native|OpenBSD|pkg_add"
    "winget|winget|Native|Windows|winget.exe"
    "choco|choco|Native|Windows|choco.exe"
    "scoop|scoop|Native|Windows|scoop"
    "flatpak|flatpak|Universal|Linux desktop apps|flatpak"
    "snap|snap|Universal|Linux app packages|snap"
    "pipx|pipx|Language|Python CLI apps|pipx"
    "pip3|pip3|Language|Python packages|pip3"
    "pip|pip|Language|Python packages|pip"
    "npm|npm|Language|Node.js packages|npm"
    "yarn|yarn|Language|Node.js packages|yarn"
    "pnpm|pnpm|Language|Node.js packages|pnpm"
    "bun|bun|Language|Bun/JavaScript packages|bun"
    "gem|gem|Language|Ruby gems|gem"
    "cargo|cargo|Language|Rust crates|cargo"
    "go|go|Language|Go modules|go"
    "composer|composer|Language|PHP packages|composer"
    "uv|uv|Language|Python packages/projects|uv"
    "poetry|poetry|Language|Python projects|poetry"
    "pipenv|pipenv|Language|Python virtualenvs|pipenv"
    "conda|conda|Language|Conda environments|conda"
    "mamba|mamba|Language|Conda environments|mamba"
    "bundler|bundler|Language|Ruby bundle manager|bundle"
    "luarocks|luarocks|Language|Lua rocks|luarocks"
    "dotnet|dotnet|Language|.NET packages|dotnet"
    "nuget|nuget|Language|.NET/NuGet packages|nuget"
    "opam|opam|Language|OCaml packages|opam"
    "cabal|cabal|Language|Haskell packages|cabal"
    "stack|stack|Language|Haskell projects|stack"
    "mix|mix|Language|Elixir projects|mix"
    "rebar3|rebar3|Language|Erlang projects|rebar3"
  )

  # ── Header ───
  echo ""
  echo -e "${OPTION} [*] ProjectR — Package and Ecosystem Managers ${RST}"
  echo ""
  echo -e "  ${DIM}Native system managers, universal app managers, and language ecosystem managers known to ProjectR."
  echo -e "  Legend:  ${OPTION}✔${RST} = available, ${ERROR}✖${RST} = not found,  ${OPTION}★${RST} = primary native manager${RST}"
  echo ""

  # ── Dynamic column widths ───
  local max_name=15     # "Package Manager"
  local max_scope=9     # "Scope"
  local max_platform=12 # "Platform / Ecosystem"
  local entry id display scope platform check_cmd
  for entry in "${managers[@]}"; do
    IFS="|" read -r id display scope platform _ <<<"$entry"
    ((${#display} > max_name)) && max_name=${#display}
    ((${#scope} > max_scope)) && max_scope=${#scope}
    ((${#platform} > max_platform)) && max_platform=${#platform}
  done
  ((max_name < 15)) && max_name=15
  ((max_scope < 9)) && max_scope=9
  ((max_platform < 20)) && max_platform=20

  printf "  %b%-${max_name}s  %-6s  %-${max_scope}s  %-${max_platform}s%b\n" \
    "$BOLD_WHITE" "Package Manager" "Avail" "Scope" "Platform / Ecosystem" "$RST"

  local sep
  printf -v sep '%*s' $((max_name + 8 + max_scope + 2 + max_platform + 2)) ''
  sep=${sep// /─}
  printf "  %b%s%b\n" "$DIM" "$sep" "$RST"

  # ── Table rows ───
  local available_list=()
  local available_native=0 available_universal=0 available_language=0 total_available=0 total_known=${#managers[@]}
  for entry in "${managers[@]}"; do
    IFS="|" read -r id display scope platform check_cmd <<<"$entry"

    # Force FreeBSD pkg to be unavailable on Termux so Termux's pkg executable
    # is not double-counted as the FreeBSD manager.
    local force_unavailable=0
    [[ "$detected_os" == "Termux (Android)" && "$id" == "bsd-pkg" ]] && force_unavailable=1

    local icon icon_color marker=""
    if ((force_unavailable)); then
      icon="✖"
      icon_color="${ERROR}"
    elif projectr_command_exists "$check_cmd"; then
      icon="✔"
      icon_color="${OPTION}"
      available_list+=("$display")
      total_available=$((total_available + 1))
      case "$scope" in
      Native) available_native=$((available_native + 1)) ;;
      Universal) available_universal=$((available_universal + 1)) ;;
      Language) available_language=$((available_language + 1)) ;;
      esac
      # Mark only the primary native package manager, not language managers.
      [[ "$scope" == "Native" && "$id" == "$detected_pm" ]] && marker=" ${OPTION}★${RST}"
    else
      icon="✖"
      icon_color="${ERROR}"
    fi

    printf "  %b%-${max_name}s%b  %b%-6s%b  %b%-${max_scope}s%b  %b%-${max_platform}s%b%b\n" \
      "$BOLD_WHITE" "$display" "$RST" \
      "$icon_color" "$icon" "$RST" \
      "$INFO" "$scope" "$RST" \
      "$DIM" "$platform" "$RST" \
      "$marker"
  done

  # ── Footer ───
  echo ""
  printf "  %b%s%b\n" "$DIM" "$sep" "$RST"
  echo -e "  ${INFO}Detected OS :${RST}  ${BOLD_WHITE}${detected_os}${RST}"
  echo -e "  ${INFO}Primary PM  :${RST} ${OPTION} ${detected_pm}${RST}"
  echo -e "  ${INFO}Available   :${RST}  ${BOLD_WHITE}${total_available}${RST}${DIM}/${total_known}${RST} ${DIM}(native=${available_native}, universal=${available_universal}, language=${available_language})${RST}"

  if [ ${#available_list[@]} -gt 0 ]; then
    echo -e "  ${INFO}Found       :${RST}  ${BOLD_WHITE}${available_list[*]}${RST}"
  fi
  echo ""
}
# ── --list=installed ───
_flag_list_installed() {
  echo ""
  echo -e "${OPTION} [*] Installed Tools ${RST}"
  echo ""

  local found=()
  local not_found=()
  local manager="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
  local entry num cmd pkg name desc type extra cat tool_id effective_cmd version version_line

  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    projectr_tool_id_into tool_id "$cmd"
    projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$manager"
    if projectr_command_exists "$effective_cmd"; then
      version="--"
      version_line=""
      IFS= read -r version_line < <("$effective_cmd" --version 2>/dev/null || true)
      if [[ "$version_line" =~ ([0-9]+([.][0-9]+)+) ]]; then
        version="${BASH_REMATCH[1]}"
      fi
      found+=("$num|$name|$cat|$version")
    else
      not_found+=("$name")
    fi
  done

  if [ ${#found[@]} -eq 0 ]; then
    echo -e "  ${ERROR}[ℹ] No tools from the list are currently installed.${RST}"
    echo ""
    return
  fi

  printf "  ${BOLD_WHITE}%-4s  %-16s  %-10s  %-10s${RST}\n" \
    "Num" "Name" "Category" "Version"
  local sep
  printf -v sep '%*s' 46 ''
  sep=${sep// /─}
  printf "  ${DIM}%s${RST}\n" "$sep"

  for entry in "${found[@]}"; do
    IFS="|" read -r num name cat version <<<"$entry"
    printf "  ${BARR}%-4s${RST}  ${OPTION}%-16s${RST}  ${INFO}%-10s${RST}  ${DIM}%-10s${RST}\n" \
      "$num" "$name" "$cat" "$version"
  done

  echo ""
  printf "  ${DIM}%s${RST}\n" "$sep"
  echo -e "  ${OPTION}[*] Installed : ${BOLD_WHITE}${#found[@]}${RST} / ${#TOOLS[@]}${RST}"
  echo -e "  ${ERROR}[*] Missing   : ${BOLD_WHITE}${#not_found[@]}${RST} / ${#TOOLS[@]}${RST}"
  echo ""
}

# ── --list=categories ────
_flag_list_categories() {
  echo ""
  echo -e "${BOLD}${OPTION} [*] Tools listed by Category ${RST}"
  echo ""
  echo -e "${DIM}  Status:${RST}${GREEN} ✔ ${RST}= installed,${RED} ✖ ${RST}= not found"
  echo ""

  local manager="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
  local -a cats=()
  local -A seen_cats=()
  local -A category_rows=()
  local entry num cmd pkg name desc type extra cat status_icon status_color tool_id effective_cmd row

  # Single-pass grouping: this replaces the previous category loop that scanned
  # the entire registry once per category.
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r num cmd pkg name desc type extra cat <<<"$entry"
    if [[ -z "${seen_cats[$cat]+set}" ]]; then
      seen_cats[$cat]=1
      cats+=("$cat")
      category_rows[$cat]=""
    fi

    projectr_tool_id_into tool_id "$cmd"
    projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$manager"
    if projectr_command_exists "$effective_cmd"; then
      status_icon="✔" status_color="${OPTION}"
    else
      status_icon="✖" status_color="${ERROR}"
    fi
    printf -v row "  ${BARR}[%02d]${RST}  ${status_color}%s${RST}  ${BOLD_WHITE}%-14s${RST}  ${DIM}%s${RST}\n" \
      "$num" "$status_icon" "$name" "$desc"
    category_rows[$cat]+="$row"
  done

  local category sep
  printf -v sep '%*s' 50 ''
  sep=${sep// /─}
  for category in "${cats[@]}"; do
    echo -e "  ${BOLD_WHITE}${category}${RST}"
    printf "  ${DIM}%s${RST}\n" "$sep"
    printf '%b' "${category_rows[$category]}"
    echo ""
  done
}

# ── --log / --log=N ───
_flag_log() {
  local lines="${1:-20}"

  # Validate: must be a positive integer
  if [[ ! "$lines" =~ ^[0-9]+$ ]] || ((lines < 1)); then
    echo -e "  ${ERROR}[ℹ] Invalid value for --log: '${lines}' — must be a positive integer.${RST}"
    echo -e "  ${DIM}Example: ./main.sh --log=50${RST}"
    return 1
  fi

  # LOG_FILE is defined in logging.sh — but flags run before it's sourced,
  # so we hardcode the same path here to stay independent
  local log_path="${SCRIPT_DIR:-$(pwd)}/log/install.log"

  echo ""
  echo -e "${OPTION} [*] Install Log ${DIM}(last ${lines} lines)${RST}"
  echo ""

  if [ ! -f "$log_path" ]; then
    echo -e "  ${ERROR}[ℹ] No log file found at: ${BOLD_WHITE}${log_path}${RST}"
    echo -e "  ${DIM}Run the script interactively at least once to generate it.${RST}"
    echo ""
    return
  fi

  printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 60))"

  # Colour-code by log level
  tail -n "$lines" "$log_path" | while IFS= read -r line; do
    case "$line" in
    *\[INSTALL\]*) echo -e "  ${OPTION}${line}${RST}" ;;
    *\[FAIL\]*) echo -e "  ${ERROR}${line}${RST}" ;;
    *\[ERROR\]*) echo -e "  ${ERROR}${line}${RST}" ;;
    *\[SKIPPED\]*) echo -e "  ${DIM}${line}${RST}" ;;
    *\[EXIT\]*) echo -e "  ${INFO}${line}${RST}" ;;
    *\[OK\]*) echo -e "  ${OPTION}${line}${RST}" ;;
    *━━*) echo -e "  ${BOLD_WHITE}${line}${RST}" ;; # session separators
    *) echo -e "  ${line}" ;;
    esac
  done

  printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' $(seq 1 60))"
  echo -e "  ${DIM}Full log: ${BOLD_WHITE}${log_path}${RST}"
  echo ""
}

# ── --reset ───
_flag_reset() {
  local dry=0 arg
  for arg in "$@"; do
    case "$arg" in
    --dry-run) dry=1 ;;
    *)
      echo -e "${ERROR}[ℹ] Unknown reset option: $arg${RST}"
      return 2
      ;;
    esac
  done
  echo ""
  echo -e "${OPTION} [*] Reset Saved Preferences ${RST}"
  echo ""

  local config_path="${HOME}/.config/projectr/session.conf"

  if [ ! -f "$config_path" ]; then
    echo -e "  ${DIM} [*] Nothing to reset — no config file found.${RST}"
    echo ""
    return
  fi

  # Show what's currently saved before wiping
  local line_count
  line_count=$(wc -l <"$config_path")

  if [ "$line_count" -eq 0 ]; then
    echo -e "${DIM} [*] Config file is already empty.${RST}"
    echo ""
    return
  fi

  echo -e "${INFO} [*] Clearing ${BOLD_WHITE}${line_count}${RST}${INFO} saved preference(s):${RST}"
  echo ""
  while IFS= read -r line; do
    echo -e "    ${DIM}✖  ${line}${RST}"
  done <"$config_path"
  echo ""

  if [[ $dry -eq 1 ]]; then
    echo -e "${DIM} [DRY-RUN] Would clear ${config_path}; no preferences were changed.${RST}"
  else
    >"$config_path"
    echo -e "${OPTION} [✓] All preferences cleared.${RST}"
  fi
  echo ""
}

# ── --install=<name> ───
_flag_install() {
  local target="$1"
  echo ""
  echo -e "${OPTION} [*] Non-interactive install: ${BOLD_WHITE}${target}${RST}"
  echo ""

  # Find the matching tool entry using the lazy registry index.
  local matched_entry=""
  matched_entry=$(projectr_tool_lookup_entry "$target" 2>/dev/null || true)

  if [ -z "$matched_entry" ]; then
    echo -e "  ${ERROR}[ℹ] No tool named '${target}' found in the list.${RST}"
    echo -e "  ${DIM}Run ${BOLD_WHITE}./main.sh --list=tools${RST}${DIM} to see valid names.${RST}"
    echo ""
    return 1
  fi

  IFS="|" read -r num cmd pkg name desc type extra cat <<<"$matched_entry"
  local tool_id effective_cmd manager
  manager="${PROJECTR_INSTALL_MANAGER_OVERRIDE:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}"
  projectr_tool_id_into tool_id "$cmd"
  projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$manager"

  # Already installed?
  if command -v "$effective_cmd" >/dev/null 2>&1; then
    echo -e "  ${OPTION}[✓] ${name} is already installed — nothing to do.${RST}"
    echo ""
    return 0
  fi

  # special type tools can't run non-interactively (they prompt the user)
  if [[ "$type" == "special" ]]; then
    echo -e "  ${ERROR}[ℹ] '${name}' uses an interactive installer and can't be run via flag.${RST}"
    echo -e "  ${DIM}Launch the script normally and select [${num}] from the menu.${RST}"
    echo ""
    return 1
  fi

  # Guard: verify every required file exists before sourcing
  local _required=(
    "$_PROJECT_ROOT/lib/core/progress_bar.sh"
    "$_PROJECT_ROOT/lib/core/spinner.sh"
    "$_PROJECT_ROOT/lib/core/logging.sh"
  )
  for _f in "${_required[@]}"; do
    if [[ ! -f "$_f" ]]; then
      echo -e "  ${ERROR}[ℹ] Required file missing: $_f${RST}"
      echo -e "  ${DIM}Check that \$_PROJECT_ROOT is correct: $_PROJECT_ROOT${RST}"
      return 1
    fi
    source "$_f"
  done

  local -a INSTALLED_PKGS=()
  local -a SKIPPED_PKGS=()
  local -a FAILED_PKGS=()

  projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
  local status=$?

  echo ""
  return "$status"
}

# ── --uninstall=<name> ────
_flag_uninstall() {
  local target="$1"
  echo ""
  echo -e "${OPTION} [*] Non-interactive uninstall: ${BOLD_WHITE}${target}${RST}"
  echo ""

  local matched_entry=""
  matched_entry=$(projectr_tool_lookup_entry "$target" 2>/dev/null || true)

  if [ -z "$matched_entry" ]; then
    echo -e "  ${ERROR}[ℹ] No tool named '${target}' found in the list.${RST}"
    echo -e "  ${DIM}Run ${BOLD_WHITE}./main.sh --list=tools${RST}${DIM} to see valid names.${RST}"
    echo ""
    return 1
  fi

  IFS="|" read -r num cmd pkg name desc type extra cat <<<"$matched_entry"
  local tool_id effective_cmd uninstall_manager manager
  projectr_tool_id_into tool_id "$cmd"
  uninstall_manager="${PROJECTR_UNINSTALL_MANAGER_OVERRIDE:-$(projectr_state_lookup_manager "$tool_id" "$pkg")}"
  manager="${uninstall_manager:-${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}}"
  projectr_effective_cmd_into effective_cmd "$tool_id" "$cmd" "$manager"

  if ! command -v "$effective_cmd" >/dev/null 2>&1; then
    echo -e "  ${DIM}[*] ${name} is not installed — nothing to do.${RST}"
    echo ""
    return 0
  fi

  local _required=(
    "$_PROJECT_ROOT/lib/core/spinner.sh"
    "$_PROJECT_ROOT/lib/core/logging.sh"
  )
  for _f in "${_required[@]}"; do
    if [[ ! -f "$_f" ]]; then
      echo -e "  ${ERROR}[ℹ] Required file missing: $_f${RST}"
      echo -e "  ${DIM}Check that \$_PROJECT_ROOT is correct: $_PROJECT_ROOT${RST}"
      return 1
    fi
    source "$_f"
  done

  export NON_INTERACTIVE=1
  projectr_uninstall_tool_by_fields "$cmd" "$pkg" "$name" "$type"
  local status=$?
  unset NON_INTERACTIVE
  echo ""
  return "$status"
}

# Search and install flag
_flag_search() {
  local target="$1"
  echo ""
  echo -e "${OPTION} [*] Search & install: ${BOLD_WHITE}${target}${RST}"
  echo ""

  local _required=(
    "$_PROJECT_ROOT/lib/features/search_install.sh"
    "$_PROJECT_ROOT/lib/core/spinner.sh"
    "$_PROJECT_ROOT/lib/core/logging.sh"
    "$_PROJECT_ROOT/lib/features/installer.sh"
    "$_PROJECT_ROOT/lib/features/post_install.sh"
  )
  for _f in "${_required[@]}"; do
    if [[ ! -f "$_f" ]]; then
      echo -e "  ${ERROR}[ℹ] Required file missing: $_f${RST}"
      echo -e "  ${DIM}Check that \$_PROJECT_ROOT is correct: $_PROJECT_ROOT${RST}"
      return 1
    fi
    source "$_f"
  done

  local -a INSTALLED_PKGS=() SKIPPED_PKGS=() FAILED_PKGS=()
  export NON_INTERACTIVE=1
  search_and_install "$target"
  local status=$?
  unset NON_INTERACTIVE
  echo ""
  return "$status"
}
