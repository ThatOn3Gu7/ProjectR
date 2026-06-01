#!/usr/bin/env bash


projectr_uninstall_tool_by_fields() {
    local cmd="$1" pkg="$2" name="$3" type="$4"

    case "$type" in
        pkg|special)
            uninstall_pkg "$cmd" "$pkg" "$name"
            ;;
        pip|pip3|pipx|cargo|gem|npm|yarn)
            uninstall_lang "$type" "$pkg" "$name" "$cmd"
            ;;
        *)
            echo -e "${ERROR} [!] Unsupported tool type for uninstall: ${type}${RST}"
            log_fail "Unsupported tool type '$type' for uninstall of $name" "uninstall"
            return 1
            ;;
    esac
}

projectr_run_uninstall_command() {
    local component="$1" action="$2"
    shift 2
    if declare -f projectr_run_logged >/dev/null 2>&1; then
        projectr_run_logged "$component" "$action" "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

# -- the uninstall function (for pip/npm/gem/etc) --
uninstall_lang() {
    local pm="$1"
    local pkg="$2"
    local name="$3"
    local cmd="${4:-$pkg}"

    if [[ -z "$pm" || -z "$pkg" || -z "$name" ]]; then
        echo -e "${ERROR}  [!] uninstall_lang: missing arguments.${RST}"
        log_error "uninstall_lang missing arguments pm='$pm' pkg='$pkg' name='$name'" "uninstall-lang"
        return 1
    fi

    if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
      if ! ask_confirm "Remove "$name"? (can be reinstalled later)" "n" "Remove" "Keep" "danger" "20" "center"; then
            echo -e "${INFO}  [→] Skipping: $name${RST}"
            log_info "User skipped uninstall for $name" "uninstall"
            return 0
        fi
    fi

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] Package: $name not found (via $pm)${RST}"
        log_warn "$name not found on PATH before language uninstall (cmd=$cmd pm=$pm pkg=$pkg)" "uninstall-lang"
        sleep 2
        return 1
    fi

    start_spinner "   [*] Removing: $name (via $pm).."

    case "$pm" in
        npm)           projectr_run_uninstall_command "uninstall-lang" "remove $name via npm" npm uninstall -g "$pkg" ;;
        yarn)          projectr_run_uninstall_command "uninstall-lang" "remove $name via yarn" yarn global remove "$pkg" ;;
        pnpm)          projectr_run_uninstall_command "uninstall-lang" "remove $name via pnpm" pnpm remove -g "$pkg" ;;
        bun)           projectr_run_uninstall_command "uninstall-lang" "remove $name via bun" bun remove -g "$pkg" ;;
        pip|pip3|pipx) projectr_run_uninstall_command "uninstall-lang" "remove $name via $pm" "$pm" uninstall -y "$pkg" ;;
        gem)           projectr_run_uninstall_command "uninstall-lang" "remove $name via gem" gem uninstall "$pkg" -x ;;
        cargo)         projectr_run_uninstall_command "uninstall-lang" "remove $name via cargo" cargo uninstall "$pkg" ;;
        go)            projectr_run_uninstall_command "uninstall-lang" "remove $name via go" go clean -i "$pkg" && rm -rf "$(go env GOPATH)/bin/$pkg" 2>/dev/null ;;
        composer)      projectr_run_uninstall_command "uninstall-lang" "remove $name via composer" composer global remove "$pkg" ;;
        *)
            stop_spinner
            echo -e "${ERROR} [!] Unsupported language package manager: $pm${RST}"
            log_fail "Unsupported language package manager '$pm' while removing $name" "uninstall-lang"
            return 1
            ;;
    esac

    local exit_code=$?

    # Post-removal verification
    if command -v "$cmd" >/dev/null 2>&1; then
        stop_spinner "${ERROR}  [!] $name still found after removal — may need manual cleanup.${RST}"
        log FAIL "$name (lang): binary still present after $pm removal"
        return 1
    fi

    if [[ $exit_code -eq 0 ]]; then
        stop_spinner "${OPTION}  [✓] Removed: $name successfully (via $pm)${RST}"
        log OK "$name removed successfully via $pm"
    else
        stop_spinner "${ERROR}  [!] $name removal reported errors (exit: $exit_code).${RST}"
        log FAIL "$name uninstall exited $exit_code on $pm"
        return 1
    fi
}
# -- the uninstall function (for apt/etc) --
uninstall_pkg() {
    local cmd="$1"
    local pkg="$2"
    local name="$3"
    local PM
    PM="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

    if [[ -z "$cmd" || -z "$pkg" || -z "$name" ]]; then
        echo -e "${ERROR}  [!] uninstall_pkg: missing arguments.${RST}"
        log_error "uninstall_pkg missing arguments cmd='$cmd' pkg='$pkg' name='$name'" "uninstall-pkg"
        return 1
    fi
    if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
      if ! ask_confirm "Remove "$name"? (can be reinstalled later)" "n" "Remove" "Keep" "danger" "20" "center"; then
            echo -e "${INFO}  [→] Skipping: $name${RST}"
            log_info "User skipped uninstall for $name" "uninstall"
            return 0
        fi
    fi

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] Package: $name not found (on $PM)..${RST}"
        log_warn "$name not found on PATH before package uninstall (cmd=$cmd pm=$PM pkg=$pkg)" "uninstall-pkg"
        sleep 2
        return 1
    fi

    start_spinner "   [*] Removing pkg: $name (via $PM).."

    case "$PM" in
        pkg)         projectr_run_uninstall_command "uninstall-pkg" "remove $name via pkg" pkg uninstall -y "$pkg" ;;
        apt|apt-get) projectr_run_uninstall_command "uninstall-pkg" "purge $name via apt" sudo apt purge -y "$pkg" || projectr_run_uninstall_command "uninstall-pkg" "purge $name via apt-get fallback" sudo apt-get purge -y "$pkg" ;;
        pacman)      projectr_run_uninstall_command "uninstall-pkg" "remove $name via pacman" sudo pacman -Rns --noconfirm "$pkg" ;;
        dnf)         projectr_run_uninstall_command "uninstall-pkg" "remove $name via dnf" sudo dnf remove -y "$pkg" ;;
        yum)         projectr_run_uninstall_command "uninstall-pkg" "remove $name via yum" sudo yum remove -y "$pkg" ;;
        zypper)      projectr_run_uninstall_command "uninstall-pkg" "remove $name via zypper" sudo zypper remove -y "$pkg" ;;
        apk)         projectr_run_uninstall_command "uninstall-pkg" "remove $name via apk" sudo apk del "$pkg" ;;
        emerge)      projectr_run_uninstall_command "uninstall-pkg" "remove $name via emerge" sudo emerge --unmerge "$pkg" ;;
        xbps)        projectr_run_uninstall_command "uninstall-pkg" "remove $name via xbps" sudo xbps-remove -R "$pkg" ;;
        nix)         projectr_run_uninstall_command "uninstall-pkg" "remove $name via nix" nix-env --uninstall "$pkg" && projectr_run_uninstall_command "uninstall-pkg" "collect nix garbage after $name" nix-collect-garbage -d ;;
        guix)        projectr_run_uninstall_command "uninstall-pkg" "remove $name via guix" guix package --remove="$pkg" ;;
        eopkg)       projectr_run_uninstall_command "uninstall-pkg" "remove $name via eopkg" sudo eopkg remove "$pkg" ;;
        urpmi)       projectr_run_uninstall_command "uninstall-pkg" "remove $name via urpmi" sudo urpme "$pkg" ;;
        slackpkg)    projectr_run_uninstall_command "uninstall-pkg" "remove $name via slackpkg" sudo slackpkg remove "$pkg" ;;
        portage)     projectr_run_uninstall_command "uninstall-pkg" "depclean $name via emerge" sudo emerge --depclean "$pkg" ;;
        brew)        projectr_run_uninstall_command "uninstall-pkg" "remove $name via brew" brew uninstall --force "$pkg" ;;
        macports)    projectr_run_uninstall_command "uninstall-pkg" "remove $name via macports" sudo port uninstall "$pkg" ;;
        bsd-pkg)     projectr_run_uninstall_command "uninstall-pkg" "remove $name via FreeBSD pkg" sudo pkg delete -y "$pkg" ;;
        pkg_add)     projectr_run_uninstall_command "uninstall-pkg" "remove $name via pkg_delete" doas pkg_delete "$pkg" ;;
        winget)      projectr_run_uninstall_command "uninstall-pkg" "remove $name via winget" winget uninstall --silent --accept-package-agreements "$pkg" ;;
        choco)       projectr_run_uninstall_command "uninstall-pkg" "remove $name via choco" choco uninstall -y "$pkg" ;;
        scoop)       projectr_run_uninstall_command "uninstall-pkg" "remove $name via scoop" scoop uninstall "$pkg" ;;
        flatpak)     projectr_run_uninstall_command "uninstall-pkg" "remove $name via flatpak" flatpak uninstall -y "$pkg" ;;
        snap)        projectr_run_uninstall_command "uninstall-pkg" "remove $name via snap" sudo snap remove "$pkg" ;;
        appimage)
            stop_spinner
            echo -e "${OPTION} [*] AppImages must be deleted manually.${RST}"
            echo -e "${OPTION} [*] Try: rm ~/Applications/${pkg}.AppImage${RST}"
            return 0
            ;;
        *)
            stop_spinner
            echo -e "${ERROR} [!] Unsupported package manager: $PM${RST}"
            log_fail "Unsupported package manager '$PM' while removing $name" "uninstall-pkg"
            return 1
            ;;
    esac

    local exit_code=$?

    # Post-removal verification: binary should be gone now
    if command -v "$cmd" >/dev/null 2>&1; then
        stop_spinner "${ERROR}  [!] $name still present after removal — may need manual cleanup.${RST}"
        log FAIL "$name: binary still present after $PM removal"
        return 1
    fi

    if [[ $exit_code -eq 0 ]]; then
        stop_spinner "${OPTION}  [✓] Removed: $name successfully (via $PM).${RST}"
        log OK "$name removed successfully via $PM"
    else
        stop_spinner "${ERROR}  [!] $name removal reported errors (exit: $exit_code).${RST}"
        log FAIL "$name uninstall exited $exit_code on $PM"
        return 1
    fi
}
