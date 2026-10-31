#!/usr/bin/env bash
# Terminal QoL bootstrap — Debian 13 + macOS. Idempotent; safe on existing systems.
#
# Usage: install.sh [--yes] [--dry-run] [--append|--link] [--no-packages] [--no-chsh]
#   --yes          non-interactive, accept defaults
#   --dry-run      print actions, change nothing
#   --append       keep existing rc/config files, add one source/include line (default on existing files)
#   --link         back up existing files and replace with symlinks
#   --no-packages  skip package installation
#   --no-chsh      never change the default shell
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.xt-dotfiles}"
OS="$(uname -s)"
YES=0 DRY=0 PKGS=1 CHSH=1 RCMODE=""
for a in "$@"; do case "$a" in
  --yes|-y) YES=1;; --dry-run|-n) DRY=1;; --append) RCMODE=append;; --link) RCMODE=link;;
  --no-packages) PKGS=0;; --no-chsh) CHSH=0;;
  -h|--help) sed -n '2,10p' "$0"; exit 0;;
  *) echo "unknown arg: $a"; exit 1;;
esac; done

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
run()  { if (( DRY )); then printf '\033[2m[dry] %s\033[0m\n' "$*"; else "$@"; fi; }

ask() {  # ask "Question" [y|n] -> 0 = yes. --yes takes default.
  local q="$1" def="${2:-y}" ans
  (( YES )) && { [[ $def == y ]]; return; }
  if [[ $def == y ]]; then read -rp "$q [Y/n] " ans </dev/tty; [[ -z $ans || $ans =~ ^[Yy] ]]
  else                    read -rp "$q [y/N] " ans </dev/tty; [[ $ans =~ ^[Yy] ]]; fi
}
choose() {  # choose "Question" default opt1 opt2 ... -> echoes first word of selection
  local q="$1" def="$2"; shift 2; local i=1 o ans
  (( YES )) && { echo "$def"; return; }
  for o in "$@"; do printf '  %d) %s\n' "$i" "$o" >&2; ((i++)); done
  read -rp "$q [$def] " ans </dev/tty
  [[ -z $ans ]] && { echo "$def"; return; }
  if [[ $ans =~ ^[0-9]+$ ]] && (( ans>=1 && ans<=$# )); then ans="${!ans}"; fi
  echo "${ans%% *}"
}
append_line() {  # append_line <file>  [--prepend]
  local f="$1" line="$2"
  grep -qF -- "$line" "$f" 2>/dev/null && return 0
  if [[ ${3:-} == --prepend ]]; then
    run bash -c "printf '%s\n\n' '$line' | cat - '$f' > '$f.tmp' && mv '$f.tmp' '$f'"
  else
    run bash -c "printf '\n# dotfiles\n%s\n' '$line' >> '$f'"
  fi
}

# ---------- Preflight ----------
log "Host: $(hostname) ($OS)   User: $USER   Shell: $SHELL   Mode: ${RCMODE:-ask}$( ((DRY)) && echo ' DRY-RUN')"
for t in zsh eza bat fd rg fzf zoxide starship tmux btop delta docker; do
  if command -v "$t" >/dev/null; then printf '  ✔ %-9s %s\n' "$t" "$(command -v "$t")"; else printf '  ✘ %-9s\n' "$t"; fi
done
for rc in ~/.zshrc ~/.bashrc ~/.tmux.conf ~/.gitconfig ~/.ssh/config; do
  if   [[ -L $rc ]]; then printf '  %s -> %s\n' "$rc" "$(readlink "$rc")"
  elif [[ -f $rc ]]; then printf '  %s exists (%s lines)\n' "$rc" "$(wc -l <"$rc" | tr -d ' ')"
  else                    printf '  %s absent\n' "$rc"; fi
done
echo; ask "Proceed?" y || exit 0

# ---------- Packages ----------
DEB_PKGS=(zsh git curl wget unzip tmux htop btop ncdu duf tree jq eza bat fd-find ripgrep fzf
          zoxide git-delta tealdeer fastfetch micro rsync ca-certificates gnupg locales needrestart)
BREW_PKGS=(zsh git curl wget tmux htop btop ncdu duf tree jq eza bat fd ripgrep fzf zoxide
           git-delta tlrc fastfetch micro coreutils gnu-sed starship lazygit lazydocker)

if (( PKGS )) && ask "Install/update CLI packages?" y; then
  case "$OS" in
    Linux)
      run sudo apt-get update -qq
      missing=(); for p in "${DEB_PKGS[@]}"; do dpkg -s "$p" &>/dev/null || missing+=("$p"); done
      if (( ${#missing[@]} )); then
        log "Installing: ${missing[*]}"
        for p in "${missing[@]}"; do run sudo apt-get install -y -qq "$p" 2>/dev/null || warn "skipped $p (not in repo)"; done
      else log "All apt packages present"; fi
      run mkdir -p "$HOME/.local/bin"
      [[ -x /usr/bin/batcat && ! -e $HOME/.local/bin/bat ]] && run ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
      [[ -x /usr/bin/fdfind && ! -e $HOME/.local/bin/fd  ]] && run ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
      if ! command -v starship >/dev/null && ask "Install starship prompt?" y; then
        run bash -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"'
      fi
      if ! command -v lazydocker >/dev/null && ask "Install lazydocker (docker TUI)?" y; then
        run bash -c 'curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR="$HOME/.local/bin" bash'
      fi ;;
    Darwin)
      if ! command -v brew >/dev/null && ask "Install Homebrew?" y; then
        run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
      fi
      missing=(); for p in "${BREW_PKGS[@]}"; do brew list --formula "$p" &>/dev/null || missing+=("$p"); done
      if (( ${#missing[@]} )); then run brew install "${missing[@]}"; else log "All brew packages present"; fi
      brew list --cask font-jetbrains-mono-nerd-font &>/dev/null \
        || { ask "Install JetBrains Mono Nerd Font?" y && run brew install --cask font-jetbrains-mono-nerd-font; } ;;
    *) warn "Unsupported OS: $OS — skipping packages" ;;
  esac
fi

# ---------- Plugins (submodules, pinned) ----------
if [[ -d $DOTFILES/.git ]]; then
  run git -C "$DOTFILES" submodule update --init --recursive -q || warn "submodule update failed"
fi
# Fallback if repo was copied without .git
if [[ ! -f $DOTFILES/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  run git clone -q --depth 1 -b v0.7.1 https://github.com/zsh-users/zsh-autosuggestions "$DOTFILES/plugins/zsh-autosuggestions"
  run git clone -q --depth 1 -b 0.8.0  https://github.com/zsh-users/zsh-syntax-highlighting "$DOTFILES/plugins/zsh-syntax-highlighting"
fi

# ---------- Config wiring ----------
# wire <src> <dst> <append-line> [--prepend]
wire() {
  local src="$1" dst="$2" line="$3" pre="${4:-}"
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then log "$dst already linked"; return; fi
  if [[ -f $dst ]] && grep -qF -- "$line" "$dst"; then log "$dst already includes dotfiles"; return; fi
  local mode="$RCMODE"
  if [[ -z $mode ]]; then
    if [[ -s $dst ]]; then
      echo; warn "$dst exists with content."
      mode=$(choose "How to handle $dst?" append \
        "append  (keep your file, add one include line — recommended on existing systems)" \
        "link    (back up your file, replace with dotfiles version)" \
        "skip")
    else mode=link; fi
  fi
  case "$mode" in
    append) [[ -f $dst ]] || run touch "$dst"; append_line "$dst" "$line" $pre; log "appended include to $dst" ;;
    link)   [[ -e $dst && ! -L $dst ]] && { run mv "$dst" "$dst.bak.$(date +%s)"; warn "backed up $dst"; }
            run ln -sfn "$src" "$dst"; log "linked $dst" ;;
    *)      warn "left $dst alone" ;;
  esac
}

SRC_LINE='[[ -f "$HOME/.xt-dotfiles/shell/common.sh" ]] && source "$HOME/.xt-dotfiles/shell/common.sh"'

if command -v zsh >/dev/null && ask "Configure zsh?" y; then
  wire "$DOTFILES/zshrc" "$HOME/.zshrc" "$SRC_LINE"
  ZSH_PATH="$(command -v zsh)"
  if (( CHSH )) && [[ $SHELL != "$ZSH_PATH" ]] && ask "Make zsh your default shell?" y; then
    grep -qx "$ZSH_PATH" /etc/shells || run bash -c "echo '$ZSH_PATH' | sudo tee -a /etc/shells >/dev/null"
    run chsh -s "$ZSH_PATH" "$USER" || warn "chsh failed — run manually: chsh -s $ZSH_PATH"
  fi
else
  log "zsh not available — bash only"
fi
ask "Configure bash too (fallback / root shells)?" y && wire "$DOTFILES/bashrc" "$HOME/.bashrc" "$SRC_LINE"

if ask "Configure tmux?" y; then
  wire "$DOTFILES/tmux.conf" "$HOME/.tmux.conf" 'source-file ~/.xt-dotfiles/tmux.conf'
fi

if ask "Configure git (delta pager, aliases)?" y; then
  wire "$DOTFILES/gitconfig" "$HOME/.gitconfig" '[include]
	path = ~/.xt-dotfiles/gitconfig'
  # identity lives outside the repo
  if [[ ! -f $HOME/.gitconfig.local ]]; then
    name="$(git config --global user.name 2>/dev/null || true)"; email="$(git config --global user.email 2>/dev/null || true)"
    if (( ! YES )); then
      read -rp "git user.name  [${name:-skip}]: " n </dev/tty; name="${n:-$name}"
      read -rp "git user.email [${email:-skip}]: " e </dev/tty; email="${e:-$email}"
    fi
    if [[ -n $name && -n $email ]]; then
      run bash -c "printf '[user]\n\tname = %s\n\temail = %s\n' '$name' '$email' > '$HOME/.gitconfig.local'"
    fi
  fi
fi

if ask "Configure ssh client (multiplexing, keepalive)?" y; then
  run install -d -m 700 "$HOME/.ssh" "$HOME/.ssh/config.d"
  wire "$DOTFILES/ssh_config" "$HOME/.ssh/config" 'Include ~/.xt-dotfiles/ssh_config' --prepend
  [[ -e $HOME/.ssh/config ]] && run chmod 600 "$HOME/.ssh/config"
  if [[ $OS == Darwin && ! -f $HOME/.ssh/config.d/00-term.conf ]]; then
    run bash -c "printf 'Host *\n  SetEnv TERM=xterm-256color\n' > '$HOME/.ssh/config.d/00-term.conf'"
  fi
fi

# ---------- Extras ----------
run mkdir -p "$HOME/.config" "$HOME/.cache"
if [[ ! -f $HOME/.config/starship.toml ]] && ask "Install starship.toml?" y; then
  run cp "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"
fi
[[ -f $HOME/.aliases.local ]] || { ask "Create ~/.aliases.local for host-specific overrides?" y && run touch "$HOME/.aliases.local"; }
command -v tldr >/dev/null && run tldr --update >/dev/null 2>&1 || true

log "Done. Run: exec \$SHELL -l"
