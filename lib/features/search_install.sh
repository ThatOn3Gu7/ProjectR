#!/bin/bash
# "Install by name" — checks TOOLS array first, then does smart multi-manager scan

# ── Name normalisation maps ──
# pkg: what to pass to the package manager
# bin: what binary to check for after install
declare -A SI_PKG_MAP=(
    [nvim]="neovim"      [vim]="vim"          [fd]="fd-find"
    [bat]="bat"          [rg]="ripgrep"       [fzf]="fzf"
    [python]="python3"   [node]="nodejs"      [pip]="python3-pip"
    [lazygit]="lazygit"  [lf]="lf"            [delta]="git-delta"
    [procs]="procs"      [dust]="dust"        [bottom]="bottom"
)
declare -A SI_BIN_MAP=(
    [neovim]="nvim"      [fd-find]="fd"       [ripgrep]="rg"
    [nodejs]="node"      [python3]="python3"  [git-delta]="delta"
)

# Manager priority — lower number = preferred
declare -A SI_TIER=(
    [apt]=1   [apt-get]=1  [pacman]=1 [dnf]=1   [yum]=1    [zypper]=1
    [apk]=1   [emerge]=1   [xbps]=1   [nix]=1   [brew]=1   [port]=1
    [pkg]=1   [pkg_add]=1  [winget]=1 [choco]=1 [scoop]=1
    [pipx]=2  [flatpak]=2  [snap]=2
    [cargo]=3 [npm]=3      [yarn]=3   [pip]=3   [pip3]=3   [gem]=3
)

# ── Helpers ───

# Resolve user input → pkg name + binary name
_si_normalize() {
    local input="${1,,}"
    local pkg="${SI_PKG_MAP[$input]:-$input}"
    local bin="${SI_BIN_MAP[$pkg]:-${SI_BIN_MAP[$input]:-$input}}"
    echo "$pkg|$bin"
}

# Check if a package exists in a given manager (fast, no install)
_si_check_avail() {
    local pkg="$1" mgr="$2"
    # Wrap every check in an 8-second timeout to prevent hangs on slow mirrors
    local t=""
    command -v timeout >/dev/null 2>&1 && t="timeout 8"

    case "$mgr" in
        apt|apt-get)   $t apt-cache show "$pkg" >/dev/null 2>&1 ;;
        pacman)        $t pacman -Ss "^${pkg}$" >/dev/null 2>&1 ;;
        dnf|yum)       $t $mgr info "$pkg" >/dev/null 2>&1 ;;
        brew)          $t brew info "$pkg" >/dev/null 2>&1 ;;
        pkg)           $t pkg show "$pkg" >/dev/null 2>&1 ;;
        npm)           $t npm info "$pkg" >/dev/null 2>&1 ;;
        pip|pip3)
                $t $mgr index versions "$pkg" >/dev/null 2>&1 \
          || $t $mgr install --dry-run "$pkg" >/dev/null 2>&1 ;;
        pipx)
                 $t pip index versions "$pkg" >/dev/null 2>&1 \
           || $t pip install --dry-run "$pkg" >/dev/null 2>&1 ;;
        gem)           $t gem list -r "^${pkg}$" >/dev/null 2>&1 ;;
        cargo)         $t cargo search --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg " ;;
        *)             return 0 ;;
    esac
}

# Search TOOLS array by cmd / pkg / display-name (case-insensitive)
_si_find_in_tools() {
    local query="${1,,}"
    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        if [[ "${cmd,,}" == "$query" || "${pkg,,}" == "$query" || "${name,,}" == "$query" ]]; then
            echo "$entry"
            return 0
        fi
    done
    return 1
}

# ── Core: install one tool by name ───
search_and_install() {
    local input="$1"
    echo ""

    # ── Path A: tool is in our TOOLS list ───
    local matched
    matched=$(_si_find_in_tools "$input")
    if [ -n "$matched" ]; then
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$matched"
        echo -e "${OPTION}  [✓] Found in tool list: ${BOLD_WHITE}$name${RST} ${DIM}(#$num – $cat)${RST}"
        sleep 2
        echo ""

        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${OPTION}  [✓] $name is already installed — nothing to do.${RST}"
            SKIPPED_PKGS+=("$name")
            sleep 2; return 0
        fi

        projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
        return
    fi

    # ── Path B: unknown tool — smart multi-manager scan ───
    local norm; norm=$(_si_normalize "$input")
    local pkg="${norm%|*}"
    local binary="${norm#*|}"

    echo -e "${INFO}  [*] '${BOLD_WHITE}$input${RST}${INFO}' not in tool list — scanning package managers...${RST}"
    echo -e "${DIM}      (looking for pkg: $pkg, binary: $binary)${RST}"
    echo ""

    if command -v "$binary" >/dev/null 2>&1; then
        echo -e "${OPTION}  [✓] '$binary' is already installed — nothing to do.${RST}"
        SKIPPED_PKGS+=("$input")
        sleep 2; return 0
    fi

    # Build candidate list: system PM first, then language managers
    local sys_pm; sys_pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    local candidates=()
    [ -n "$sys_pm" ] && candidates+=("$sys_pm")
    for lm in cargo npm pip pip3 gem pipx; do
        command -v "$lm" >/dev/null 2>&1 && candidates+=("$lm")
    done

    # Deduplicate
    local unique=()
    for m in "${candidates[@]}"; do
        [[ " ${unique[*]} " == *" $m "* ]] || unique+=("$m")
    done
    # Scan each manager — _si_check_avail has an 8s timeout per call
    local available=()
    local total_mgrs=${#unique[@]}
    local mgr_idx=0

    for mgr in "${unique[@]}"; do
        ((mgr_idx++))
        printf "    ${DIM}[%d/%d]${RST} Checking ${BOLD_WHITE}%s${RST}..." \
               "$mgr_idx" "$total_mgrs" "$mgr"
        if _si_check_avail "$pkg" "$mgr"; then
            local tier="${SI_TIER[$mgr]:-3}"
            printf " ${OPTION}[✓]${RST} ${DIM}(tier %d)${RST}\n" "$tier"
            available+=("$mgr")
        else
            printf " ${ERROR}[✗]${RST}\n"
        fi
    done

    if [ ${#available[@]} -eq 0 ]; then
        echo ""
        echo -e "${ERROR}  [✗] No package manager has '${BOLD_WHITE}$pkg${RST}${ERROR}' available.${RST}"
        echo -e "${INFO}  [*] Check manually: https://repology.org/project/$pkg/versions${RST}"
        FAILED_PKGS+=("$input")
        sleep 3; return 1
    fi

    # If multiple managers have it, let the user pick
    local chosen="${available[0]}"
    if [ ${#available[@]} -gt 1 ]; then
        echo ""
        echo -e "${INFO}  [?] Multiple sources found — choose one:${RST}"
        echo ""
        local i=1
        for mgr in "${available[@]}"; do
            local tier="${SI_TIER[$mgr]:-3}"
            local tier_name
            case "$tier" in 1) tier_name="native" ;; 2) tier_name="isolated" ;; *) tier_name="language" ;; esac
            echo -e "    ${OPTION}[$i]${RST} ${BOLD_WHITE}$mgr${RST} ${DIM}(tier $tier – $tier_name)${RST}"
            ((i++))
        done
        echo ""
        echo -ne "  ${BRIGHT_MAGENTA}[*] Choose [1-${#available[@]}]: ${RST}"
        read -r pick
        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#available[@]} )); then
            chosen="${available[$((pick-1))]}"
        else
            echo -e "${INFO}  [*] Invalid input — defaulting to: ${BOLD_WHITE}$chosen${RST}"
        fi
    fi

    echo ""
    log INSTALL "search_and_install: '$input' → pkg='$pkg' via '$chosen'"

    # Route to your existing install functions
    case "$chosen" in
        pip|pip3|pipx) install_lang "pip"   "$pkg" "$input" "$binary" ;;
        npm|yarn)      install_lang "npm"   "$pkg" "$input" "$binary" ;;
        gem)           install_lang "gem"   "$pkg" "$input" "$binary" ;;
        cargo)         install_lang "cargo" "$pkg" "$input" "$binary" ;;
        *)             install_pkg "$binary" "$pkg" "$input" ;;
    esac
}

# ── Interactive menu ───
install_by_name_menu() {
    while true; do
        clear
        log ENTER "User entered sub-menu 'search-install'"
        echo -e "${OPTION}"
        print_titled_box --align center \
            " [ Install by Name ] " \
            "● Checks the built-in tool list first" \
            "● Falls back to scanning ALL available package managers" \
            "● Type '/' to open interactive Fuzzy Search"
        echo -e "${RST}"
        echo ""
        echo -e "${INFO}  [*] Examples: ${DIM}git, neovim, ripgrep, holehe, lazygit${RST}"
        echo -e "${ERROR}  [b] Back to main menu${RST}"
        echo ""
        # Updated prompt to remind users about the '/' hotkey
        echo -ne " ${BG_GREEN}[*] Tool name(s) or '/' to search: ${RST} "
        read -ra inputs

        [[ ${#inputs[@]} -eq 0 ]] && continue
        [[ "${inputs[0],,}" == "b" ]] && { log LEFT "User exited sub-menu 'search-install'"; return; }

        # --- IMPLEMENTING YOUR FUZZY SEARCH TRIGGER ---
        if [[ "${inputs[0]}" == "/" ]]; then
            interactive_fuzzy_search
            # Refresh the screen after fzf closes and restart the loop
            echo -e "${OPTION}"
            read -p " [*] Press ENTER to continue..."
            echo -e "${RST}"
            continue 
        fi
        
        # Reset summary arrays
        INSTALLED_PKGS=()
        SKIPPED_PKGS=()
        FAILED_PKGS=()

        for tool in "${inputs[@]}"; do
            [[ -z "$tool" ]] && continue
            search_and_install "$tool"
            echo ""
        done

        # Show summary for multi-tool runs
        if (( ${#inputs[@]} > 1 )); then
            post_install_summary
        fi

        echo -e "${OPTION}"
        read -p " [*] Press ENTER to continue..."
        echo -e "${RST}"
        echo -e "${OPTION}"
        ask " [*] Install another tool?" "n" && continue || return
        echo -e "${RST}"
    done
}

# Append to: lib/features/search_install.sh
interactive_fuzzy_search() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo ""
        echo -e "${ERROR} [✗] fzf is not installed. Install it first (option 22 from the menu).${RST}"
        return 1
    fi

    local selected
    selected=$(
        for entry in "${TOOLS[@]}"; do
            IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
            # Format: raw_cmd|display line  — delimiter kept clean for parsing
            printf "%s|[%s] %s\n" "$name" "$cat" "$desc"
        done | fzf \
            --prompt="🔍 Search tools (Tab=multi, Enter=confirm): " \
            --multi \
            --height=60% \
            --delimiter="|" \
            --with-nth=2
    )

    if [[ -z "$selected" ]]; then
        echo ""
        echo -e "${INFO}  [*] No tools selected.${RST}"
        return 0
    fi

    local tools_to_install=()
    while IFS= read -r line; do
        # First field before '|' is the raw cmd — no padding since we use printf %s not %-15s
        local clean_cmd="${line%%|*}"
        [[ -n "$clean_cmd" ]] && tools_to_install+=("$clean_cmd")
    done <<< "$selected"

    INSTALLED_PKGS=(); SKIPPED_PKGS=(); FAILED_PKGS=()
    for tool in "${tools_to_install[@]}"; do
        search_and_install "$tool"
        echo ""
    done

    [[ ${#tools_to_install[@]} -gt 1 ]] && post_install_summary
}
