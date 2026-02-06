#!/bin/bash

# post-install summary pop-up
post_install_summary() {
    log OK "Post-Installation-Summary shown"
    echo ""
    echo -e "${OPT}${BOLD}"
    boxed_text center " [*] Post-Installation Summary" 
    echo -e "${RST}"

    if [ ${#INSTALLED_PKGS[@]} -gt 0 ]; then
        echo -e "${OPT}${BOLD} [*] Installed:${RST}"
         echo ""
        for pkg in "${INSTALLED_PKGS[@]}"; do
            echo -e "   ${OPT}[✓]${RST} $pkg"
        done
        echo ""
    fi

    if [ ${#SKIPPED_PKGS[@]} -gt 0 ]; then
        echo -e "${INFO}${BOLD} [*] Skipped:${RST}"
         echo ""
        for pkg in "${SKIPPED_PKGS[@]}"; do
            echo -e "   ${BLUE}[→]${RST} $pkg"
        done
        echo ""
    fi

    if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
        echo -e "${ERR}${BOLD} [!] Failed:${RST}"
         echo ""
        for pkg in "${FAILED_PKGS[@]}"; do
            echo -e "   ${ERR}[✗]${RST} $pkg"
        done
        echo ""
    fi
}
