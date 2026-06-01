#!/bin/bash
# Plugin tool loader for tools.d/*.toml.
# Supports a tiny TOML subset intentionally: one tool per file with key = "value".

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
            value=$2
            sub(/^[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            gsub(/^"|"$/, "", value)
            print value
            exit
        }
    ' "$file"
}

projectr_load_tool_plugin() {
    local file="$1"
    local cmd pkg name desc type extra cat num

    cmd=$(projectr_toml_value cmd "$file")
    pkg=$(projectr_toml_value pkg "$file")
    name=$(projectr_toml_value name "$file")
    desc=$(projectr_toml_value desc "$file")
    type=$(projectr_toml_value type "$file")
    extra=$(projectr_toml_value extra "$file")
    cat=$(projectr_toml_value category "$file")

    [[ -n "$cmd" && -n "$pkg" && -n "$name" ]] || {
        echo -e "${BOLD_YELLOW:-}[!] Skipping malformed plugin: $file${RST:-}" >&2
        return 0
    }

    desc=${desc:-Plugin-provided tool}
    type=${type:-pkg}
    extra=${extra:--}
    cat=${cat:-Plugin}
    num=$(( ${#TOOLS[@]} + 1 ))
    # Disallow special type in plugins — too dangerous
    if [[ "$type" == "special" ]]; then
       echo -e "${BOLD_YELLOW:-}[!] Plugin '$file': type 'special' not allowed in plugins — defaulting to 'pkg'.${RST:-}" >&2
       type="pkg"
       extra="-"
    fi
    TOOLS+=("$num|$cmd|$pkg|$name|$desc|$type|$extra|$cat")
}
