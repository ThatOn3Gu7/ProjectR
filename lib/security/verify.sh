#!/usr/bin/env bash
# Light-weight trust helpers for update/bootstrap paths.

PROJECTR_TRUSTED_REPO_REGEX="${PROJECTR_TRUSTED_REPO_REGEX:-^(https://github\.com/Thaton3gu7/ProjectR(\.git)?|git@github\.com:Thaton3gu7/ProjectR(\.git)?)$}"

projectr_verify_sha256_file() {
    local expected="$1" file="$2" actual
    command -v sha256sum >/dev/null 2>&1 || return 2
    actual=$(sha256sum "$file" | awk '{print $1}') || return 1
    [[ "$actual" == "$expected" ]]
}

projectr_verify_repo_url() {
    local url="$1"
    [[ "${PROJECTR_ALLOW_ANY_REMOTE:-0}" == "1" ]] && return 0
    [[ "$url" =~ $PROJECTR_TRUSTED_REPO_REGEX ]]
}

projectr_require_trusted_repo() {
    local url="$1" context="${2:-update}"
    if ! projectr_verify_repo_url "$url"; then
        echo -e "${ERROR:-}[!] Refusing $context from untrusted repository: $url${RST:-}" >&2
        echo -e "${INFO:-}[*] Set PROJECTR_ALLOW_ANY_REMOTE=1 to override if you trust this remote.${RST:-}" >&2
        return 1
    fi
    return 0
}
