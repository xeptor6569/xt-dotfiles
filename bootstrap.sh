#!/usr/bin/env bash
# One-liner entry point:
#   curl -fsSL https://raw.githubusercontent.com/xeptor669/xt-dotfiles/main/bootstrap.sh | bash -s -- [install.sh args]
set -euo pipefail
REPO="${DOTFILES_REPO:-https://github.com/xeptor6569/xt-dotfiles}"
DOTFILES="${DOTFILES:-$HOME/.xt-dotfiles}"

if ! command -v git >/dev/null; then
  if command -v apt-get >/dev/null; then sudo apt-get update -qq && sudo apt-get install -y -qq git
  elif command -v brew >/dev/null;    then brew install git
  else echo "git is required"; exit 1; fi
fi

if [[ -d $DOTFILES/.git ]]; then
  git -C "$DOTFILES" pull --ff-only
else
  git clone --recurse-submodules "$REPO" "$DOTFILES"
fi
exec "$DOTFILES/install.sh" "$@"