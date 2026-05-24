#!/bin/bash

post_install_summary() {
    log OK "Post-Installation-Summary shown"
    
    echo ""
    
    # -- TITLE BOX --
    print_titled_box --align center \
        "  [*] Post-Installation-Summary" \
        "Installation finished at $(date '+%H:%M:%S')"
    
    echo ""
    
    # -- INSTALLED SECTION --
    if [ ${#INSTALLED_PKGS[@]} -gt 0 ]; then
        local installed_display=()
        for pkg in "${INSTALLED_PKGS[@]}"; do
            # Clean up package description
            local clean_pkg="${pkg%,}"
            installed_display+=("[→] $clean_pkg")
        done
        
        print_list_box "center" "[✓] INSTALLED SUCCESSFULLY" "${installed_display[@]}"
        echo ""
    fi
    
    # -- SKIPPED SECTION --
    if [ ${#SKIPPED_PKGS[@]} -gt 0 ]; then
        local skipped_display=()
        for pkg in "${SKIPPED_PKGS[@]}"; do
            # Clean up package description
            local clean_pkg="${pkg%,}"
            skipped_display+=("[→] $clean_pkg")
        done
        
        print_list_box "left" "[✓] ALREADY INSTALLED (SKIPPED)" "${skipped_display[@]}"
        echo ""
    fi
    
    # -- FAILED SECTION --
    if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
        local failed_display=()
        for pkg in "${FAILED_PKGS[@]}"; do
            # Clean up package description
            local clean_pkg="${pkg%,}"
            failed_display+=("[→] $clean_pkg")
        done
        
        print_list_box "center" "[✗] FAILED TO INSTALL" "${failed_display[@]}"
        echo ""
    fi
    
    # -- STATISTICS BOX --
    local total=$(( ${#INSTALLED_PKGS[@]} + ${#SKIPPED_PKGS[@]} + ${#FAILED_PKGS[@]} ))
    
    print_titled_box --align center \
        " [*] Installation Statistics" \
        "" \
        "● Total packages processed: $total" \
        "● Successfully installed: ${#INSTALLED_PKGS[@]}" \
        "● Already installed: ${#SKIPPED_PKGS[@]}" \
        "● Failed to install: ${#FAILED_PKGS[@]}"
}
