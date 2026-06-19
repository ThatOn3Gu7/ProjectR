#!/bin/bash
# shellcheck disable=all

check_dependency() {
  local cmd="$1"
  local name="$2"
  local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  else
    echo ""
    echo -e "${ERROR} [✖] ${name} is NOT installed${RST}"

    # Generate cross-platform hint
    local hint=""
    case "$pm-$cmd" in
    # ── apt ────────────────────────────────────────────
    apt-lolcat) hint="sudo apt install ruby && gem install lolcat" ;;
    apt-git) hint="sudo apt install git" ;;
    apt-curl) hint="sudo apt install curl" ;;
    apt-crontab) hint="sudo apt install cron" ;;
    # ── apt-get ────────────────────────────────────────
    apt-get-lolcat) hint="sudo apt-get install ruby && gem install lolcat" ;;
    apt-get-git) hint="sudo apt-get install git" ;;
    apt-get-curl) hint="sudo apt-get install curl" ;;
    apt-get-crontab) hint="sudo apt-get install cron" ;;
    # ── pacman ─────────────────────────────────────────
    pacman-lolcat) hint="sudo pacman -S lolcat" ;;
    pacman-git) hint="sudo pacman -S git" ;;
    pacman-curl) hint="sudo pacman -S curl" ;;
    pacman-crontab) hint="sudo pacman -S cronie" ;;
    # ── dnf ────────────────────────────────────────────
    dnf-lolcat) hint="sudo dnf install lolcat" ;;
    dnf-git) hint="sudo dnf install git" ;;
    dnf-curl) hint="sudo dnf install curl" ;;
    dnf-crontab) hint="sudo dnf install cronie" ;;
    # ── yum ────────────────────────────────────────────
    yum-lolcat) hint="sudo yum install lolcat" ;;
    yum-git) hint="sudo yum install git" ;;
    yum-curl) hint="sudo yum install curl" ;;
    yum-crontab) hint="sudo yum install cronie" ;;
    # ── zypper ─────────────────────────────────────────
    zypper-lolcat) hint="sudo zypper install lolcat" ;;
    zypper-git) hint="sudo zypper install git" ;;
    zypper-curl) hint="sudo zypper install curl" ;;
    zypper-crontab) hint="sudo zypper install cronie" ;;
    # ── apk ────────────────────────────────────────────
    apk-lolcat) hint="sudo apk add lolcat" ;;
    apk-git) hint="sudo apk add git" ;;
    apk-curl) hint="sudo apk add curl" ;;
    apk-crontab) hint="sudo apk add cronie" ;;
    # ── emerge (Gentoo) ────────────────────────────────
    emerge-lolcat) hint="sudo emerge --ask app-misc/lolcat" ;;
    emerge-git) hint="sudo emerge --ask dev-vcs/git" ;;
    emerge-curl) hint="sudo emerge --ask net-misc/curl" ;;
    emerge-crontab) hint="sudo emerge --ask sys-process/cronie" ;;
    # ── xbps (Void) ────────────────────────────────────
    xbps-lolcat) hint="sudo xbps-install -S lolcat" ;;
    xbps-git) hint="sudo xbps-install -S git" ;;
    xbps-curl) hint="sudo xbps-install -S curl" ;;
    xbps-crontab) hint="sudo xbps-install -S cronie" ;;
    # ── nix ────────────────────────────────────────────
    nix-lolcat) hint="nix-shell -p lolcat" ;;
    nix-git) hint="nix-shell -p git" ;;
    nix-curl) hint="nix-shell -p curl" ;;
    nix-crontab) hint="nix-shell -p cron" ;;
    # ── guix ───────────────────────────────────────────
    guix-lolcat) hint="guix package -i lolcat" ;;
    guix-git) hint="guix package -i git" ;;
    guix-curl) hint="guix package -i curl" ;;
    guix-crontab) hint="guix package -i mcron" ;;
    # ── eopkg (Solus) ──────────────────────────────────
    eopkg-lolcat) hint="sudo eopkg install lolcat" ;;
    eopkg-git) hint="sudo eopkg install git" ;;
    eopkg-curl) hint="sudo eopkg install curl" ;;
    eopkg-crontab) hint="sudo eopkg install cronie" ;;
    # ── urpmi (Mageia) ─────────────────────────────────
    urpmi-lolcat) hint="sudo urpmi lolcat" ;;
    urpmi-git) hint="sudo urpmi git" ;;
    urpmi-curl) hint="sudo urpmi curl" ;;
    urpmi-crontab) hint="sudo urpmi cronie" ;;
    # ── slackpkg (Slackware) ───────────────────────────
    slackpkg-lolcat) hint="gem install lolcat" ;;
    slackpkg-git) hint="sudo slackpkg install git" ;;
    slackpkg-curl) hint="sudo slackpkg install curl" ;;
    slackpkg-crontab) hint="sudo slackpkg install dcron" ;;
    # ── brew (macOS/Linux) ─────────────────────────────
    brew-lolcat) hint="brew install lolcat" ;;
    brew-git) hint="brew install git" ;;
    brew-curl) hint="brew install curl" ;;
    brew-crontab) hint="brew install --cask cron" ;;
    # ── macports ───────────────────────────────────────
    macports-lolcat) hint="sudo port install lolcat" ;;
    macports-git) hint="sudo port install git" ;;
    macports-curl) hint="sudo port install curl" ;;
    macports-crontab) hint="sudo port install cron" ;;
    # ── bsd-pkg (FreeBSD) ──────────────────────────────
    bsd-pkg-lolcat) hint="sudo pkg install lolcat" ;;
    bsd-pkg-git) hint="sudo pkg install git" ;;
    bsd-pkg-curl) hint="sudo pkg install curl" ;;
    bsd-pkg-crontab) hint="sudo pkg install cronie" ;;
    # ── pkg_add (OpenBSD) ──────────────────────────────
    pkg_add-lolcat) hint="doas pkg_add lolcat" ;;
    pkg_add-git) hint="doas pkg_add git" ;;
    pkg_add-curl) hint="doas pkg_add curl" ;;
    pkg_add-crontab) hint="built-in -- enable via: rcctl enable cron" ;;
    # ── pkg (Termux) ───────────────────────────────────
    pkg-lolcat) hint="pkg install ruby && gem install lolcat" ;;
    pkg-git) hint="pkg install git" ;;
    pkg-curl) hint="pkg install curl" ;;
    pkg-crontab) hint="pkg install cronie" ;;
    # ── winget ─────────────────────────────────────────
    winget-lolcat) hint="gem install lolcat" ;;
    winget-git) hint="winget install Git.Git" ;;
    winget-curl) hint="winget install curl.curl" ;;
    winget-crontab) hint="use Windows Task Scheduler (no native cron)" ;;
    # ── choco ──────────────────────────────────────────
    choco-lolcat) hint="choco install lolcat" ;;
    choco-git) hint="choco install git" ;;
    choco-curl) hint="choco install curl" ;;
    choco-crontab) hint="choco install nncron" ;;
    # ── scoop ──────────────────────────────────────────
    scoop-lolcat) hint="scoop install lolcat" ;;
    scoop-git) hint="scoop install git" ;;
    scoop-curl) hint="scoop install curl" ;;
    scoop-crontab) hint="use Windows Task Scheduler (no native cron)" ;;
    # ── flatpak ────────────────────────────────────────
    flatpak-lolcat) hint="gem install lolcat" ;;
    flatpak-git) hint="flatpak install flathub org.gnome.gitlab.albfan.GitCola" ;;
    flatpak-curl) hint="flatpak install flathub org.curl.curl" ;;
    flatpak-crontab) hint="use your system cron (flatpak has no cron package)" ;;
    # ── snap ───────────────────────────────────────────
    snap-lolcat) hint="sudo snap install lolcat" ;;
    snap-git) hint="sudo snap install git" ;;
    snap-curl) hint="sudo snap install curl" ;;
    snap-crontab) hint="use your system cron (snap has no cron package)" ;;
    # ── fallback ───────────────────────────────────────
    *) hint="Install $cmd using your package manager" ;;
    esac
    echo -e "${INFO} [ℹ] Try: $hint${RST}"
    return 1
  fi
}
# Check multiple dependencies and show menu if missing
verify_dependencies() {
  # ONE-TIME: if user already chose to skip dep check, honour it
  if [ "$(config_get 'skip_dep_check')" = "true" ]; then
    return 0
  fi
  local missing_count=0
  local missing_deps=()
  # Define dependencies here
  # Format: "command:Display Name"
  local dependencies=(
    "lolcat:Lolcat (Recommended)"
    "git:Git (Required)"
    "curl:cURL (Required)"
  )

  # Check each dependency
  for dep in "${dependencies[@]}"; do
    IFS=":" read -r cmd name <<<"$dep"
    if ! check_dependency "$cmd" "$name"; then
      missing_deps+=("$cmd:$name")
      ((missing_count++))
    fi
  done

  # If nothing missing, return
  if [ $missing_count -eq 0 ]; then
    return 0
  fi

  echo ""
  echo -e "${ERROR} [ℹ] $missing_count dependency(ies) missing!${RST}"
  echo ""

  # Tell user what to do
  echo -e " ${BOLD_YELLOW}[*] Options:${RST}"
  echo ""
  echo -e "${OPTION}  [1] Try to auto-install missing dependencies${RST}"
  echo -e "${OPTION}  [2] Show manual installation commands${RST}"
  echo -e "${OPTION}  [3] Continue anyway (not recommended)${RST}"
  echo -e "${ERROR}  [4] Exit script${RST}"
  echo ""

  local choice
  while true; do
    echo -ne " ${BRIGHT_MAGENTA}▶ Select option [1-4]: ${RST}"
    read -r choice

    case $choice in
    1)
      auto_install_dependencies "${missing_deps[@]}"
      break
      ;;
    2)
      show_install_commands "${missing_deps[@]}"
      break
      ;;
    3)
      if ask " [*] Save choice for next time?" "y"; then
        echo -e "${INFO} [*] Continuing with missing deps (preference saved)...${RST}"
        config_set "skip_dep_check" "true"
      else
        echo -e "${INFO} [*] Continuing with missing deps (not saved)...${RST}"
      fi
      sleep 1
      break
      ;;
    4)
      graceful_exit
      ;;
    *)
      echo -e "${BOLD_RED} [ℹ] Invalid input: '${choice}' — enter 1, 2, 3 or 4.${RST}"
      sleep 1
      ;;
    esac
  done
}
# Improved auto-install with privilege check and better error handling
auto_install_dependencies() {
  local deps=("$@")
  local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"
  local failed=()

  # Privilege check — most system PMs require root or sudo
  local needs_sudo=0
  case "$pm" in apt | pacman | dnf | yum | zypper | apk | emerge | xbps) needs_sudo=1 ;; esac

  if ((needs_sudo)) && [[ $EUID -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      echo -e "${ERROR} [ℹ] This system requires root to install packages and sudo is not available.${RST}"
      echo -e "${INFO} [*] Re-run the script as root, or install dependencies manually.${RST}"
      return 1
    fi
    # Verify sudo works right now (cached credential or password prompt)
    if ! sudo -v 2>/dev/null; then
      echo -e "${ERROR} [ℹ] sudo authentication failed — cannot auto-install.${RST}"
      return 1
    fi
  fi

  echo ""
  echo -e "${BOLD_BLUE} [*] Attempting to install missing dependencies...${RST}"

  for dep in "${deps[@]}"; do
    IFS=":" read -r cmd name <<<"$dep"

    start_spinner " [*] Installing: $name.."

    case "$cmd" in
    lolcat)
      if install_lolcat >/dev/null 2>&1; then
        stop_spinner "${OPTION} [✓] Installed: $name${RST}"
      else
        stop_spinner "${ERROR} [✖] Failed: $name${RST}"
        failed+=("$name")
      fi
      ;;
    git | curl | crontab)
      local install_arr=()
      case "$pm" in
      apt) install_arr=(sudo apt-get install -y "$cmd") ;;
      pacman) install_arr=(sudo pacman -S --noconfirm "$cmd") ;;
      dnf | yum) install_arr=(sudo "$pm" install -y "$cmd") ;;
      zypper) install_arr=(sudo zypper install -y "$cmd") ;;
      apk) install_arr=(sudo apk add "$cmd") ;;
      pkg) install_arr=(pkg install -y "$cmd") ;;
      brew) install_arr=(brew install "$cmd") ;;
      nix) install_arr=(nix-env -i "$cmd") ;;
      *)
        stop_spinner "${ERROR} [✖] No auto-install rule for PM: $pm${RST}"
        failed+=("$name")
        continue
        ;;
      esac
      if "${install_arr[@]}" >/dev/null 2>&1; then
        stop_spinner "${OPTION}  [✓] Installed: $cmd${RST}"
      else
        stop_spinner "${ERROR}  [✖] Failed: $cmd${RST}"
        failed+=("$name")
      fi
      ;;
    *)
      stop_spinner "${ERROR}  [✖] No install rule for: $cmd${RST}"
      failed+=("$name")
      ;;
    esac
    sleep 0.5
  done

  if [[ ${#failed[@]} -eq 0 ]]; then
    echo -e "${OPTION} [✓] All missing dependencies installed!${RST}"
  else
    echo -e "${ERROR} [✖] Failed to install: ${failed[*]}${RST}"
    sleep 2
    show_install_commands "${deps[@]}"
  fi

  sleep 2
}
# Special function to install lolcat (tricky on different systems)
install_lolcat() {
  local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

  # Try system package manager first
  case "$pm" in
  apt)
    sudo apt install -y lolcat >/dev/null 2>&1 && return 0
    # Fallback to gem if apt fails
    sudo apt install -y ruby >/dev/null 2>&1 && gem install lolcat 2>/dev/null && return 0
    ;;
  pacman)
    sudo pacman -S --noconfirm lolcat 2>/dev/null && return 0
    ;;
  pkg)
    pkg install -y lolcat >/dev/null 2>&1 && return 0
    # Fallback to gem if pkg fails
    pkg install -y ruby >/dev/null 2>&1 && gem install lolcat 2>/dev/null && return 0
    ;;
  brew)
    brew install lolcat 2>/dev/null && return 0
    ;;
  apk)
    sudo apk add lolcat >/dev/null 2>&1 && return 0
    ;;
  esac

  # Last resort: try gem directly
  if command -v gem >/dev/null 2>&1; then
    gem install lolcat 2>/dev/null && return 0
  fi

  return 1
}
# Generate install hints for multiple package managers
get_install_hints() {
  local cmd="$1"

  case "$cmd" in
  lolcat)
    echo -e "${INFO}[*] Install lolcat on different systems: ${RST}"
    echo -e "${INFO} |"
    echo -e "${INFO} ├─ Debian/Ubuntu:     ${OPTION}sudo apt install lolcat ${RST}"
    echo -e "${INFO} ├─ Arch Linux:        ${OPTION}sudo pacman -S lolcat ${RST}"
    echo -e "${INFO} ├─ Fedora/RHEL:       ${OPTION}sudo dnf install lolcat ${RST}"
    echo -e "${INFO} ├─ openSUSE:          ${OPTION}sudo zypper install lolcat ${RST}"
    echo -e "${INFO} ├─ GNU Guix:          ${OPTION}guix package -i lolcat ${RST}"
    echo -e "${INFO} ├─ Solus:             ${OPTION}sudo eopkg install lolcat ${RST}"
    echo -e "${INFO} ├─ Mageia:            ${OPTION}sudo urpmi lolcat ${RST}"
    echo -e "${INFO} ├─ Slackware:         ${OPTION}sudo slackpkg install lolcat ${RST}"
    echo -e "${INFO} ├─ OpenBSD:           ${OPTION}doas pkg_add lolcat ${RST}"
    echo -e "${INFO} ├─ Alpine Linux:      ${OPTION}sudo apk add lolcat ${RST}"
    echo -e "${INFO} ├─ Void Linux:        ${OPTION}sudo xbps-install -S lolcat ${RST}"
    echo -e "${INFO} ├─ NixOS:             ${OPTION}nix-shell -p lolcat ${RST}"
    echo -e "${INFO} ├─ Gentoo:            ${OPTION}sudo emerge --ask app-misc/lolcat ${RST}"
    echo -e "${INFO} ├─ FreeBSD:           ${OPTION}sudo pkg install lolcat ${RST}"
    echo -e "${INFO} ├─ NetBSD/pkgsrc:     ${OPTION}sudo pkgin install lolcat ${RST}"
    echo -e "${INFO} ├─ macOS (Homebrew):  ${OPTION}brew install lolcat ${RST}"
    echo -e "${INFO} ├─ macOS (MacPorts):  ${OPTION}sudo port install lolcat ${RST}"
    echo -e "${INFO} ├─ Termux:            ${OPTION}pkg install ruby && gem install lolcat ${RST}"
    echo -e "${INFO} ├─ Windows (Choco):   ${OPTION}choco install lolcat ${RST}"
    echo -e "${INFO} ├─ Windows (Scoop):   ${OPTION}scoop install lolcat ${RST}"
    echo -e "${INFO} ├─ Snap:              ${OPTION}sudo snap install lolcat ${RST}"
    echo -e "${INFO} ├─ Flatpak:           ${OPTION}flatpak install flathub com.github.jaseg.lolcat ${RST}"
    echo -e "${INFO} ├─ Ruby Gem:          ${OPTION}gem install lolcat ${RST}"
    echo -e "${INFO} └─ Source/Git:        ${OPTION}git clone https://github.com/busyloop/lolcat && cd lolcat && gem build lolcat.gemspec && gem install lolcat-*.gem ${RST}"
    ;;
  git)
    echo -e "${INFO}[*] Install Git on different systems: ${RST}"
    echo -e "${INFO} |"
    echo -e "${INFO} ├─ Debian/Ubuntu:     ${OPTION}sudo apt install git ${RST}"
    echo -e "${INFO} ├─ Arch Linux:        ${OPTION}sudo pacman -S git ${RST}"
    echo -e "${INFO} ├─ Fedora/RHEL:       ${OPTION}sudo dnf install git ${RST}"
    echo -e "${INFO} ├─ openSUSE:          ${OPTION}sudo zypper install git ${RST}"
    echo -e "${INFO} ├─ Alpine Linux:      ${OPTION}sudo apk add git ${RST}"
    echo -e "${INFO} ├─ GNU Guix:          ${OPTION}guix package -i git ${RST}"
    echo -e "${INFO} ├─ Solus:             ${OPTION}sudo eopkg install git ${RST}"
    echo -e "${INFO} ├─ Mageia:            ${OPTION}sudo urpmi git ${RST}"
    echo -e "${INFO} ├─ Slackware:         ${OPTION}sudo slackpkg install git ${RST}"
    echo -e "${INFO} ├─ OpenBSD:           ${OPTION}doas pkg_add git ${RST}"
    echo -e "${INFO} ├─ Void Linux:        ${OPTION}sudo xbps-install -S git ${RST}"
    echo -e "${INFO} ├─ NixOS:             ${OPTION}nix-shell -p git ${RST}"
    echo -e "${INFO} ├─ Gentoo:            ${OPTION}sudo emerge --ask dev-vcs/git ${RST}"
    echo -e "${INFO} ├─ FreeBSD:           ${OPTION}sudo pkg install git ${RST}"
    echo -e "${INFO} ├─ NetBSD/pkgsrc:     ${OPTION}sudo pkgin install git ${RST}"
    echo -e "${INFO} ├─ macOS (Homebrew):  ${OPTION}brew install git ${RST}"
    echo -e "${INFO} ├─ macOS (MacPorts):  ${OPTION}sudo port install git ${RST}"
    echo -e "${INFO} ├─ Termux:            ${OPTION}pkg install git ${RST}"
    echo -e "${INFO} ├─ Windows (Choco):   ${OPTION}choco install git ${RST}"
    echo -e "${INFO} ├─ Windows (Scoop):   ${OPTION}scoop install git ${RST}"
    echo -e "${INFO} ├─ Windows (winget):  ${OPTION}winget install Git.Git ${RST}"
    echo -e "${INFO} ├─ Snap:              ${OPTION}sudo snap install git ${RST}"
    echo -e "${INFO} ├─ Flatpak:           ${OPTION}flatpak install flathub org.gnome.gitlab.albfan.GitCola ${RST}"
    echo -e "${INFO} └─ Source:            ${OPTION}git clone https://github.com/git/git.git && cd git && make configure && ./configure --prefix=/usr && make all && sudo make install ${RST}"
    ;;
  curl)
    echo -e "${INFO}[*] Install cURL on different systems: ${RST}"
    echo -e "${INFO} |"
    echo -e "${INFO} ├─ Debian/Ubuntu:     ${OPTION}sudo apt install curl ${RST}"
    echo -e "${INFO} ├─ Arch Linux:        ${OPTION}sudo pacman -S curl ${RST}"
    echo -e "${INFO} ├─ Fedora/RHEL:       ${OPTION}sudo dnf install curl ${RST}"
    echo -e "${INFO} ├─ openSUSE:          ${OPTION}sudo zypper install curl ${RST}"
    echo -e "${INFO} ├─ Alpine Linux:      ${OPTION}sudo apk add curl ${RST}"
    echo -e "${INFO} ├─ GNU Guix:          ${OPTION}guix package -i curl ${RST}"
    echo -e "${INFO} ├─ Solus:             ${OPTION}sudo eopkg install curl ${RST}"
    echo -e "${INFO} ├─ Mageia:            ${OPTION}sudo urpmi curl ${RST}"
    echo -e "${INFO} ├─ Slackware:         ${OPTION}sudo slackpkg install curl ${RST}"
    echo -e "${INFO} ├─ OpenBSD:           ${OPTION}doas pkg_add curl ${RST}"
    echo -e "${INFO} ├─ Void Linux:        ${OPTION}sudo xbps-install -S curl ${RST}"
    echo -e "${INFO} ├─ NixOS:             ${OPTION}nix-shell -p curl ${RST}"
    echo -e "${INFO} ├─ Gentoo:            ${OPTION}sudo emerge --ask net-misc/curl ${RST}"
    echo -e "${INFO} ├─ FreeBSD:           ${OPTION}sudo pkg install curl ${RST}"
    echo -e "${INFO} ├─ NetBSD/pkgsrc:     ${OPTION}sudo pkgin install curl ${RST}"
    echo -e "${INFO} ├─ macOS (Homebrew):  ${OPTION}brew install curl ${RST}"
    echo -e "${INFO} ├─ macOS (MacPorts):  ${OPTION}sudo port install curl ${RST}"
    echo -e "${INFO} ├─ Termux:            ${OPTION}pkg install curl ${RST}"
    echo -e "${INFO} ├─ Windows (Choco):   ${OPTION}choco install curl ${RST}"
    echo -e "${INFO} ├─ Windows (Scoop):   ${OPTION}scoop install curl ${RST}"
    echo -e "${INFO} ├─ Windows (winget):  ${OPTION}winget install curl.curl ${RST}"
    echo -e "${INFO} ├─ Snap:              ${OPTION}sudo snap install curl ${RST}"
    echo -e "${INFO} ├─ Flatpak:           ${OPTION}flatpak install flathub org.curl.curl ${RST}"
    echo -e "${INFO} └─ Source:            ${OPTION}git clone https://github.com/curl/curl.git && cd curl && ./buildconf && ./configure && make && sudo make install ${RST}"
    ;;
  crontab)
    echo -e "${INFO}[*] Install crontab on different systems: ${RST}"
    echo -e "${INFO} |"
    echo -e "${INFO} ├─ Debian/Ubuntu:     ${OPTION}sudo apt install cron ${RST}"
    echo -e "${INFO} ├─ Arch Linux:        ${OPTION}sudo pacman -S cronie ${RST}"
    echo -e "${INFO} ├─ Fedora/RHEL:       ${OPTION}sudo dnf install cronie ${RST}"
    echo -e "${INFO} ├─ openSUSE:          ${OPTION}sudo zypper install cronie ${RST}"
    echo -e "${INFO} ├─ Alpine Linux:      ${OPTION}sudo apk add cronie ${RST}"
    echo -e "${INFO} ├─ Void Linux:        ${OPTION}sudo xbps-install -S cronie ${RST}"
    echo -e "${INFO} ├─ NixOS:             ${OPTION}nix-shell -p cron ${RST}"
    echo -e "${INFO} ├─ Gentoo:            ${OPTION}sudo emerge --ask sys-process/cronie ${RST}"
    echo -e "${INFO} ├─ GNU Guix:          ${OPTION}guix package -i mcron ${RST}"
    echo -e "${INFO} ├─ Solus:             ${OPTION}sudo eopkg install cronie ${RST}"
    echo -e "${INFO} ├─ Mageia:            ${OPTION}sudo urpmi cronie ${RST}"
    echo -e "${INFO} ├─ Slackware:         ${OPTION}sudo slackpkg install dcron ${RST}"
    echo -e "${INFO} ├─ FreeBSD:           ${OPTION}sudo pkg install cronie ${RST}"
    echo -e "${INFO} ├─ OpenBSD:           ${OPTION}built-in — enable via: rcctl enable cron ${RST}"
    echo -e "${INFO} ├─ macOS (Homebrew):  ${OPTION}brew install --cask cron ${RST}"
    echo -e "${INFO} ├─ Termux:            ${OPTION}pkg install cronie ${RST}"
    echo -e "${INFO} └─ Windows:           ${OPTION}Use Task Scheduler (no native cron) ${RST}"
    ;;
  *)
    echo -e "${INFO} [*] No hints for:${OPTION} $cmd ${RST}"
    ;;
  esac
}
# Improved show_install_commands
show_install_commands() {
  local deps=("$@")
  local pm="${PRIMARY_PKG_MANAGER:-$(detect_pkg_manager)}"

  echo -e "${BOLD_GREEN}"
  print_box center " [*] Installation Instructions "
  echo -e "${RST}"

  echo -e "${INFO} [*] 📦 Detected package manager: ${OPTION}$pm${RST}\n"

  for dep in "${deps[@]}"; do
    IFS=":" read -r cmd name <<<"$dep"
    echo -e "${BOLD_YELLOW} ▶ ${name}${RST}"
    echo ""
    get_install_hints "$cmd"
    echo ""
  done

  echo -e "${INFO}💡 Tip: Run the script again after installing dependencies${RST}\n"
  echo -e "${BOLD_GREEN}"
  read -p " [*] Press any KEY to exit..."
  clear
  exit 0
}
