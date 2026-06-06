#!/bin/bash
# "Install by name" — checks TOOLS array first, then does smart multi-manager scan

# ── Name normalisation maps ──
declare -A SI_PKG_MAP=(
    [git]="git"      [curl]="curl"        [wget]="wget"
    [bat]="bat"      [htop]="htop"        [fish]="fish"
    [ssh]="openssh"  [python3]="python3"  [nmap]="nmap"
    [cacafire]="libcaca"      [speedtest-go]="speedtest-go"
    [cpufetch]="cpufetch"     [neofetch]="neofetch"
    [ranger]="ranger"         [nano]="nano"          [sl]="sl"
    [ncdu]="ncdu"             [nvim]="neovim"        [cbonsai]="cbonsai"
    [asciinema]="asciinema"   [croc]="croc"          [fzf]="fzf"
    [zoxide]="zoxide"         [zsh]="zsh"            [duf]="duf"
    [tty-clock]="tty-clock"   [pipes.sh]="pipes.sh"  [yazi]="yazi"
    [lsd]="lsd"               [broot]="broot"        [dust]="dust"
    [procs]="procs"           [tldr]="tldr"          [npm]="nodejs"
    [gh]="gh"                 [holehe]="holehe"      [asciiquarium]="asciiquarium"
    [wttr]="wttr"             [tmux]="tmux"          [lazygit]="lazygit"
    [ani-cli]="ani-cli"       [code-server]="code-server"  [pipx]="pipx"
    [jq]="jq"                 [yq]="yq"              [rg]="ripgrep"
    [fd]="fd-find"            [sd]="sd"              [hyperfine]="hyperfine"
    [starship]="starship"     [eza]="eza"            [tree]="tree"
    [rsync]="rsync"           [rclone]="rclone"      [restic]="restic"
    [borg]="borgbackup"       [age]="age"            [gpg]="gnupg"
    [pass]="pass"             [openssl]="openssl"    [openssl-tool]="openssl-tool"
    [mosh]="mosh"             [autossh]="autossh"    [socat]="socat"
    [netcat]="netcat"         [tcpdump]="tcpdump"    [wireshark]="wireshark"
    [traceroute]="traceroute" [mtr]="mtr"            [iperf3]="iperf3"
    [whois]="whois"           [dnsutils]="dnsutils"  [dog]="dog"
    [httpie]="httpie"         [xh]="xh"              [aria2c]="aria2"
    [yt-dlp]="yt-dlp"         [ffmpeg]="ffmpeg"      [imagemagick]="imagemagick"
    [chafa]="chafa"           [jp2]="jp2"            [figlet]="figlet"
    [toilet]="toilet"         [lolcat]="lolcat"      [cmatrix]="cmatrix"
    [nyancat]="nyancat"       [fortune]="fortune"    [cowsay]="cowsay"
    [rig]="rig"               [moon-buggy]="moon-buggy"  [nethack]="nethack"
    [2048]="2048"             [vitetris]="vitetris"  [micro]="micro"
    [vim]="vim"               [emacs]="emacs"        [helix]="helix"
    [kak]="kakoune"           [joe]="joe"            [mc]="mc"
    [nnn]="nnn"               [lf]="lf"              [joshuto]="joshuto"
    [trash-put]="trash-cli"   [rename]="rename"      [entr]="entr"
    [watchexec]="watchexec"   [direnv]="direnv"      [make]="make"
    [cmake]="cmake"           [ninja]="ninja-build"  [gcc]="gcc"
    [clang]="clang"           [gdb]="gdb"            [lldb]="lldb"
    [strace]="strace"         [ltrace]="ltrace"      [valgrind]="valgrind"
    [shellcheck]="shellcheck" [shfmt]="shfmt"        [bats]="bats"
    [just]="just"             [task]="task"          [go]="golang"
    [rustup]="rustup"         [cargo]="cargo"        [lua]="lua"
    [luarocks]="luarocks"     [ruby]="ruby"          [gem]="ruby"
    [perl]="perl"             [php]="php"            [composer]="composer"
    [java]="openjdk"          [mvn]="maven"          [gradle]="gradle"
    [deno]="deno"             [bun]="bun"            [pnpm]="pnpm"
    [yarn]="yarn"             [typescript]="typescript"  [eslint]="eslint"
    [prettier]="prettier"     [nodemon]="nodemon"    [serve]="serve"
    [http-server]="http-server"  [vercel]="vercel"   [netlify]="netlify-cli"
    [aws]="awscli"            [az]="azure-cli"       [gcloud]="google-cloud-cli"
    [terraform]="terraform"   [ansible]="ansible"    [vagrant]="vagrant"
    [docker]="docker"         [docker-compose]="docker-compose"  [podman]="podman"
    [buildah]="buildah"       [skopeo]="skopeo"      [kubectl]="kubectl"
    [helm]="helm"             [k9s]="k9s"            [minikube]="minikube"
    [kind]="kind"             [postgres]="postgresql"  [psql]="postgresql-client"
    [mysql]="mysql"           [mariadb]="mariadb"    [sqlite3]="sqlite"
    [redis-server]="redis"    [mongosh]="mongodb-mongosh"  [pgcli]="pgcli"
    [mycli]="mycli"           [litecli]="litecli"    [csvkit]="csvkit"
    [visidata]="visidata"     [duckdb]="duckdb"      [gnuplot]="gnuplot"
    [pandoc]="pandoc"         [tectonic]="tectonic"  [latexmk]="latexmk"
    [mdbook]="mdbook"         [hugo]="hugo"          [jekyll]="jekyll"
    [mkdocs]="mkdocs"         [glow]="glow"          [slides]="slides"
    [lynx]="lynx"             [w3m]="w3m"            [elinks]="elinks"
    [newsboat]="newsboat"     [weechat]="weechat"    [irssi]="irssi"
    [mutt]="mutt"             [msmtp]="msmtp"        [neomutt]="neomutt"
    [btop]="btop"             [glances]="glances"    [atop]="atop"
    [iotop]="iotop"           [iftop]="iftop"        [nethogs]="nethogs"
    [powertop]="powertop"     [sysstat]="sysstat"    [dstat]="dstat"
    [smartctl]="smartmontools"  [testdisk]="testdisk"  [photorec]="testdisk"
    [rkhunter]="rkhunter"     [lynis]="lynis"        [ufw]="ufw"
    [fail2ban-client]="fail2ban"  [john]="john"       [hashcat]="hashcat"
    [hydra]="hydra"           [sqlmap]="sqlmap"      [nikto]="nikto"
    [gobuster]="gobuster"     [ffuf]="ffuf"          [zap-baseline.py]="zaproxy"
    [amass]="amass"           [theHarvester]="theharvester"  [sherlock]="sherlock-project"
    [maigret]="maigret"       [subfinder]="subfinder"  [assetfinder]="assetfinder"
    [waybackurls]="waybackurls"  [exiftool]="exiftool"  [binwalk]="binwalk"
    [radare2]="radare2"       [ghidra]="ghidra"      [apktool]="apktool"
    [adb]="android-tools"     [scrcpy]="scrcpy"      [termux-api-start]="termux-api"
    [ollama]="ollama"         [mods]="mods"          [aichat]="aichat"
    [tgpt]="tgpt"             [fabric]="fabric-ai"
)
declare -A SI_BIN_MAP=(
    [openssh]="ssh"           [libcaca]="cacafire"
    [neovim]="nvim"           [nodejs]="npm"         [ripgrep]="rg"
    [fd-find]="fd"            [borgbackup]="borg"    [gnupg]="gpg"
    [aria2]="aria2c"          [kakoune]="kak"        [trash-cli]="trash-put"
    [ninja-build]="ninja"     [golang]="go"          [ruby]="gem"
    [openjdk]="java"          [maven]="mvn"          [netlify-cli]="netlify"
    [awscli]="aws"            [azure-cli]="az"       [google-cloud-cli]="gcloud"
    [postgresql]="postgres"   [postgresql-client]="psql"  [sqlite]="sqlite3"
    [redis]="redis-server"    [mongodb-mongosh]="mongosh"
    [smartmontools]="smartctl"  [testdisk]="photorec"
    [fail2ban]="fail2ban-client"  [zaproxy]="zap-baseline.py"
    [theharvester]="theHarvester"  [sherlock-project]="sherlock"
    [android-tools]="adb"     [termux-api]="termux-api-start"
    [fabric-ai]="fabric"
)

declare -A SI_TIER=(
    [apt]=1   [apt-get]=1  [pacman]=1 [dnf]=1   [yum]=1    [zypper]=1
    [apk]=1   [emerge]=1   [xbps]=1   [nix]=1   [brew]=1   [port]=1
    [pkg]=1   [pkg_add]=1  [winget]=1 [choco]=1 [scoop]=1
    [pipx]=2  [flatpak]=2  [snap]=2
    [cargo]=3 [npm]=3      [yarn]=3   [pip]=3   [pip3]=3   [gem]=3
)

# ── Helpers ───

_si_normalize() {
    local input="${1,,}"
    local pkg="${SI_PKG_MAP[$input]:-$input}"
    local bin="${SI_BIN_MAP[$pkg]:-${SI_BIN_MAP[$input]:-$input}}"
    echo "$pkg|$bin"
}

_si_check_avail() {
    local pkg="$1" mgr="$2"
    local t=""
    command -v timeout >/dev/null 2>&1 && t="timeout 8"

    case "$mgr" in
        apt|apt-get)   $t apt-cache show "$pkg" >/dev/null 2>&1 ;;
        pacman)        $t pacman -Ss "^${pkg}$" >/dev/null 2>&1 ;;
        dnf|yum)       $t $mgr info "$pkg" >/dev/null 2>&1 ;;
        brew)          $t brew info "$pkg" >/dev/null 2>&1 ;;
        pkg)           $t pkg show "$pkg" >/dev/null 2>&1 ;;
        npm)           $t npm info "$pkg" >/dev/null 2>&1 ;;
        yarn)          $t yarn info "$pkg" >/dev/null 2>&1 ;;
        pnpm)          $t pnpm view "$pkg" version >/dev/null 2>&1 ;;
        bun)           $t bun pm view "$pkg" version >/dev/null 2>&1 ;;
        pip|pip3)      $t $mgr index versions "$pkg" >/dev/null 2>&1 \
        || $t $mgr install --dry-run "$pkg" >/dev/null 2>&1 ;;
        pipx)          $t pip index versions "$pkg" >/dev/null 2>&1 \
        || $t pip install --dry-run "$pkg" >/dev/null 2>&1 ;;
        gem)           $t gem list -r "^${pkg}$" >/dev/null 2>&1 ;;
        cargo)         $t cargo search --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg " ;;
        *)             return 0 ;;
    esac
}

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

# ── Cross-platform typo suggestions ─────────────────────────────────────────
# Tries: command-not-found → PM searches → fuzzy fallback via TOOLS array
# Returns: space-separated list of suggestions
_si_get_suggestions() {
    local input="$1"
    local suggestions=""
    local t=""
    command -v timeout >/dev/null 2>&1 && t="timeout 5"

    # 1. Try system command-not-found handlers
    local cnf_paths="/usr/lib/command-not-found /usr/share/command-not-found/command-not-found /usr/libexec/command-not-found"
    for cnf in $cnf_paths; do
        [[ -x "$cnf" ]] || continue
        local out=$($t "$cnf" "$input" 2>&1) || true
        if echo "$out" | grep -qi "did you mean"; then
            local tmp=$(echo "$out" | grep -iEo "did you mean[^.]*$" | tail -1)
            tmp="${tmp##*did you mean}"
            tmp="${tmp##*[,: ]}"
            [[ -n "$tmp" ]] && { echo "$tmp"; return; }
        fi
    done

    # 2. Try package manager search commands. Keep each command as an
    # argument array instead of using eval so a search term can never become
    # shell syntax.
    local pm_searchers=(apt-cache dnf yum pacman apk brew snap flatpak cargo npm yarn pip gem pkg)

    for pm in "${pm_searchers[@]}"; do
        command -v "$pm" >/dev/null 2>&1 || continue

        local out
        case "$pm" in
            apt-cache) out=$($t apt-cache search "$input" 2>/dev/null) || continue ;;
            dnf)       out=$($t dnf search "$input" 2>/dev/null | grep -v '^=') || continue ;;
            yum)       out=$($t yum search "$input" 2>/dev/null) || continue ;;
            pacman)    out=$($t pacman -Ss "$input" 2>/dev/null) || continue ;;
            apk)       out=$($t apk search "$input" 2>/dev/null) || continue ;;
            brew)      out=$($t brew search "$input" 2>/dev/null) || continue ;;
            snap)      out=$($t snap find "$input" 2>/dev/null | tail -n +2) || continue ;;
            flatpak)   out=$($t flatpak search "$input" 2>/dev/null) || continue ;;
            cargo)     out=$($t cargo search "$input" --limit 5 2>/dev/null) || continue ;;
            npm)       out=$($t npm search "$input" 2>/dev/null | tail -n +2) || continue ;;
            yarn)      out=$($t yarn search "$input" 2>/dev/null) || continue ;;
            pip)       out=$($t pip index versions "$input" 2>/dev/null) || continue ;;
            gem)       out=$($t gem search "$input" --remote 2>/dev/null) || continue ;;
            pkg)       out=$($t pkg search "$input" 2>/dev/null) || continue ;;
            *)         continue ;;
        esac
        [[ -z "$out" ]] && continue

        local extracted=""
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^Checking|^No|^Results|^Error|^Fetching|^Updating|^=+|^http ]] && continue

            local pkg_name=""
            case "$pm" in
                apt-cache|dnf|yum|brew|snap|flatpak|cargo|npm|pip|pkg) pkg_name=$(echo "$line" | awk '{print $1}') ;;
                pacman)      pkg_name=$(echo "$line" | awk -F/ '{print $2}' | awk '{print $1}') ;;
                apk)         pkg_name=$(echo "$line" | awk -F'-[0-9]' '{print $1}') ;;
                yarn)        pkg_name=$(echo "$line" | awk '{print $1}') ;;
                gem)         pkg_name=$(echo "$line" | awk '{print $1}' | sed 's/^gems\///') ;;
            esac

            [[ -n "$pkg_name" && "$pkg_name" != "$input" && "$pkg_name" =~ ^[a-zA-Z0-9] ]] && extracted+="$pkg_name "
        done <<< "$out"

        if [[ -n "$extracted" ]]; then
            suggestions=$(echo "$extracted" | tr ' ' '\n' | grep -v '^$' | sort -u | head -8 | tr '\n' ' ' | sed 's/ $//')
            [[ -n "$suggestions" ]] && { echo "$suggestions"; return; }
        fi
    done

    # 3. Fuzzy fallback: match against known commands in TOOLS array
    # Use substring matching + Levenshtein approximation
    local input_len=${#input}
    local candidates=""

    for entry in "${TOOLS[@]}"; do
        IFS="|" read -r num cmd pkg name desc type extra cat <<< "$entry"
        # Substring match (input is substring of cmd/pkg)
        if [[ "${cmd,,}" == *"${input,,}"* || "${pkg,,}" == *"${input,,}"* ]]; then
            candidates+="$cmd "
        # Prefix/suffix match (cmd starts or ends with input)
        elif [[ "${cmd,,}" == "${input,,}"* || "${cmd,,}" == *"${input,,}" ]]; then
            candidates+="$cmd "
        # Levenshtein-ish: allow 1-2 char differences for short inputs
        elif (( input_len >= 3 && input_len <= 10 )); then
            local cmd_low="${cmd,,}"
            local inp_low="${input,,}"
            local diff=0
            # Quick check: same prefix (first 3 chars match)
            if [[ "${cmd_low:0:3}" == "${inp_low:0:3}" ]]; then
                (( diff++ ))
            fi
            # Same length +/- 1
            local cmd_len=${#cmd}
            if (( diff > 0 && (cmd_len == input_len || cmd_len == input_len + 1 || cmd_len == input_len - 1) )); then
                candidates+="$cmd "
            fi
        fi
    done

    if [[ -n "$candidates" ]]; then
        suggestions=$(echo "$candidates" | tr ' ' '\n' | grep -v '^$' | sort -u | head -6 | tr '\n' ' ' | sed 's/ $//')
        [[ -n "$suggestions" ]] && { echo "$suggestions"; return; }
    fi

    echo ""
}

# ── Core: install one tool by name ───
search_and_install() {
    local input="$1"
    echo ""

    if [[ -z "$input" || ! "$input" =~ ^[A-Za-z0-9._@+:/=-]+$ ]]; then
        echo -e "${ERROR}  [✗] Invalid search term: '${input}'. Use package-style names only.${RST}"
        log_warn "Rejected unsafe search/install term: $input" "search-install"
        FAILED_PKGS+=("$input")
        return 2
    fi

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

    local norm; norm=$(_si_normalize "$input")
    local pkg="${norm%|*}"
    local binary="${norm#*|}"

    echo -e "${INFO}  [*] '${BOLD_WHITE}$input${RST}${INFO}' not in tools list — scanning package managers...${RST}"
    echo -e "${DIM}      (looking suggestions for pkg: $pkg, binary: $binary)${RST}"
    echo ""

    if command -v "$binary" >/dev/null 2>&1; then
        echo -e "${OPTION}  [✓] '$binary' is already installed — nothing to do.${RST}"
        SKIPPED_PKGS+=("$input")
        sleep 2; return 0
    fi

    # Typo suggestions
    local suggestions
    suggestions=$(_si_get_suggestions "$input")
    if [[ -n "$suggestions" ]]; then
        echo ""
        echo -e "  ${ERROR}[!]${RST} '${BOLD_WHITE}$input${RST}' not found — perhaps you meant:"
        echo ""

        local suggestion_array=()
        local valid_in_tools=()
        local valid_outside=()

        for s in $suggestions; do
            suggestion_array+=("$s")
            local in_tools=$(_si_find_in_tools "$s")
            if [ -n "$in_tools" ]; then
                valid_in_tools+=("$s")
            else
                valid_outside+=("$s")
            fi
        done

        local count=0
        if [[ ${#valid_in_tools[@]} -gt 0 ]]; then
            echo -e "    ${DIM}From known tools:${RST}"
            for s in "${valid_in_tools[@]}"; do
                ((count++))
                IFS="|" read -r num cmd pkg name desc type extra cat <<< "$(_si_find_in_tools "$s")"
                echo -e "      ${OPTION}[$count]${RST} ${BOLD_WHITE}$name${RST}  ${DIM}($cmd / $pkg)${RST}"
            done
        fi

        if [[ ${#valid_outside[@]} -gt 0 ]]; then
            [[ ${#valid_in_tools[@]} -gt 0 ]] && echo ""
            echo -e "    ${DIM}Other suggestions:${RST}"
            for s in "${valid_outside[@]}"; do
                ((count++))
                echo -e "      ${OPTION}[$count]${RST} ${DIM}$s${RST}"
            done
        fi

        echo ""
        echo -ne "  ${BRIGHT_MAGENTA}[*] Pick a number to install, or press Enter to skip: ${RST}"
        read -r pick

        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= count )); then
            local selected="${suggestion_array[$((pick - 1))]}"
            local tool_info=$(_si_find_in_tools "$selected")
            if [ -n "$tool_info" ]; then
                IFS="|" read -r num cmd pkg name desc type extra cat <<< "$tool_info"
                echo ""
                echo -e "${INFO}  [*] Installing ${BOLD_WHITE}$name${RST}..."
                sleep 2
                projectr_install_tool_by_fields "$cmd" "$pkg" "$name" "$type" "$extra"
                return
            else
                echo ""
                echo -e "${INFO}  [*] Routing '${BOLD_WHITE}$selected${RST}' through package manager...${RST}"
                sleep 2
                local new_norm; new_norm=$(_si_normalize "$selected")
                pkg="${new_norm%|*}"
                binary="${new_norm#*|}"
            fi
        else
            echo -e "${DIM}      Skipped — continuing with normal scan.${RST}"
            sleep 1
        fi
        echo ""
    fi

    local sys_pm; sys_pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
    local candidates=()
    [ -n "$sys_pm" ] && candidates+=("$sys_pm")
    for lm in cargo npm yarn pnpm bun pipx pip pip3 gem; do
        command -v "$lm" >/dev/null 2>&1 && candidates+=("$lm")
    done

    local unique=()
    for m in "${candidates[@]}"; do
        [[ " ${unique[*]} " == *" $m "* ]] || unique+=("$m")
    done
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
            printf " ${ERROR}[✗] - not found${RST}\n"
        fi
    done

    if [ ${#available[@]} -eq 0 ]; then
        echo ""
        echo -e "${ERROR}  [✗] No package manager has '${BOLD_WHITE}$pkg${RST}${ERROR}' available.${RST}"
        echo -e "${INFO}  [*] Check manually: https://repology.org/project/$pkg/versions${RST}"
        FAILED_PKGS+=("$input")
        sleep 3; return 1
    fi

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
        echo -e "    ${ERROR}[0]${RST} ${DIM}Cancel and go back${RST}"
        echo ""
        echo -ne "  ${BRIGHT_MAGENTA}[*] Choose [0-${#available[@]}]: ${RST}"
        read -r pick
        if [[ "$pick" =~ ^[0-9]+$ ]]; then
            if (( pick == 0 )); then
                echo ""
                echo -e "${DIM}      Cancelled.${RST}"
                sleep 1
                return 0
            elif (( pick >= 1 && pick <= ${#available[@]} )); then
                chosen="${available[$((pick-1))]}"
            else
                echo -e "${INFO}  [*] Invalid input — defaulting to: ${BOLD_WHITE}$chosen${RST}"
            fi
        else
            echo -e "${INFO}  [*] Invalid input — defaulting to: ${BOLD_WHITE}$chosen${RST}"
        fi
    fi

    echo ""
    log INSTALL "search_and_install: '$input' → pkg='$pkg' via '$chosen'"

    case "$chosen" in
        pip|pip3|pipx) install_lang "$chosen" "$pkg" "$input" "$binary" ;;
        npm|yarn|pnpm|bun) install_lang "$chosen" "$pkg" "$input" "$binary" ;;
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
            "● Auto-detects typos and suggests correct tool names" \
            "● Type '/' to open interactive Fuzzy Search"
        echo -e "${RST}"
        echo ""
        echo -e "${INFO}  [*] Examples: ${DIM}git, neovim, ripgrep, holehe, lazygit${RST}"
        echo -e "${ERROR}  [b] Back to main menu${RST}"
        echo ""
        echo -ne " ${DIM} [*] Tool name(s) or '/' to search:${RST} "
        read -ra inputs

        [[ ${#inputs[@]} -eq 0 ]] && continue
        [[ "${inputs[0],,}" == "b" ]] && { log LEFT "User exited sub-menu 'search-install'"; return; }

        if [[ "${inputs[0]}" == "/" ]]; then
            interactive_fuzzy_search
            printf "${DIM}  [press ENTER]${RST}"
            read -s; echo
            continue
        fi

        INSTALLED_PKGS=()
        SKIPPED_PKGS=()
        FAILED_PKGS=()

        for tool in "${inputs[@]}"; do
            [[ -z "$tool" ]] && continue
            search_and_install "$tool"
            echo ""
        done

        if (( ${#inputs[@]} > 1 )); then
            post_install_summary
        fi

        printf "${DIM}  [press ENTER]${RST}"
        read -s; echo
        echo -e "${DIM}"
        ask "  [*] Install another tool?" "n" && continue || return
        echo -e "${RST}"
    done
}

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
