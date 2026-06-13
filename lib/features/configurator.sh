#!/usr/bin/env bash
# shellcheck disable=all
# Declarative post-install configuration bridge for profiles.

projectr_profile_settings() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  case "$file" in
  *.yml | *.yaml)
    awk '
         /^[[:space:]]*settings:[[:space:]]*$/ { in_settings=1; next }
         in_settings && /^[^[:space:]]/ { in_settings=0 }
         in_settings && /^[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*:/ {
             key=$1
             sub(/:.*/, "", key)
             val=$0
             sub(/^[^:]*:[[:space:]]*/, "", val)
             gsub(/["\047]/, "", val)
             print key "=" val
         }
     ' "$file"
    ;;
  *.toml)
    awk '
        /^[[:space:]]*\[settings\][[:space:]]*$/ { in_settings=1; next }
        in_settings && /^[[:space:]]*\[/ { in_settings=0 }
        in_settings && /^[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*=/ {
            key=$1
            val=$0
            sub(/^[^=]*=[[:space:]]*/, "", val)
            gsub(/["\047]/, "", val)
            print key "=" val
        }
    ' "$file"
    ;;
  *) return 1 ;;
  esac
}

projectr_profile_export_settings() {
  local file="$1" kv key val
  while IFS= read -r kv; do
    [[ -n "$kv" ]] || continue
    key="${kv%%=*}"
    val="${kv#*=}"
    case "$key" in
    nvim_config) export PROJECTR_NVIM_CONFIG="$val" ;;
    zsh_oh_my_zsh) export PROJECTR_ZSH_INSTALL_OMZ="$val" ;;
    zsh_theme) export PROJECTR_ZSH_THEME="$val" ;;
    zsh_powerlevel10k) export PROJECTR_ZSH_INSTALL_P10K="$val" ;;
    esac
  done < <(projectr_profile_settings "$file")
}
