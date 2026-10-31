#!/usr/bin/env bash
# Remove dotfiles wiring, restore most recent backups. Packages are left installed.
set -euo pipefail
DOTFILES="${DOTFILES:-$HOME/.xt-dotfiles}"
declare -A PATTERN=(
  ["$HOME/.zshrc"]='xt-dotfiles/shell/common.sh'
  ["$HOME/.bashrc"]='xt-dotfiles/shell/common.sh'
  ["$HOME/.tmux.conf"]='xt-dotfiles/tmux.conf'
  ["$HOME/.gitconfig"]='xt-dotfiles/gitconfig'
  ["$HOME/.ssh/config"]='xt-dotfiles/ssh_config'
)
for rc in "${!PATTERN[@]}"; do
  if [[ -L $rc && $(readlink "$rc") == "$DOTFILES/"* ]]; then
    rm "$rc"; echo "unlinked $rc"
    latest=$(ls -t "$rc".bak.* 2>/dev/null | head -1 || true)
    [[ -n $latest ]] && { mv "$latest" "$rc"; echo "restored $rc from $(basename "$latest")"; }
  elif [[ -f $rc ]] && grep -q "${PATTERN[$rc]}" "$rc"; then
    # strip the include/source line and our "# dotfiles" marker
    sed -i.tmp -e "\#${PATTERN[$rc]}#d" -e '/^# dotfiles$/d' "$rc" && rm -f "$rc.tmp"
    echo "removed include from $rc"
  fi
done
echo "Done. Shell default unchanged — revert with: chsh -s /bin/bash"
echo "Remove the repo with: rm -rf $DOTFILES"
