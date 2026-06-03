#!/bin/bash

# Presets are grouped by practical category and reference command keys from
# lib/data/tools.sh. install_preset_by_names resolves each key against TOOLS.
PRESET_MINIMAL_CMDS=(
  git curl wget bat jq yq ripgrep fd tree htop btop fish nano micro ssh
  neofetch duf ncdu lsd eza broot zoxide fzf tldr
)

PRESET_DEV_CMDS=(
  git npm python3 pipx go rustup cargo lua ruby php java deno bun pnpm yarn
  fzf tldr zsh nvim helix tmux lazygit gh yazi ranger direnv make cmake ninja
  gcc clang gdb shellcheck shfmt bats just task hyperfine watchexec entr code-server
)

PRESET_FUN_CMDS=(
  sl neofetch cbonsai cpufetch tty-clock pipes.sh speedtest-go cacafire ani-cli
  asciiquarium chafa figlet toilet lolcat cmatrix nyancat fortune cowsay rig
  moon-buggy nethack 2048 vitetris
)

PRESET_NETWORK_CMDS=(
  nmap mosh autossh socat netcat tcpdump traceroute mtr iperf3 whois dnsutils dog
  httpie xh aria2c curl wget speedtest-go weechat irssi mutt msmtp neomutt
)

PRESET_SECURITY_CMDS=(
  openssl gpg age pass nmap tcpdump wireshark testdisk rkhunter lynis ufw fail2ban-client
  john hashcat hydra sqlmap nikto gobuster ffuf zap-baseline.py binwalk radare2 ghidra
)

PRESET_OSINT_CMDS=(
  holehe whois exiftool amass theHarvester sherlock maigret subfinder assetfinder waybackurls
)

PRESET_CLOUD_CONTAINER_CMDS=(
  rclone restic borg aws az gcloud terraform ansible vagrant docker docker-compose podman
  buildah skopeo kubectl helm k9s minikube kind
)

PRESET_DATA_DATABASE_CMDS=(
  jq yq csvkit visidata duckdb gnuplot postgres psql mysql mariadb sqlite3 redis-server
  mongosh pgcli mycli litecli
)

PRESET_MEDIA_DOCS_CMDS=(
  yt-dlp ffmpeg imagemagick chafa pandoc tectonic latexmk mdbook hugo jekyll mkdocs
  glow slides lynx w3m elinks newsboat
)

PRESET_MOBILE_AI_CMDS=(
  adb apktool scrcpy termux-api-start ollama mods aichat tgpt fabric
)

# Registry used by the preset menu. Format: id|Title|Description|array_name
PRESET_MENU_ITEMS=(
  "1|Minimal tools|For beginners and clean base systems|PRESET_MINIMAL_CMDS"
  "2|Developer tools|Full professional developer workspace|PRESET_DEV_CMDS"
  "3|Fun tools|Games, animations, and terminal toys|PRESET_FUN_CMDS"
  "4|Network tools|Diagnostics, transfer, DNS, and remote access|PRESET_NETWORK_CMDS"
  "5|Security tools|Audit, recovery, and web security utilities|PRESET_SECURITY_CMDS"
  "6|OSINT tools|Username, domain, metadata, and recon helpers|PRESET_OSINT_CMDS"
  "7|Cloud and containers|Cloud CLIs, automation, Docker, and Kubernetes|PRESET_CLOUD_CONTAINER_CMDS"
  "8|Data and databases|Data wrangling plus SQL and NoSQL clients|PRESET_DATA_DATABASE_CMDS"
  "9|Media and docs|Media processing, static sites, and document tools|PRESET_MEDIA_DOCS_CMDS"
  "10|Mobile and AI|Android utilities and terminal AI clients|PRESET_MOBILE_AI_CMDS"
)
