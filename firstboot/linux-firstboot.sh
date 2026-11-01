#!/usr/bin/env bash
# Fresh Debian 13 / Ubuntu 24.04+ host. Run as root:
#   curl -fsSL https://raw.githubusercontent.com/xeptor6569/xt-dotfiles/main/firstboot/linux-firstboot.sh \
#     | bash -s -- <username> ["ssh-ed25519 AAAA..."]
# Env: HOSTNAME_NEW=foo TZ=America/New_York DOTFILES_REPO=https://github.com/xeptor6569/xt-dotfiles
set -euo pipefail
NEWUSER="${1:?usage: $0 <username> [ssh-pubkey]}"
PUBKEY="${2:-}"
HOSTNAME_NEW="${HOSTNAME_NEW:-}"
TZ="${TZ:-America/New_York}"
REPO="${DOTFILES_REPO:-https://github.com/xeptor6569/xt-dotfiles}"
export DEBIAN_FRONTEND=noninteractive

# shellcheck disable=SC1091
. /etc/os-release
case "$ID" in
  debian) DOCKER_DISTRO=debian; CODENAME="$VERSION_CODENAME" ;;
  ubuntu) DOCKER_DISTRO=ubuntu; CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}" ;;
  *) echo "Unsupported distro '$ID' (need debian or ubuntu)" >&2; exit 1 ;;
esac

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

log "System update + base packages"
apt-get update && apt-get full-upgrade -y
apt-get install -y sudo git curl wget vim locales unattended-upgrades apt-listchanges \
  needrestart ufw fail2ban ca-certificates gnupg lsb-release

log "Locale / timezone / hostname"
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen && update-locale LANG=en_US.UTF-8
timedatectl set-timezone "$TZ"
[[ -n $HOSTNAME_NEW ]] && hostnamectl set-hostname "$HOSTNAME_NEW"

log "User $NEWUSER + sudo"
id "$NEWUSER" &>/dev/null || adduser --disabled-password --gecos "" "$NEWUSER"
usermod -aG sudo "$NEWUSER"
echo "$NEWUSER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$NEWUSER"; chmod 440 "/etc/sudoers.d/90-$NEWUSER"

if [[ -n $PUBKEY ]]; then
  log "SSH key + sshd hardening"
  install -d -m 700 -o "$NEWUSER" -g "$NEWUSER" "/home/$NEWUSER/.ssh"
  grep -qF "$PUBKEY" "/home/$NEWUSER/.ssh/authorized_keys" 2>/dev/null || echo "$PUBKEY" >> "/home/$NEWUSER/.ssh/authorized_keys"
  chmod 600 "/home/$NEWUSER/.ssh/authorized_keys"; chown "$NEWUSER:$NEWUSER" "/home/$NEWUSER/.ssh/authorized_keys"
  cat > /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin prohibit-password
KbdInteractiveAuthentication no
AcceptEnv LANG LC_* TERM
EOF
  systemctl reload ssh
fi

log "Firewall, fail2ban, auto security updates"
ufw allow OpenSSH && ufw --force enable
systemctl enable --now fail2ban
dpkg-reconfigure -f noninteractive unattended-upgrades

log "Journald size cap"
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=200M\n' > /etc/systemd/journald.conf.d/size.conf
systemctl restart systemd-journald
journalctl --vacuum-size=200M >/dev/null 2>&1 || true

log "Quiet stock MOTD (fastfetch runs from the shell instead)"
chmod -x /etc/update-motd.d/* 2>/dev/null || true

if ! command -v docker >/dev/null; then
  log "Docker (official repo)"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$DOCKER_DISTRO/gpg" -o /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DOCKER_DISTRO $CODENAME stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
usermod -aG docker "$NEWUSER"
mkdir -p /opt/stacks && chown "$NEWUSER:$NEWUSER" /opt/stacks
if [[ ! -f /etc/docker/daemon.json ]]; then
  log "Docker log rotation"
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<'EOF'
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
EOF
  systemctl restart docker
fi

log "Dotfiles for $NEWUSER"
sudo -u "$NEWUSER" -H bash -c "
  [[ -d ~/.xt-dotfiles ]] || git clone --recurse-submodules '$REPO' ~/.xt-dotfiles
  ~/.xt-dotfiles/install.sh --yes --link"

log "Dotfiles for root (shared repo, no shell change)"
ln -sfn "/home/$NEWUSER/.xt-dotfiles" /root/.xt-dotfiles
git config --global --add safe.directory "/home/$NEWUSER/.xt-dotfiles"
DOTFILES=/root/.xt-dotfiles /root/.xt-dotfiles/install.sh --yes --link --no-packages --no-chsh

log "Done. Log in as $NEWUSER. Reboot recommended: $(needrestart -b 2>/dev/null | grep -c 'NEEDRESTART-KSTA: [23]' || echo 0) kernel restart pending"
