# Sourced by both ~/.bashrc and ~/.zshrc (and by append-mode rc files)
export DOTFILES="$HOME/.xt-dotfiles"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
[[ -d /opt/homebrew/bin ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"
export EDITOR="${EDITOR:-micro}"
export VISUAL="$EDITOR"
export LESS="-R -F -X -i"
export BAT_THEME="ansi"
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

_shell="$(basename "${ZSH_NAME:-${BASH:-sh}}")"

command -v zoxide   >/dev/null && eval "$(zoxide init "$_shell")"
command -v starship >/dev/null && eval "$(starship init "$_shell")"
if command -v fzf >/dev/null; then
  # fzf >= 0.48 can emit its own integration; older packages (Ubuntu 24.04: 0.44) ship files instead.
  # Check for output rather than exit status: eval of an empty string succeeds.
  _fzf_init="$(fzf --"$_shell" 2>/dev/null)"
  if [[ -n $_fzf_init ]]; then
    eval "$_fzf_init"
  else
    for _d in /usr/share/doc/fzf/examples /usr/share/fzf /usr/share/fzf/shell; do
      for _f in key-bindings completion; do
        [[ -f $_d/$_f.$_shell ]] && source "$_d/$_f.$_shell"
      done
    done
  fi
  unset _fzf_init _d
fi

for _f in aliases docker functions; do
  [[ -f "$DOTFILES/shell/$_f.sh" ]] && source "$DOTFILES/shell/$_f.sh"
done
[[ -f "$HOME/.aliases.local" ]] && source "$HOME/.aliases.local"   # per-host overrides, not in git

# Daily, background, silent check for dotfiles updates
_dot_stamp="$HOME/.cache/dotfiles-check"
if [[ -d $DOTFILES/.git ]] && { [[ ! -f $_dot_stamp ]] || [[ -n $(find "$_dot_stamp" -mtime +1 2>/dev/null) ]]; }; then
  mkdir -p "$HOME/.cache" && touch "$_dot_stamp"
  ( git -C "$DOTFILES" fetch -q 2>/dev/null \
    && [[ $(git -C "$DOTFILES" rev-list HEAD..@{u} --count 2>/dev/null) -gt 0 ]] \
    && printf '\033[33mdotfiles: updates available — run dotup\033[0m\n' ) &
fi
unset _shell _f _dot_stamp
