#!/data/data/com.termux/files/usr/bin/bash
# Apply professional messaging helpers to all .sh files in the project.
# Replaces raw echo/printf statements that use colour variables with calls to
# msg_success, msg_error, msg_info, or msg_warning.

replace_in_file() {
  local file="$1"
  # Use perl for in‑place regex replacement. Preserve indentation.
  perl -0777 -i -pe '
    # Success messages: ${OPTION}[✓] <text>${RST}
    s{(^[ \t]*echo -e "\$\{OPTION\}\[✓\] (.*?)\$\{RST\}")}{
        my $indent = $1 =~ /^(\s*)/ ? $1 : "";
        my $msg = $2;
        $indent . "msg_success \"$msg\""
    }gem;
    # Error messages: ${ERROR}[!] <text>${RST}
    s{(^[ \t]*echo -e "\$\{ERROR\}\[!\] (.*?)\$\{RST\}")}{
        my $indent = $1 =~ /^(\s*)/ ? $1 : "";
        my $msg = $2;
        $indent . "msg_error \"$msg\""
    }gem;
    # Info messages using ${INFO} or ${OPTION} with asterisk or generic info marker
    s{(^[ \t]*echo -e "\$\{INFO\}\[\*\] (.*?)\$\{RST\}")}{
        my $indent = $1 =~ /^(\s*)/ ? $1 : "";
        my $msg = $2;
        $indent . "msg_info \"$msg\""
    }gem;
    s{(^[ \t]*echo -e "\$\{OPTION\}\[\*\] (.*?)\$\{RST\}")}{
        my $indent = $1 =~ /^(\s*)/ ? $1 : "";
        my $msg = $2;
        $indent . "msg_info \"$msg\""
    }gem;
    # Warning messages: ${ERROR}[!] used for warnings in many scripts – map to msg_warning
    s{(^[ \t]*echo -e "\$\{ERROR\}\[!\] (.*?)\$\{RST\}")}{
        my $indent = $1 =~ /^(\s*)/ ? $1 : "";
        my $msg = $2;
        $indent . "msg_warning \"$msg\""
    }gem;
  ' "$file"
}

export -f replace_in_file

# Find all .sh files in the repository (excluding generated files if any)
find . -type f -name "*.sh" | while read -r f; do
  replace_in_file "$f"
done

echo "Message helper replacement completed."
