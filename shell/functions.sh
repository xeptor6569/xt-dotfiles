mkcd()    { mkdir -p "$1" && cd "$1" || return; }
extract() { case "$1" in
  *.tar.gz|*.tgz) tar xzf "$1";; *.tar.xz) tar xJf "$1";; *.tar.bz2) tar xjf "$1";;
  *.zip) unzip "$1";; *.gz) gunzip "$1";; *.7z) 7z x "$1";; *) echo "unknown: $1";; esac; }
ff()      { fd --type f "${1:-.}" | fzf --preview 'bat --color=always {}'; }
fe()      { local f; f=$(ff "${1:-.}") && $EDITOR "$f"; }
fkill()   { ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs -r kill -"${1:-9}"; }
backup()  { cp -a "$1" "$1.bak.$(date +%Y%m%d-%H%M%S)"; }
sshkeys() { cat ~/.ssh/*.pub; }
serve()   { python3 -m http.server "${1:-8000}"; }
weather() { curl -s "wttr.in/${1:-}?format=3"; }
# push your terminal's terminfo to a host that doesn't know it (kitty/ghostty/etc.)
ssh-terminfo() { infocmp -x | ssh "$1" 'tic -x -'; }
# measure shell startup (target < 150ms)
shellbench() { local i; for i in 1 2 3; do time "$SHELL" -i -c exit; done; }
