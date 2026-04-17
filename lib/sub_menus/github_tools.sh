#!/bin/bash

github_tools() {
 while true; do
  clear
  cat <<"EOF" #| lolcat

# Future ASCII art is to be here too

EOF

echo -e "${OPT}${BOLD}"
 boxed_text left "[*] Clone a tool form github you want:"
  echo ""
  echo -e "${OPT}    [01] OpenCode - A codeing againt ${RST}"
 echo ""
  echo -e "${ERR}${BOLD}    [b] Back to main-menu ${RST}"
 echo ""
  echo -ne "${INFO}${BOLD} [*] Chose what to clone: ${RST}"
   read clone_chose
  case "$clone_chose" in
    01|1) echo " [*] Cloneing OpenCode"
      sleep 5
    ;;
    b|B) return
    ;;
    e|E) graceful_exit
    ;;
    *) echo -e "${ERR}${BOLD}  [!] Invalid Option: $clone_chose ..${RST}" 
    ;;
  esac
  
 done 
}
