#!/usr/bin/env bash
# Kept so existing one-liners keep working; the script now covers Debian and Ubuntu.
set -euo pipefail
REPO="${DOTFILES_REPO:-https://github.com/xeptor6569/xt-dotfiles}"
RAW="${REPO/github.com/raw.githubusercontent.com}/main/firstboot/linux-firstboot.sh"
if [[ -f $(dirname "$0")/linux-firstboot.sh ]]; then exec bash "$(dirname "$0")/linux-firstboot.sh" "$@"; fi
curl -fsSL "$RAW" | bash -s -- "$@"
