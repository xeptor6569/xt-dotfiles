#!/usr/bin/env bash
# Run the installer in a throwaway Debian 13 container, then drop into zsh.
#   test/docker-test.sh            # fresh box, --link
#   test/docker-test.sh existing   # simulate a box with an existing .zshrc, --append
set -euo pipefail
DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-fresh}"
# Repo is mounted read-only at /src and copied to a writable location, so git
# submodule updates and chmod work without touching the host checkout.
PRE='apt-get update -qq && apt-get install -y -qq sudo git curl ca-certificates rsync >/dev/null && rsync -a /src/ /root/.xt-dotfiles/'
case "$MODE" in
  fresh)    CMD="$PRE && /root/.xt-dotfiles/install.sh --yes --link --no-chsh && exec zsh -l" ;;
  existing) CMD="$PRE && echo 'alias ll=\"echo OLD\"' > /root/.zshrc && /root/.xt-dotfiles/install.sh --yes --append --no-chsh && exec zsh -l" ;;
  *) echo "usage: $0 [fresh|existing]"; exit 1 ;;
esac
docker run --rm -it -v "$DOTFILES:/src:ro" -e DOTFILES=/root/.xt-dotfiles -e USER=root debian:13 bash -c "$CMD"
