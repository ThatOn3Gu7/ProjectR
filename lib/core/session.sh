#!/usr/bin/env bash
# Session/bootstrap helpers so interactive and CLI flows share the same lock,
# transaction id, and logging envelope.

PROJECTR_LOCK_FD="${PROJECTR_LOCK_FD:-9}"
PROJECTR_LOCK_FILE="${PROJECTR_LOCK_FILE:-${HOME}/.config/projectr_v2/tmp/project.lock}"
PROJECTR_RUNTIME_PREPARED="${PROJECTR_RUNTIME_PREPARED:-0}"
PROJECTR_READ_ONLY_ACTION="${PROJECTR_READ_ONLY_ACTION:-0}"
PROJECTR_NEEDS_NETWORK="${PROJECTR_NEEDS_NETWORK:-0}"

projectr_cli_primary_arg() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --no-color|--quiet) continue ;;
            *) printf '%s\n' "$arg"; return 0 ;;
        esac
    done
    return 1
}

projectr_classify_cli_action() {
    local primary
    primary=$(projectr_cli_primary_arg "$@") || { PROJECTR_READ_ONLY_ACTION=0; PROJECTR_NEEDS_NETWORK=0; return 0; }
    case "$primary" in
        --help|-h|help|--version|-v|version|list|--list|log|--log|doctor|--doctor|audit|--audit|verify|--verify|diff|--diff-profile|profile-diff|completions|--completions)
            PROJECTR_READ_ONLY_ACTION=1
            PROJECTR_NEEDS_NETWORK=0
            ;;
        dry-run|--dry-run)
            PROJECTR_READ_ONLY_ACTION=1
            PROJECTR_NEEDS_NETWORK=0
            ;;
        export|--export|export-lock|--export-lock)
            PROJECTR_READ_ONLY_ACTION=1
            PROJECTR_NEEDS_NETWORK=0
            ;;
        install|--install|search|--search|import|--import|update|--update|self-update|--self-update|projectr-update|--projectr-update|upgrade|--upgrade|repair|--repair|reset|--reset|scheduler|--scheduler)
            PROJECTR_READ_ONLY_ACTION=0
            PROJECTR_NEEDS_NETWORK=1
            ;;
        uninstall|--uninstall|undo|--undo)
            PROJECTR_READ_ONLY_ACTION=0
            PROJECTR_NEEDS_NETWORK=0
            ;;
        *)
            PROJECTR_READ_ONLY_ACTION=0
            PROJECTR_NEEDS_NETWORK=0
            ;;
    esac
    export PROJECTR_READ_ONLY_ACTION PROJECTR_NEEDS_NETWORK
}

projectr_transaction_id() {
    if [[ -z "${PROJECTR_TRANSACTION_ID:-}" ]]; then
        PROJECTR_TRANSACTION_ID="${PROJECTR_SESSION_ID:-$(date '+%Y%m%d-%H%M%S')-$$}"
        export PROJECTR_TRANSACTION_ID
    fi
    printf '%s\n' "$PROJECTR_TRANSACTION_ID"
}

projectr_prepare_lock_dir() {
    mkdir -p "$(dirname "$PROJECTR_LOCK_FILE")" || return 1
}

projectr_acquire_lock() {
    [[ "${PROJECTR_LOCK_ACQUIRED:-0}" == "1" ]] && return 0
    projectr_prepare_lock_dir || return 1
    eval "exec ${PROJECTR_LOCK_FD}>\"$PROJECTR_LOCK_FILE\""
    flock -n "$PROJECTR_LOCK_FD" || return 1
    PROJECTR_LOCK_ACQUIRED=1
    export PROJECTR_LOCK_ACQUIRED
}

projectr_runtime_prepare() {
    [[ "${PROJECTR_RUNTIME_PREPARED:-0}" == "1" ]] && return 0

    projectr_classify_cli_action "$@"
    if ! projectr_acquire_lock; then
        echo -e "${ERROR:-}[!] ProjectR is already running in another session.${RST:-}"
        declare -f log_warn >/dev/null 2>&1 && log_warn "Lock acquisition failed for $PROJECTR_LOCK_FILE" "startup"
        return 1
    fi

    projectr_transaction_id >/dev/null
    PROJECTR_RUNTIME_PREPARED=1
    export PROJECTR_RUNTIME_PREPARED

    declare -f log >/dev/null 2>&1 && log START "━━━━━━ Session started at: $(date '+%Y-%m-%d %H:%M') ━━━━━━" "startup"
    declare -f projectr_log_environment >/dev/null 2>&1 && projectr_log_environment

    # Only run heavyweight or interactive checks when they make sense.
    if [[ $# -eq 0 ]]; then
        declare -f verify_dependencies >/dev/null 2>&1 && verify_dependencies || true
        declare -f check_startup_connectivity >/dev/null 2>&1 && check_startup_connectivity || true
    elif [[ "${PROJECTR_NEEDS_NETWORK:-0}" == "1" ]]; then
        if declare -f check_internet >/dev/null 2>&1 && ! check_internet; then
            echo -e "${ERROR:-}[!] Network access looks unavailable for this operation.${RST:-}"
            declare -f log_warn >/dev/null 2>&1 && log_warn "Network unavailable during CLI preflight: $*" "startup"
            return 1
        fi
    fi
    return 0
}
