# ~/.bashrc
[[ $- != *i* ]] && return
HISTSIZE=50000; HISTFILESIZE=50000; HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize cdspell autocd globstar 2>/dev/null
bind '"\e[A": history-search-backward'; bind '"\e[B": history-search-forward'
bind 'set completion-ignore-case on'
[[ -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
source ~/.xt-dotfiles/shell/common.sh
[[ -n $SSH_CONNECTION && $0 == -* ]] && command -v fastfetch >/dev/null && fastfetch
