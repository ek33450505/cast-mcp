#!/bin/bash
# uninstall.sh — remove cast-mcp launcher + server from common install locations.
set -euo pipefail

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_RESET=''
fi
_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

printf "\n${C_BOLD}cast-mcp uninstaller${C_RESET}\n"
printf "═════════════════════════════════════════════\n\n"

_step "Removing launcher..."
for d in "$HOME/.local/bin" "/usr/local/bin" "/opt/homebrew/bin"; do
  if [ -f "$d/cast-mcp" ]; then
    rm -f "$d/cast-mcp" && _ok "removed $d/cast-mcp"
  fi
done

_step "Removing server lib..."
LIB_TARGET="${CAST_LIB_DIR:-$HOME/.local/lib/cast-mcp}"
if [ -d "$LIB_TARGET" ]; then
  rm -f "$LIB_TARGET/cast-mcp-server.py" "$LIB_TARGET/VERSION"
  rmdir "$LIB_TARGET" 2>/dev/null || true
  _ok "removed $LIB_TARGET"
fi

printf "\n${C_GREEN}cast-mcp uninstalled.${C_RESET}\n\n"
exit 0
