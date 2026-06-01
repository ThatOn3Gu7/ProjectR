#!/bin/bash

# --- 1. ERROR ANALYSIS ENGINE (The Brain) ---
analyze_error() {
    local err_file="$1"
    
    # Safety check: if log is missing, return generic error
    if [ ! -f "$err_file" ]; then
        echo "Unknown Error (Log file missing)"
        return
    fi

    # 1. Network Issues
    if grep -iqE "could not resolve host|temporary failure in name resolution" "$err_file"; then
        echo "Network Error: DNS Resolution failed. Check internet connection."
        return
    fi
    if grep -iqE "connection refused|network is unreachable|connect to host" "$err_file"; then
        echo "Network Error: Host unreachable or connection blocked."
        return
    fi
    if grep -iqE "time(out|ed out)" "$err_file"; then
        echo "Network Error: Connection timed out."
        return
    fi
    
    # 2. Package Manager Issues (apt, pkg, dnf)
    if grep -iqE "unable to locate package|no package '.*' found" "$err_file"; then
        echo "Package Error: The specified package could not be found."
        return
    fi
    if grep -iqE "could not get lock|resource temporarily unavailable" "$err_file"; then
        echo "System Busy: Another installer is running (apt/dpkg lock)."
        return
    fi
    if grep -iqE "permission denied|are you root" "$err_file"; then
        echo "Permission Error: Run with sudo or as root."
        return
    fi
    if grep -iqE "dpkg was interrupted" "$err_file"; then
        echo "System Error: Previous installation failed. Run 'dpkg --configure -a'."
        return
    fi

    # 3. Fallback: Smart Tail
    # Get the last non-empty line that isn't just whitespace
    local last_line
    last_line=$(grep -v '^\s*$' "$err_file" | tail -n 1 | tr -cd '[:print:]')
    echo "${last_line:-Unknown error occurred (Check logs)}"
}

# --- 2. PROGRESS FUNCTION (The Visuals) ---
progress_run() {
    local run_msg="$1"
    local success_msg="$2"
    shift 2
    local cmd=("$@")
    if declare -f log >/dev/null 2>&1; then
        log INFO "START progress: $run_msg :: $(projectr_command_string "${cmd[@]}" 2>/dev/null || printf '%s' "${cmd[*]}")" "progress"
    fi
    # Local Colors
    local C_RESET="\033[0m"
    local C_BLUE="\033[1;34m"
    local C_GREEN="\033[1;32m"
    local C_RED="\033[1;31m"
    
    local tmp_out tmp_exit
    tmp_out=$(mktemp) || { echo "ERROR
    : Failed to create temp file"; return 1; }
    tmp_exit=$(mktemp) || { rm -f "$tmp_out"; return 1; }

    # ── STEP 1: Save whatever trap was set before we got here ─────────────
    # trap -p INT prints the current INT handler as a string you can re-eval.
    # We save it NOW, before we overwrite it.
    local old_trap
    old_trap=$(trap -p INT)

    local interrupted=0
    # ── STEP 2: Set OUR trap, overwriting the previous one ────────────────
    trap 'interrupted=1' INT

    local pct=0
    local start_time
    start_time=$(date +%s)

    safe_tput civis

    (
        "${cmd[@]}" >"$tmp_out" 2>&1
        echo $? >"$tmp_exit"
    ) &
    local pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        if [ "$interrupted" -eq 1 ]; then
            kill "$pid" 2>/dev/null
            break
        fi

        # 2. Fake Progress Logic (Asymptotic: fast start, slows at end)
        if (( pct < 50 )); then
            pct=$((pct + 5))
        elif (( pct < 98 )); then
             pct=$((pct + 1))
        fi

        # 3. Time Calculation
        local elapsed=$(( $(date +%s) - start_time ))
        local mm=$(( elapsed / 60 ))
        local ss=$(( elapsed % 60 ))
        local time_str=$(printf "%02d:%02d" "$mm" "$ss")

        # 4. Bar Rendering
        local cols=$(safe_tput cols)
        # Calculate available width dynamically
        local bar_width=$(( cols - ${#run_msg} - ${#time_str} - 18 ))
        (( bar_width < 20 )) && bar_width=20

        local filled=$(( pct * bar_width / 100 ))
        local empty=$(( bar_width - filled ))
        
        # Using standard # and - for maximum compatibility (Termux safe)
        local bar="$(printf "%${filled}s" | tr ' ' '#')"
        bar+="$(printf "%${empty}s" | tr ' ' '-')"

        # Print the line
        printf "\r${C_BLUE}[*]${C_RESET} %s [%s] %3d%% %s" \
            "$run_msg" "$bar" "$pct" "$time_str"

        sleep 0.2
    done


    # Wait for process to settle
    wait "$pid" 2>/dev/null
    local exit_code
    if [[ "$interrupted" -eq 1 ]]; then
        exit_code=130
     else
        exit_code=$(cat "$tmp_exit" 2>/dev/null)
        [[ "$exit_code" =~ ^[0-9]+$ ]] || exit_code=1
    fi

    # --- Finalize Bar (100%) ---
    local elapsed=$(( $(date +%s) - start_time ))
    local mm=$(( elapsed / 60 ))
    local ss=$(( elapsed % 60 ))
    local time_str=$(printf "%02d:%02d" "$mm" "$ss")
    local cols=$(safe_tput cols)
    local bar_width=$(( cols - ${#run_msg} - ${#time_str} - 18 ))
    (( bar_width < 20 )) && bar_width=20
    local bar="$(printf "%${bar_width}s" | tr ' ' '#')"

    # Clear line and print final 100% state
    printf "\r${C_BLUE}[*]${C_RESET} %s [%s] 100%% %s\n" \
        "$run_msg" "$bar" "$time_str"

    # --- Result Handling ---
    if grep -qiE "up to date|0 upgraded|nothing to do" "$tmp_out"; then
        exit_code=0
    fi

    echo "" # Spacer

    if [ "$interrupted" -eq 1 ]; then
        echo -e "${C_RED}  [x] Interrupted while${C_RESET} : $run_msg"
        echo -e "   └─▶ Reason : User Cancelled (Ctrl+C)"
        log_warn "Interrupted progress: $run_msg" "progress"
        exit_code=130
    elif [ "$exit_code" -eq 0 ]; then
        echo -e "${C_GREEN}  [✓] Success at${C_RESET} : $run_msg"
        if [ -n "$success_msg" ]; then
            echo -e "   └─▶ Result : $success_msg"
        fi
        log_ok "Progress succeeded: $run_msg${success_msg:+ :: $success_msg}" "progress"
    else
        # HERE IS THE MAGIC: We call the error analyzer
        local failure_reason=$(analyze_error "$tmp_out")
        
        echo -e "${C_RED}  [x] Failed to${C_RESET} : $run_msg"
        echo -e "   └─▶ Reason : $failure_reason"
        log_fail "Progress failed: $run_msg :: $failure_reason" "progress"
        projectr_log_file_excerpt FAIL "$tmp_out" "progress" 20
    fi

    safe_tput cnorm
    rm -f "$tmp_out" "$tmp_exit"

    # ── STEP 3: Restore the trap we saved at the top ──────────────────────
    # This MUST be the last thing before return so that after progress_run
    # finishes, Ctrl+C goes back to calling graceful_exit in main.sh.
    if [[ -n "$old_trap" ]]; then
        eval "$old_trap"
    else
        # If there was no previous trap, just reset INT to default behaviour
        trap - INT
    fi

    return "$exit_code"
}

