#!/usr/bin/env bash
set -euo pipefail
REPO="${DOTFILES_REPO:-https://github.com/xeptor6569/xt-dotfiles}"
xcode-select --install 2>/dev/null || true
command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

brew install --cask iterm2 docker rectangle raycast visual-studio-code font-jetbrains-mono-nerd-font || true

# sane defaults
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.dock autohide -bool true
killall Finder Dock 2>/dev/null || true

[[ -d ~/.xt-dotfiles ]] || git clone --recurse-submodules "$REPO" ~/.xt-dotfiles
~/.xt-dotfiles/install.sh --append
echo "Set your terminal font to 'JetBrainsMono Nerd Font' for icons."
