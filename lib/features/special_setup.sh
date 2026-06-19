#!/bin/bash
# shellcheck disable=all

projectr_truthy() {
  case "${1:-}" in
  1 | true | TRUE | yes | YES | y | Y | on | ON) return 0 ;;
  *) return 1 ;;
  esac
}

projectr_nvim_config_repo() {
  case "${1,,}" in
  nvchad | 1) printf 'NvChad|https://github.com/NvChad/starter\n' ;;
  lazyvim | 2) printf 'LazyVim|https://github.com/LazyVim/starter\n' ;;
  astronvim | 3) printf 'AstroNvim|https://github.com/AstroNvim/template\n' ;;
  skip | 4 | '') printf 'skip|\n' ;;
  *) return 1 ;;
  esac
}

projectr_zsh_set_theme() {
  local theme="$1" zshrc="$HOME/.zshrc" tmp
  [[ -f "$zshrc" ]] || return 0
  tmp=$(mktemp) || return 1
  awk -v theme="$theme" '
        BEGIN { changed=0 }
        /^ZSH_THEME=/ { print "ZSH_THEME=\"" theme "\""; changed=1; next }
        { print }
        END { if (!changed) print "ZSH_THEME=\"" theme "\"" }
    ' "$zshrc" >"$tmp" && mv "$tmp" "$zshrc"
}

# -- install neovim & config --
setup_nvim() {

  install_pkg nvim neovim "Neovim: Best code editor"
  sleep 1

  local saved desired
  saved=$(config_get "nvim_config_choice")
  desired="${PROJECTR_NVIM_CONFIG:-}"

  if [[ "$saved" == "skip" && -z "$desired" ]]; then
    return 0
  fi

  if [[ "$saved" == "done" && -z "$desired" ]]; then
    return 0
  fi

  local STANDARD_PATH="$HOME/.config/nvim"
  if [[ -d "$STANDARD_PATH" && -z "$desired" ]]; then
    echo -e "${OPTION}  [✓] A Neovim configuration is already present.${RST}"
    sleep 1
    return 0
  fi

  if [[ -n "$desired" ]]; then
    prompt_nvim_config "$desired"
    [[ $? -eq 0 ]] && config_set "nvim_config_choice" "done"
    return $?
  fi

  if ! ask "  [*] Install a config for NeoVim?"; then
    config_set "nvim_config_choice" "skip"
    return 0
  fi

  if prompt_nvim_config; then
    config_set "nvim_config_choice" "done"
  fi
}

prompt_nvim_config() {

  if ! command -v git >/dev/null 2>&1; then
    echo -e "${ERROR}  [ℹ] Git is not installed. Unable to clone the Neovim configuration.${RST}"
    return 1
  fi
  local repo=""
  while true; do
    echo -e "${INFO}  [*] Please select the configuration to install:${RST}"
    echo ""
    echo -e "${OPTION}   [1] NvChad ${RST}"
    echo -e "${OPTION}   [2] LazyVim ${RST}"
    echo -e "${OPTION}   [3] AstroNvim ${RST}"
    echo -e "${OPTION}   [4] Skip ${RST}"
    echo ""
    echo -ne "${INFO}  [*] Enter selection (1-4): ${RST}"
    local config_choice
    read -r config_choice
    case "$config_choice" in
    1)
      repo="https://github.com/NvChad/starter"
      break
      ;;
    2)
      repo="https://github.com/LazyVim/starter"
      break
      ;;
    3)
      repo="https://github.com/AstroNvim/template"
      break
      ;;
    4)
      echo -e "${INFO}  [*] Skipping Neovim configuration installation...${RST}"
      return 0
      ;;
    *)
      echo -e "${ERROR}  [ℹ] Invalid selection: '$config_choice'.${RST}"
      ;;
    esac
  done
  echo -e "${OPTION}  [*] Cloning repository: $repo...${RST}"
  git clone --depth 1 "$repo" "$HOME/.config/nvim" >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo -e "${ERROR}  [ℹ] Failed to clone repository: $repo. Please verify network connectivity.${RST}"
    return 1
  fi
  echo -e "${OPTION}  [✓] Repository $repo cloned successfully.${RST}"
  log INSTALL "Neovim config cloned successfully"
  if [[ -d "$HOME/.config/nvim/.git" ]]; then
    rm -rf "$HOME/.config/nvim/.git"
    echo -e "${OPTION}  [✓] The .git directory has been successfully removed.${RST}"
  fi
}

#  install zsh & oh-my-zsh.
setup_zsh() {
  install_pkg zsh zsh "Zsh: Extended shell with powerful features"
  sleep 1

  local want_omz="${PROJECTR_ZSH_INSTALL_OMZ:-}"
  local want_p10k="${PROJECTR_ZSH_INSTALL_P10K:-}"
  local theme_choice="${PROJECTR_ZSH_THEME:-}"

  if [[ -z "$want_omz" ]]; then
    ask "  [*] Install oh-my-zsh?" "y" || return 0
  elif ! projectr_truthy "$want_omz"; then
    return 0
  fi

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "${OPTION}  [✓] Oh-My-Zsh already exists. Skipping...${RST}"
  else
    if ! command -v git >/dev/null 2>&1; then
      echo -e "${ERROR}  [ℹ] Git is not installed. Unable to safely clone Oh-My-Zsh.${RST}"
      return 1
    fi
    echo -e "${INFO}  [*] Cloning the Oh-My-Zsh repository directly...${RST}"
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo -e "${ERROR}  [ℹ] Failed to clone the Oh-My-Zsh repository.${RST}"
      return 1
    fi
    if [[ ! -f "$HOME/.zshrc" && -f "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" ]]; then
      cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc" 2>/dev/null || true
    fi
  fi

  if [[ -n "$theme_choice" && "$theme_choice" != "powerlevel10k" ]]; then
    projectr_zsh_set_theme "$theme_choice" || true
  fi

  if [[ -z "$want_p10k" ]]; then
    ask "  [*] Also install Powerlevel10k?" "y" || return 0
  elif ! projectr_truthy "$want_p10k"; then
    return 0
  fi

  if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
    echo -e "${OPTION}  [✓] Powerlevel10k already installed — skipping.${RST}"
  else
    if ! command -v git >/dev/null 2>&1; then
      echo -e "${ERROR}  [ℹ] Git is not installed. Unable to clone Powerlevel10k.${RST}"
      return 1
    fi
  fi
  echo -e "${INFO}  [*] Cloning the Powerlevel10k repository...${RST}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo -e "${ERROR}  [ℹ] Failed to clone Powerlevel10k. Please verify network connectivity.${RST}"
    return 1
  fi
  echo ""
  echo -e "${OPTION} [✓] Powerlevel10k installation complete. Run 'p10k configure' to set up.${RST}"

  projectr_zsh_set_theme "powerlevel10k/powerlevel10k" || true
  echo ""
  echo -e "${OPTION} [✓] Powerlevel10k installed. Run: p10k configure${RST}"
  log INSTALL "Powerlevel10k cloned successfully"
}
#  install_code_server — special installer for code-server
install_code_server() {
  if [[ "${PRIMARY_PKG_MANAGER:-}" != "pkg" ]]; then
    echo -e "${ERROR}  [ℹ] Installation of code-server via tur-repo is only supported on Termux environment.${RST}"
    return 1
  fi
  if ! [ -f "$PREFIX/etc/apt/sources.list.d/tur.list" ]; then
    msg_info "Code-server requires tur-repo."
    if ! ask " [*] Set it up now?" "y"; then
      msg_info "Skipping installation of code-server"
      sleep 2
      return 1
    fi
    msg_info "Installing tur-repo now"
    pkg update >/dev/null 2>&1 && pkg install -y tur-repo >/dev/null 2>&1
  fi
  if [[ $? -ne 0 ]]; then
    msg_error "Failed to install tur-repo. Installation of code-server has been aborted."
    sleep 2
    return 1
  else
    msg_success "tur-repo installed, continuing installation of code-server"
  fi
  echo ""
  install_pkg code-server code-server "Code-server: VScode on android"
}

# -- special installers for tools that usually need extra context or optional hints --
setup_golang() {
  install_pkg go golang "Go: Programming language and toolchain"
  if command -v go >/dev/null 2>&1; then
    echo -e "${INFO}  [*] Recommended: Append \"\$(go env GOPATH 2>/dev/null)/bin\" to your PATH to enable Go binaries.${RST}"
  fi
}

setup_rustup() {
  install_pkg rustup rustup "Rustup: Rust toolchain manager"
  post_rust
}

setup_docker() {
  local docker_pkg="docker"
  case "${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}" in
  apt | apt-get) docker_pkg="docker.io" ;;
  dnf | yum | zypper) docker_pkg="docker" ;;
  pkg) docker_pkg="docker" ;;
  esac

  install_pkg docker "$docker_pkg" "Docker: Container engine and CLI"
  post_docker
}

setup_kubectl() {
  install_pkg kubectl kubectl "Kubectl: Kubernetes command-line tool"
  post_kubectl
}

setup_postgres() {
  install_pkg postgres postgresql "PostgreSQL: Advanced relational database"
  post_postgres
}

setup_mysql() {
  install_pkg mysql mysql "MySQL: Database server and client"
  post_mysql
}

setup_android_tools() {
  install_pkg adb android-tools "Android tools: adb and fastboot utilities"
  post_adb
}

post_rust() {
  if command -v rustc >/dev/null 2>&1; then
    echo -e "${INFO}  [*] Execute 'rustup default stable' to activate the default Rust toolchain.${RST}"
  fi
}
post_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo -e "${INFO}  [*] For rootless access, add your user account to the 'docker' group and re-establish the session.${RST}"
  fi
}
post_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    echo -e "${INFO}  [*] Please configure cluster credentials via kubeconfig before running kubectl commands.${RST}"
  fi
}
post_postgres() {
  if command -v psql >/dev/null 2>&1; then
    echo -e "${INFO}  [*] Initialize and start the PostgreSQL service using the system service manager instructions.${RST}"
  fi
}
post_mysql() {
  if command -v mysql >/dev/null 2>&1; then
    echo -e "${INFO}  [*] Execute the system database secure-installation utility prior to exposing MySQL services.${RST}"
  fi
}
post_adb() {
  if command -v adb >/dev/null 2>&1; then
    echo -e "${INFO}  [*] Please ensure USB debugging is enabled on your Android device before utilizing adb.${RST}"
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
    echo -e "${OPTION}   [✓] Neovim configuration has been removed.${RST}"
  fi
}

uninstall_zsh_special() {
  uninstall_pkg zsh zsh "Zsh"
  projectr_uninstall_omz
}

projectr_uninstall_omz() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    rm -rf "$HOME/.oh-my-zsh"
    echo -e "${OPTION}   [✓] Oh-My-Zsh directories and files have been removed.${RST}"
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
