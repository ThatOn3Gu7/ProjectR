#!/data/data/com.termux/files/usr/bin/bash
# Apply professional messaging helpers to all .sh files.
# Replaces raw echo statements with calls to msg_success, msg_error,
# msg_info, and msg_warning.

replace_file() {
    local f="$1"

    # Success messages: ${OPTION}[✓] MESSAGE${RST}
    sed -i -E 's/^([[:space:]]*)echo -e "\${OPTION}\[✓\] (.*)\${RST}"/\1msg_success "\2"/' "$f"

    # Error messages: ${ERROR}[!] MESSAGE${RST}
    sed -i -E 's/^([[:space:]]*)echo -e "\${ERROR}\[!\] (.*)\${RST}"/\1msg_error "\2"/' "$f"

    # Info messages using ${OPTION}[*] or ${INFO}[*] or ${BOLD_GREEN}[*]
    sed -i -E 's/^([[:space:]]*)echo -e "\${OPTION}\[\*\] (.*)\${RST}"/\1msg_info "\2"/' "$f"
    sed -i -E 's/^([[:space:]]*)echo -e "\${INFO}\[\*\] (.*)\${RST}"/\1msg_info "\2"/' "$f"
    sed -i -E 's/^([[:space:]]*)echo -e "\${BOLD_GREEN}\[\*\] (.*)\${RST}"/\1msg_info "\2"/' "$f"

    # Warning messages (same pattern as error but we map to warning)
    # First replace any still‑existing msg_error that originated from a warning.
    sed -i -E 's/^([[:space:]]*)msg_error "(.*)"/\1msg_warning "\2"/' "$f"
}

export -f replace_file

find . -type f -name "*.sh" | while read -r file; do
    replace_file "$file"
done

echo "Helper replacement completed."
