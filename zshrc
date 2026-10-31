# ~/.zshrc
HISTFILE=~/.zsh_history; HISTSIZE=50000; SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE SHARE_HISTORY INC_APPEND_HISTORY
setopt AUTO_CD CORRECT INTERACTIVE_COMMENTS
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

source ~/.xt-dotfiles/shell/common.sh

# at-a-glance MOTD on SSH login shells
[[ -n $SSH_CONNECTION && -o login ]] && command -v fastfetch >/dev/null && fastfetch

[[ -f $DOTFILES/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source "$DOTFILES/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f $DOTFILES/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source "$DOTFILES/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"  # keep last
