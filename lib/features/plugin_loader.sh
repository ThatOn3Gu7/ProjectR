#!/bin/bash
# shellcheck disable=all
# Plugin tool loader for tools.d/*.toml.
# Supports a tiny TOML subset intentionally: one tool per file with key = "value".
# Plugins are data, never code: ProjectR does not source plugin files and rejects
# unexpected keys, executable tool types, unsafe paths, and shell metacharacters.

projectr_load_tool_plugins() {
  local plugin_dir="${PROJECTR_TOOLS_DIR:-$SCRIPT_DIR/tools.d}"
  [[ -d "$plugin_dir" ]] || return 0

  local file
  while IFS= read -r file; do
    projectr_load_tool_plugin "$file"
  done < <(find "$plugin_dir" -maxdepth 1 -type f -name '*.toml' | sort)
}

projectr_toml_value() {
  local key="$1" file="$2"
  awk -F '=' -v key="$key" '
        $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            value=$0
            sub(/^[^=]*=/, "", value)
            sub(/^[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            gsub(/^"|"$/, "", value)
            print value
            exit
        }
    ' "$file"
}

projectr_plugin_reject() {
  local file="$1" reason="$2"
  echo -e "${BOLD_YELLOW:-}[ℹ] Skipping plugin '$file': $reason${RST:-}" >&2
  log_warn "Skipping plugin '$file': $reason" "plugin"
  return 1
}

projectr_plugin_validate_key() {
  local key="$1"
  [[ "$key" =~ ^(cmd|pkg|name|desc|type|extra|category|schema_version|min_projectr_version|platforms|homepage|pkg_[A-Za-z0-9_]+|cmd_[A-Za-z0-9_]+)$ ]]
}

projectr_plugin_validate_file() {
  local file="$1" plugin_dir="${PROJECTR_TOOLS_DIR:-$SCRIPT_DIR/tools.d}"
  [[ -f "$file" ]] || projectr_plugin_reject "$file" "not a regular file" || return 1
  [[ -r "$file" ]] || projectr_plugin_reject "$file" "not readable" || return 1

  local real_file real_dir
  real_file=$(cd "$(dirname "$file")" 2>/dev/null && pwd -P)/$(basename "$file") || return 1
  real_dir=$(cd "$plugin_dir" 2>/dev/null && pwd -P) || return 1
  case "$real_file" in
  "$real_dir"/*.toml) ;;
  *)
    projectr_plugin_reject "$file" "outside configured plugin directory"
    return 1
    ;;
  esac

  local bad_key
  bad_key=$(awk -F '=' '
        /^[[:space:]]*($|#|\[)/ { next }
        NF < 2 { print "<syntax>"; exit }
        {
            key=$1
            sub(/^[[:space:]]*/, "", key)
            sub(/[[:space:]]*$/, "", key)
            print key
        }
    ' "$file" | while IFS= read -r key; do
    [[ "$key" =~ ^(cmd|pkg|name|desc|type|extra|category|schema_version|min_projectr_version|platforms|homepage|pkg_[A-Za-z0-9_]+|cmd_[A-Za-z0-9_]+)$ ]] || {
      echo "$key"
      break
    }
  done)
  [[ -z "$bad_key" ]] || {
    projectr_plugin_reject "$file" "unsupported key '$bad_key'"
    return 1
  }
}

projectr_plugin_safe_text() {
  local value="$1"
  [[ "$value" != *$'\n'* ]] || return 1
  [[ "$value" != *$'\r'* ]] || return 1
  [[ "$value" != *'`'* && "$value" != *'$('* && "$value" != *';'* && "$value" != *'|'* && "$value" != *'&'* ]] || return 1
}

projectr_plugin_safe_token() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9._@+:/=-]+$ ]]
}

projectr_plugin_supported_platform() {
  local platforms="$1"
  [[ -z "$platforms" ]] && return 0
  local os
  os=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')
  case ",$platforms," in
  *,all,* | *,$os,*) return 0 ;;
  *) return 1 ;;
  esac
}

projectr_load_tool_plugin() {
  local file="$1"
  local cmd pkg name desc type extra cat num schema_version min_version platforms homepage
  local line key value manager

  projectr_plugin_validate_file "$file" || return 0

  cmd=$(projectr_toml_value cmd "$file")
  pkg=$(projectr_toml_value pkg "$file")
  name=$(projectr_toml_value name "$file")
  desc=$(projectr_toml_value desc "$file")
  type=$(projectr_toml_value type "$file")
  extra=$(projectr_toml_value extra "$file")
  cat=$(projectr_toml_value category "$file")
  schema_version=$(projectr_toml_value schema_version "$file")
  min_version=$(projectr_toml_value min_projectr_version "$file")
  platforms=$(projectr_toml_value platforms "$file")
  homepage=$(projectr_toml_value homepage "$file")

  [[ -n "$cmd" && -n "$pkg" && -n "$name" ]] || {
    projectr_plugin_reject "$file" "missing required cmd/pkg/name"
    return 0
  }

  [[ -z "$schema_version" || "$schema_version" == "1" ]] || {
    projectr_plugin_reject "$file" "unsupported schema_version '$schema_version'"
    return 0
  }
  [[ -z "$min_version" || "$min_version" == "1.4" ]] || {
    projectr_plugin_reject "$file" "requires ProjectR version '$min_version'"
    return 0
  }
  projectr_plugin_supported_platform "$platforms" || {
    log_info "Skipping plugin '$file' because it does not target this platform ($platforms)" "plugin"
    return 0
  }

  projectr_plugin_safe_token "$cmd" || {
    projectr_plugin_reject "$file" "unsafe cmd token"
    return 0
  }
  projectr_plugin_safe_token "$pkg" || {
    projectr_plugin_reject "$file" "unsafe pkg token"
    return 0
  }
  projectr_plugin_safe_text "$name" || {
    projectr_plugin_reject "$file" "unsafe name"
    return 0
  }
  projectr_plugin_safe_text "$desc" || {
    projectr_plugin_reject "$file" "unsafe desc"
    return 0
  }
  projectr_plugin_safe_text "$cat" || {
    projectr_plugin_reject "$file" "unsafe category"
    return 0
  }
  projectr_plugin_safe_text "$homepage" || {
    projectr_plugin_reject "$file" "unsafe homepage"
    return 0
  }

  desc=${desc:-Plugin-provided tool}
  type=${type:-pkg}
  extra=${extra:--}
  cat=${cat:-Plugin}

  case "$type" in
  pkg | pip | pip3 | pipx | cargo | gem | npm | yarn | pnpm | bun | go | composer) ;;
  special)
    projectr_plugin_reject "$file" "type 'special' is not allowed in plugins" || true
    return 0
    ;;
  *)
    projectr_plugin_reject "$file" "unsupported plugin type '$type'" || true
    return 0
    ;;
  esac
  [[ "$extra" == "-" || -z "$extra" ]] || {
    projectr_plugin_reject "$file" "extra hooks are disabled for plugins"
    return 0
  }
  extra="-"

  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    key=$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    value=$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//')
    case "$key" in
    pkg_*)
      manager="${key#pkg_}"
      projectr_plugin_safe_token "$value" || {
        projectr_plugin_reject "$file" "unsafe package override for $manager"
        return 0
      }
      PROJECTR_TOOL_PKG_OVERRIDES["$cmd:${manager//_/-}"]="$value"
      ;;
    cmd_*)
      manager="${key#cmd_}"
      projectr_plugin_safe_token "$value" || {
        projectr_plugin_reject "$file" "unsafe command override for $manager"
        return 0
      }
      PROJECTR_TOOL_CMD_OVERRIDES["$cmd:${manager//_/-}"]="$value"
      ;;
    esac
  done <"$file"

  num=$((${#TOOLS[@]} + 1))
  TOOLS+=("$num|$cmd|$pkg|$name|$desc|$type|$extra|$cat")
  declare -f projectr_tools_index_invalidate >/dev/null 2>&1 && projectr_tools_index_invalidate
  log_info "Loaded tool plugin '$name' from $file as #$num type=$type homepage=${homepage:-n/a}" "plugin"
}
