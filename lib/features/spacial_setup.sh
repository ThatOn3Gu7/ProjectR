#!/bin/bash

# -- install neovim & config --
setup_nvim() {

  install_pkg nvim neovim "Neovim: Best code editor"
  sleep 1
  
    local saved
    saved=$(config_get "nvim_config_choice")

    # User already said skip — respect it
    if [[ "$saved" == "skip" ]]; then
        return 0
    fi

    # User already installed a config in a previous run — don't ask again
    if [[ "$saved" == "done" ]]; then
        return 0
    fi

    # Config dir already exists — something is there, move on
    local STANDARD_PATH="$HOME/.config/nvim"
    if [[ -d "$STANDARD_PATH" ]]; then
        echo -e "${OPTION}  [✓] A Neovim config is already installed!${RST}"
        sleep 2
        return 0
    fi

    if ! ask "  [*] Install a config for NeoVim?"; then
        config_set "nvim_config_choice" "skip"
        return 0
    fi

    if prompt_nvim_config; then
        # Only mark done if the clone actually succeeded
        config_set "nvim_config_choice" "done"
    fi
 }
# Checks for a nvim config and gives the user the choice to clone one
prompt_nvim_config() {

    if ! command -v git >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] git is not installed — cannot clone a Neovim config.${RST}"
        return 1
    fi

    echo -e "${INFO}  [*] Which config would you like to install? ${RST}"
    echo ""
    echo -e "${OPTION}   [1] NvChad ${RST}"
    echo -e "${OPTION}   [2] LazyVim ${RST}"
    echo -e "${OPTION}   [3] AstroNvim ${RST}"
    echo -e "${OPTION}   [4] Skip ${RST}"
    echo ""
    echo -ne "${INFO}  [*] Select option (1-4): ${RST}"
    read -r config_choice

    local repo url
    case "$config_choice" in
        1) repo="NvChad";    url="https://github.com/NvChad/starter" ;;
        2) repo="LazyVim";   url="https://github.com/LazyVim/starter" ;;
        3) repo="AstroNvim"; url="https://github.com/AstroNvim/template" ;;
        4)
            echo -e "${INFO}  [*] Skipping Neovim config installation...${RST}"
            return 0
            ;;
        *)
            echo -e "${ERROR}  [!] Invalid option: '$config_choice'${RST}"
            return 1
            ;;
    esac

    echo -e "${OPTION}  [*] Cloning $repo...${RST}"

    if ! git clone --depth 1 "$url" ~/.config/nvim 2>&1; then
        echo -e "${ERROR}  [!] Failed to clone $repo — check your internet connection.${RST}"
        log FAIL "git clone failed for $repo ($url)"
        return 1
    fi

    echo -e "${OPTION}  [✓] $repo cloned successfully.${RST}"
    log INSTALL "$repo Neovim config cloned"

    if ask "  [*] Remove .git folder?" "y"; then
        rm -rf ~/.config/nvim/.git
        echo -e "${OPTION}  [✓] .git folder removed.${RST}"
    fi
}
#  install zsh & oh-my-zsh.
setup_zsh() {
    install_pkg zsh zsh "Zsh: Extended shell with powerful features"
    sleep 1

    if ! ask "  [*] Install oh-my-zsh?" "y"; then
        return 0
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${OPTION}  [✓] Oh-My-Zsh already exists. Skipping...${RST}"
        sleep 2
    else
        if ! command -v curl >/dev/null 2>&1; then
            echo -e "${ERROR}  [!] curl is not installed — cannot download oh-my-zsh.${RST}"
            return 1
        fi

        echo -e "${ERROR}  [!] IMPORTANT: The oh-my-zsh installer will REPLACE this shell session.${RST}"
        echo -e "${ERROR}  [!] ProjectR will exit when the new shell starts. This is expected.${RST}"
        echo -e "${INFO}  [*] Re-run ProjectR after zsh finishes setting up.${RST}"
        echo -e "${INFO}  [*] Clone plugins manually afterwards for full ohmyzsh features.${RST}"
        echo ""
        sleep 2

        log EXIT "oh-my-zsh installer launched — shell will be replaced by zsh"
        stop_spinner 2>/dev/null
        safe_tput cnorm

        local omz_installer
        omz_installer=$(mktemp)
        if ! curl -fsSL \
                https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
                -o "$omz_installer" 2>/dev/null || [[ ! -s "$omz_installer" ]]; then
            echo -e "${ERROR}  [!] Failed to download oh-my-zsh installer.${RST}"
            rm -f "$omz_installer"
            return 1
        fi

        KEEP_ZSHRC=yes sh "$omz_installer"
        rm -f "$omz_installer"
    fi

    sleep 1

    if ! ask "  [*] Also install Powerlevel10k?" "y"; then
        return 0
    fi

    if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        echo -e "${OPTION}  [✓] Powerlevel10k already installed — skipping.${RST}"
        sleep 3
        return 0
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] git is not installed — cannot clone Powerlevel10k.${RST}"
        return 1
    fi

    echo -e "${INFO}  [*] Cloning Powerlevel10k...${RST}"
    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" >/dev/null 2>&1; then
        echo -e "${ERROR}  [!] Failed to clone Powerlevel10k — check your connection.${RST}"
        log FAIL "git clone failed for Powerlevel10k"
        return 1
    fi

    echo ""
    echo -e "${OPTION} [✓] Powerlevel10k installed. Run: p10k configure${RST}"
    log INSTALL "Powerlevel10k cloned successfully"
}
#  install_code_server — special installer for code-server
install_code_server() {
    if [[ "${PRIMARY_PKG_MANAGER:-}" != "pkg" ]]; then
        echo -e "${ERROR}  [!] code-server via tur-repo is only supported on Termux.${RST}"
        return 1
    fi
    echo -e "${OPTION}"
    if ask "[*] tur-repo is required for code-server. Install it?" "y"; then
        echo -e "${RST}"
        if ! progress_run "Installing tur-repo" \
                          "tur-repo ready" \
                          pkg install -y tur-repo; then
            echo -e "${ERROR}  [!] tur-repo failed to install — aborting code-server.${RST}"
            log FAIL "tur-repo install failed; code-server aborted"
            return 1
        fi
        echo ""
        install_pkg "code-server" "code-server" "Code-Server: VSCode on Android"
    else
        echo -e "${INFO}  [→] Skipping code-server installation.${RST}"
    fi
}

# -- special installers for tools that usually need extra context or optional hints --
setup_golang() {
    install_pkg go golang "Go: Programming language and toolchain"
    if command -v go >/dev/null 2>&1; then
        echo -e "${INFO}  [*] Tip: add \"$(go env GOPATH 2>/dev/null)/bin\" to PATH for Go-installed CLIs.${RST}"
    fi
}

setup_rustup() {
    install_pkg rustup rustup "Rustup: Rust toolchain manager"
    if command -v rustup >/dev/null 2>&1; then
        echo -e "${INFO}  [*] Run 'rustup default stable' if no Rust toolchain is active yet.${RST}"
    fi
}

setup_docker() {
    local docker_pkg="docker"
    case "${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}" in
        apt|apt-get) docker_pkg="docker.io" ;;
        dnf|yum|zypper) docker_pkg="docker" ;;
        pkg) docker_pkg="docker" ;;
    esac

    install_pkg docker "$docker_pkg" "Docker: Container engine and CLI"
    if command -v docker >/dev/null 2>&1; then
        echo -e "${INFO}  [*] If Docker needs rootless access, add your user to the docker group and re-login.${RST}"
    fi
}

setup_kubectl() {
    install_pkg kubectl kubectl "Kubectl: Kubernetes command-line tool"
    if command -v kubectl >/dev/null 2>&1; then
        echo -e "${INFO}  [*] Configure clusters with kubeconfig before running kubectl commands.${RST}"
    fi
}

setup_postgres() {
    install_pkg postgres postgresql "PostgreSQL: Advanced relational database"
    if command -v postgres >/dev/null 2>&1 || command -v psql >/dev/null 2>&1; then
        echo -e "${INFO}  [*] Start or initialize PostgreSQL using your distro's service instructions.${RST}"
    fi
}

setup_mysql() {
    install_pkg mysql mysql "MySQL: Database server and client"
    if command -v mysql >/dev/null 2>&1; then
        echo -e "${INFO}  [*] Run your distro's secure-installation flow before exposing MySQL services.${RST}"
    fi
}

setup_android_tools() {
    install_pkg adb android-tools "Android tools: adb and fastboot utilities"
    if command -v adb >/dev/null 2>&1; then
        echo -e "${INFO}  [*] Enable USB debugging on your Android device before using adb.${RST}"
    fi
}

# Optional special uninstall hooks. projectr_uninstall_tool_by_fields falls back
# to normal package removal when a hook is not listed here.
declare -gA PROJECTR_SPECIAL_UNINSTALLERS=(
    [setup_nvim]=uninstall_nvim_special
    [setup_zsh]=uninstall_zsh_special
    [install_code_server]=uninstall_code_server_special
    [setup_golang]=uninstall_golang_special
    [setup_rustup]=uninstall_rustup_special
    [setup_docker]=uninstall_docker_special
    [setup_kubectl]=uninstall_kubectl_special
    [setup_postgres]=uninstall_postgres_special
    [setup_mysql]=uninstall_mysql_special
    [setup_android_tools]=uninstall_android_tools_special
)

uninstall_nvim_special() {
    uninstall_pkg nvim neovim "Neovim"
    if [[ -d "$HOME/.config/nvim" ]] && ask "   [*] Also remove Neovim config files?" "y"; then
        rm -rf "$HOME/.config/nvim"
        echo -e "${OPTION}   [✓] Neovim config removed${RST}"
    fi
}

uninstall_zsh_special() {
    uninstall_pkg zsh zsh "Zsh"
    if [[ -d "$HOME/.oh-my-zsh" ]] && ask "   [*] Also remove Oh-My-Zsh files?" "n"; then
        rm -rf "$HOME/.oh-my-zsh"
        echo -e "${OPTION}   [✓] Oh-My-Zsh files removed${RST}"
    fi
}

uninstall_code_server_special() { uninstall_pkg code-server code-server "Code-Server"; }
uninstall_golang_special() { uninstall_pkg go golang "Go"; }
uninstall_rustup_special() { uninstall_pkg rustup rustup "Rustup"; }
uninstall_docker_special() { uninstall_pkg docker docker "Docker"; }
uninstall_kubectl_special() { uninstall_pkg kubectl kubectl "Kubectl"; }
uninstall_postgres_special() { uninstall_pkg postgres postgresql "PostgreSQL"; }
uninstall_mysql_special() { uninstall_pkg mysql mysql "MySQL"; }
uninstall_android_tools_special() { uninstall_pkg adb android-tools "Android tools"; }
