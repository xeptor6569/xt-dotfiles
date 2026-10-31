command -v docker >/dev/null || return 0

# compose
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcub='docker compose up -d --build'
alias dcd='docker compose down'
alias dcdv='docker compose down -v'
alias dcr='docker compose restart'
alias dcs='docker compose stop'
alias dcl='docker compose logs -f --tail=100'
alias dcps='docker compose ps'
alias dce='docker compose exec'
alias dcpull='docker compose pull'
alias dcup='docker compose pull && docker compose up -d --remove-orphans'
alias dcconf='docker compose config'

# containers / images
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort'
alias dpa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | sort'
alias di='docker images'
alias dl='docker logs -f --tail=100'
alias dex='docker exec -it'
alias dstats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"'
alias dip='docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}"'

# cleanup
alias dprune='docker system prune -f'
alias dpruneall='docker system prune -af --volumes'

# functions
dsh()   { docker exec -it "$1" sh -c 'command -v bash >/dev/null && exec bash || exec sh'; }
dlog()  { docker logs -f --tail="${2:-100}" "$1"; }
dkill() { docker stop "$1" && docker rm "$1"; }
dfe()   { local c; c=$(docker ps --format '{{.Names}}' | fzf) && dsh "$c"; }
dfl()   { local c; c=$(docker ps --format '{{.Names}}' | fzf) && docker logs -f --tail=100 "$c"; }
# update every compose stack under a directory (default /opt/stacks)
dcupall() {
  local root="${1:-/opt/stacks}" d
  for d in "$root"/*/; do
    [[ -f "$d/compose.yaml" || -f "$d/compose.yml" || -f "$d/docker-compose.yml" ]] || continue
    echo "=== $(basename "$d") ==="
    (cd "$d" && docker compose pull -q && docker compose up -d --remove-orphans)
  done
  docker image prune -f
}
