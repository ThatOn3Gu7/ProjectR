#!/bin/bash
# --- Semantic aliases (makes scripts readable) ---
INFO="${BRIGHT_YELLOW}"
OPTION="${BRIGHT_GREEN}"
ERROR="${BRIGHT_RED}"
BARR="${BRIGHT_MAGENTA}"
SUCCESS="${BRIGHT_GREEN}"
WARN="${BRIGHT_YELLOW}"

# --- Reset ---
RST="\e[0m"

# --- Regular Colors ---
BLACK="\e[0;30m"
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
PURPLE="\e[0;35m"
CYAN="\e[0;36m"
WHITE="\e[0;37m"

# --- Bold Colors ---
BOLD_BLACK="\e[1;30m"
BOLD_RED="\e[1;31m"
BOLD_GREEN="\e[1;32m"
BOLD_YELLOW="\e[1;33m"
BOLD_BLUE="\e[1;34m"
BOLD_PURPLE="\e[1;35m"
BOLD_CYAN="\e[1;36m"
BOLD_WHITE="\e[1;37m"

# --- Underline Colors ---
ULINE_BLACK="\e[4;30m"
ULINE_RED="\e[4;31m"
ULINE_GREEN="\e[4;32m"
ULINE_YELLOW="\e[4;33m"
ULINE_BLUE="\e[4;34m"
ULINE_PURPLE="\e[4;35m"
ULINE_CYAN="\e[4;36m"
ULINE_WHITE="\e[4;37m"

# --- Background Colors ---
BG_BLACK="\e[40m"
BG_RED="\e[41m"
BG_GREEN="\e[42m"
BG_YELLOW="\e[43m"
BG_BLUE="\e[44m"
BG_PURPLE="\e[45m"
BG_CYAN="\e[46m"
BG_WHITE="\e[47m"

# --- High Intensity (Bright) Foreground ---
BRIGHT_BLACK="\e[0;90m"
BRIGHT_RED="\e[0;91m"
BRIGHT_GREEN="\e[0;92m"
BRIGHT_YELLOW="\e[0;93m"
BRIGHT_BLUE="\e[0;94m"
BRIGHT_PURPLE="\e[0;95m"
BRIGHT_CYAN="\e[0;96m"
BRIGHT_WHITE="\e[0;97m"

# --- Bold High Intensity ---
BOLD_BRIGHT_BLACK="\e[1;90m"
BOLD_BRIGHT_RED="\e[1;91m"
BOLD_BRIGHT_GREEN="\e[1;92m"
BOLD_BRIGHT_YELLOW="\e[1;93m"
BOLD_BRIGHT_BLUE="\e[1;94m"
BOLD_BRIGHT_PURPLE="\e[1;95m"
BOLD_BRIGHT_CYAN="\e[1;96m"
BOLD_BRIGHT_WHITE="\e[1;97m"

# --- High Intensity Backgrounds ---
BG_BRIGHT_BLACK="\e[0;100m"
BG_BRIGHT_RED="\e[0;101m"
BG_BRIGHT_GREEN="\e[0;102m"
BG_BRIGHT_YELLOW="\e[0;103m"
BG_BRIGHT_BLUE="\e[0;104m"
BG_BRIGHT_PURPLE="\e[0;105m"
BG_BRIGHT_CYAN="\e[0;106m"
BG_BRIGHT_WHITE="\e[0;107m"

# --- Text Styles (not color-specific) ---
BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
BLINK="\e[5m"          # use sparingly
REVERSE="\e[7m"        # swap foreground/background
HIDDEN="\e[8m"
STRIKETHROUGH="\e[9m"

# If you want BRIGHT_MAGENTA (was missing from your original):
BRIGHT_MAGENTA="\e[0;95m"   # purple/bright magenta
BOLD_BRIGHT_MAGENTA="\e[1;95m"
