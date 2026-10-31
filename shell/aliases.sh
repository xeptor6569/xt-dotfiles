# ---- ls / eza ----
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l --group-directories-first --icons=auto --git --header'
  alias la='eza -la --group-directories-first --icons=auto --git --header'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
  alias lS='eza -l --sort=size --reverse --icons=auto'
  alias lm='eza -l --sort=modified --reverse --icons=auto'
else
  alias ll='ls -lh --color=auto'; alias la='ls -lAh --color=auto'
fi

# ---- modern replacements (only if present) ----
command -v bat  >/dev/null && alias cat='bat --paging=never' && alias catp='bat -p'
command -v rg   >/dev/null && alias grep='rg'
command -v duf  >/dev/null && alias df='duf'
command -v btop >/dev/null && alias top='btop'
command -v tldr >/dev/null && alias help='tldr'
command -v lazygit    >/dev/null && alias lg='lazygit'
command -v lazydocker >/dev/null && alias lzd='lazydocker'

# ---- navigation ----
alias ..='cd ..'; alias ...='cd ../..'; alias ....='cd ../../..'
alias -- -='cd -'
alias mkd='mkdir -pv'

# ---- safety ----
alias rm='rm -I'; alias cp='cp -i'; alias mv='mv -i'
alias chmod='chmod -v'; alias chown='chown -v'

# ---- system ----
alias please='sudo $(fc -ln -1)'
alias ports='ss -tulpn 2>/dev/null || netstat -anv'
alias myip='curl -s https://ifconfig.me; echo'
alias lip="hostname -I 2>/dev/null | awk '{print \$1}' || ipconfig getifaddr en0"
alias psg='ps aux | grep -v grep | grep -i'
alias h='history | tail -50'
alias path='echo -e ${PATH//:/\\n}'
alias reload='exec $SHELL -l'
alias e='$EDITOR'
alias t='tmux new -A -s main'

# ---- dotfiles ----
alias dots='cd $DOTFILES'
alias dotup='git -C ~/.xt-dotfiles pull --ff-only --recurse-submodules && ~/.xt-dotfiles/install.sh --yes --append --no-packages && exec $SHELL -l'
alias dotupfull='git -C ~/.xt-dotfiles pull --ff-only --recurse-submodules && ~/.xt-dotfiles/install.sh --yes --append && exec $SHELL -l'

# ---- apt (Debian) ----
if command -v apt-get >/dev/null; then
  alias aup='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'
  alias ai='sudo apt install -y'
  alias as='apt search'
  alias ash='apt show'
fi
# ---- brew (mac) ----
command -v brew >/dev/null && alias bup='brew update && brew upgrade && brew cleanup'

# ---- git ----
alias g='git'; alias gs='git status -sb'; alias ga='git add'; alias gc='git commit'
alias gp='git push'; alias gl='git pull'; alias gd='git diff'
alias glog='git log --oneline --graph --decorate -20'

# ---- systemd (Linux) ----
if command -v systemctl >/dev/null; then
  alias sc='sudo systemctl'; alias scs='systemctl status'; alias scr='sudo systemctl restart'
  alias jf='journalctl -f'; alias ju='journalctl -u'
fi
