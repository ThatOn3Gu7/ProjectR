#!/bin/bash

# post-install summary pop-up
post_install_summary() {
    log OK "Post-Installation-Summary shown"
    echo ""
    echo -e "${OPT}${BOLD}"
    boxed_text center " [*] Post-Installation Summary" 
    echo -e "${RST}"

    if [ ${#INSTALLED_PKGS[@]} -gt 0 ]; then
        echo -e "${SUCCESS}${BOLD}Installed:${RST}"
        for pkg in "${INSTALLED_PKGS[@]}"; do
            echo " [ ✓ ] $pkg"
        done
        echo ""
    fi

    if [ ${#SKIPPED_PKGS[@]} -gt 0 ]; then
        echo -e "${OPT}${BOLD}Skipped:${RST}"
        for pkg in "${SKIPPED_PKGS[@]}"; do
            echo " [ → ] $pkg"
        done
        echo ""
    fi

    if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
        echo -e "${ERR}${BOLD}Failed:${RST}"
        for pkg in "${FAILED_PKGS[@]}"; do
            echo " [ ✗ ] $pkg"
        done
        echo ""
    fi
}
