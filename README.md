# dotfiles

Standardized terminal setup for Debian 13, Ubuntu 24.04+ and macOS. One repo, one installer,
identical shell everywhere (zsh preferred, bash as fallback), idempotent and safe to
run on machines that already have a config.

## Quick start

**Existing machine (keeps your current rc files, adds one include line):**

```sh
curl -fsSL https://raw.githubusercontent.com/xeptor6569/xt-dotfiles/main/bootstrap.sh | bash -s -- --append
```

**Fresh machine (replace rc files with repo versions; originals backed up):**

```sh
curl -fsSL https://raw.githubusercontent.com/xeptor6569/xt-dotfiles/main/bootstrap.sh | bash -s -- --yes --link
```

**Brand-new Debian or Ubuntu host, as root (user, sudo, ssh hardening, firewall, docker, dotfiles):**

```sh
curl -fsSL https://raw.githubusercontent.com/xeptor6569/xt-dotfiles/main/firstboot/linux-firstboot.sh \
| HOSTNAME_NEW=myhost bash -s -- myuser "ssh-ed25519 AAAA..."
```

**New Mac:**

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/xeptor6569/xt-dotfiles/main/firstboot/mac-firstboot.sh)
```

Then open a new terminal or `exec $SHELL -l`.

> Replace `YOU` with your GitHub user, or set `DOTFILES_REPO=` when calling the scripts.
> Review scripts before piping to bash; alternatively `git clone` and run `./install.sh`.
> The repo is cloned to `~/.xt-dotfiles` (override with `DOTFILES=`).

## What you get

| Area | Tools / config |
|---|---|
| Shell | zsh (autosuggestions, syntax-highlighting, pinned via submodules) or bash; shared history/completion settings |
| Prompt | [starship](https://starship.rs) — identical on every host, shows git/docker/duration |
| CLI replacements | `eza` (ls), `bat` (cat), `fd` (find), `ripgrep` (grep), `duf` (df), `btop` (top), `zoxide` (cd), `fzf`, `tldr`, `delta` (git diff), `ncdu`, `jq`, `fastfetch` |
| Aliases | general (`shell/aliases.sh`), docker/compose (`shell/docker.sh`), helpers (`shell/functions.sh`) |
| tmux | `C-a` prefix, mouse, true color, sane splits; `t` opens/attaches session `main` |
| git | delta pager, `pull.rebase`, `push.autoSetupRemote`, aliases; identity in `~/.gitconfig.local` |
| ssh | connection multiplexing, keepalives, `~/.ssh/config.d/*` for per-site hosts |
| Linux firstboot (Debian/Ubuntu) | user+sudo, ssh key-only, ufw, fail2ban, unattended-upgrades, locale, journald cap, Docker CE + log rotation, root gets the same shell |

## Supported platforms

| OS | Notes |
|---|---|
| Debian 13 | Reference platform. |
| Ubuntu 24.04+ | `fastfetch` isn't packaged before 25.04 (skipped; no SSH login banner). Packaged `fzf` is 0.44, too old for `fzf --zsh/--bash`, so the installer downloads a pinned release (`FZF_VERSION` in `install.sh`) to `~/.local/bin`. Docker uses the Ubuntu repo in firstboot. |
| macOS | Homebrew. |

The installer reads `/etc/os-release` (`DISTRO`, `DISTRO_FAMILY`) and treats anything Debian-like as apt-based.
Distro differences stay in small conditionals; there are no per-OS templates.

## Repository layout

```text
bootstrap.sh          curl|bash entry: installs git, clones/pulls repo, runs install.sh
install.sh            the installer (see flags below)
uninstall.sh          removes wiring, restores latest backups
shell/common.sh       env, PATH, tool init, loads aliases/docker/functions, update check
shell/aliases.sh      general aliases
shell/docker.sh       docker + compose aliases/functions
shell/functions.sh    helper functions
zshrc / bashrc        thin rc files -> source shell/common.sh
tmux.conf gitconfig ssh_config starship.toml
plugins/              git submodules (zsh-autosuggestions, zsh-syntax-highlighting)
firstboot/            linux-firstboot.sh (Debian/Ubuntu; debian-firstboot.sh is a compat wrapper), mac-firstboot.sh
test/docker-test.sh   run installer in a throwaway Debian/Ubuntu container
.github/workflows     shellcheck + install smoke test
```

## install.sh

```text
install.sh [--yes] [--dry-run] [--append|--link] [--no-packages] [--no-chsh]
```

| Flag | Effect |
|---|---|
| (none) | Interactive: shows what exists, asks per section, asks append/link/skip per file |
| `--yes` | Accept defaults, no prompts |
| `--dry-run` | Print every action, change nothing |
| `--append` | For existing config files: keep them, add one include/source line |
| `--link` | Back up existing files to `<file>.bak.<epoch>`, replace with symlinks into the repo |
| `--no-packages` | Skip apt/brew |
| `--no-chsh` | Don't change default shell |

### Behavior on existing systems

| Case | Result |
|---|---|
| Package already installed | Skipped (checked with `dpkg -s` / `brew list`) |
| Package not in repo | Warned and skipped, install continues |
| Alias already defined elsewhere | No error. Ours load last and win; put anything you want to **keep** in `~/.aliases.local` (loads after everything) |
| Existing `.zshrc` / `.bashrc` / `.tmux.conf` / `.gitconfig` / `.ssh/config` | `--append`: untouched + one include line. `--link`: backed up + symlinked |
| Already wired (symlink or include present) | Detected, skipped |
| Plugins already present | Skipped |
| Interrupted mid-run | Just re-run; every step is check-then-act |

Append vs link in practice:

- **append** — your old rc runs first, then ours. Zero risk to nvm/conda/oh-my-zsh init. Recommended for laptops and anything you've customized.
- **link** — the host becomes exactly the repo. Recommended for servers. To convert later: `install.sh --link`.

### Where host-specific things go (not in git)

| File | Purpose |
|---|---|
| `~/.aliases.local` | per-host aliases/env, lazy-loaded tools (nvm, pyenv) |
| `~/.gitconfig.local` | `[user] name/email` |
| `~/.ssh/config.d/*` | site host lists; `00-term.conf` on mac sets `TERM` for remote hosts |
| `~/.config/starship.toml` | copied once, then yours to edit |

## Daily use

| Command | What |
|---|---|
| `dotup` | pull repo + re-run installer (no packages) + reload shell |
| `dotupfull` | same, also installs new packages |
| `dots` | cd to repo |
| `reload` | restart shell |
| `t` | tmux attach-or-create `main` |
| `shellbench` | time 3 shell startups (target < 150 ms) |
| `ssh-terminfo host` | push local terminfo to a host that doesn't know your terminal |

Once a day, in the background, the shell checks whether the repo is behind origin and prints
`dotfiles: updates available — run dotup`.

### Alias cheat-sheet

**Files:** `ls ll la lt lS lm` (eza) · `cat`→bat · `grep`→rg · `df`→duf · `top`→btop · `help`→tldr
**Nav:** `.. ... ....` · `-` · `mkd` · `mkcd` · `z <dir>` (zoxide) · `Ctrl-R` history · `Ctrl-T` files · `Alt-C` dirs (fzf)
**System:** `aup ai as ash` (apt) · `bup` (brew) · `sc scs scr jf ju` (systemd) · `ports myip lip psg please`
**Git:** `g gs ga gc gp gl gd glog lg`
**Docker compose:** `dc dcu dcub dcd dcdv dcr dcs dcl dcps dce dcpull dcup dcconf`
**Docker:** `dps dpa di dl dex dstats dip dprune dpruneall lzd` · `dsh <c>` shell in · `dfe`/`dfl` fzf pick exec/logs · `dkill <c>` · `dcupall [dir]` pull+up every stack under `/opt/stacks`

`type <name>` shows what any alias expands to.

## Fonts / icons

Icons (`eza --icons`, starship glyphs) are rendered by **your terminal**, so the Nerd Font only
needs to be on the machine you type on — i.e. the Mac. The installer offers
`font-jetbrains-mono-nerd-font`; set it as the terminal font. Servers need nothing.

## Root shells

`linux-firstboot.sh` symlinks `/root/.xt-dotfiles` to the user's repo and runs the installer for
root with `--no-chsh`, so `sudo -i` has the same aliases. Day to day prefer `sudo -s`
(keeps your env). On an existing host do it manually:

```sh
sudo ln -sfn ~/.xt-dotfiles /root/.xt-dotfiles
sudo git config --global --add safe.directory ~/.xt-dotfiles
sudo DOTFILES=/root/.xt-dotfiles /root/.xt-dotfiles/install.sh --yes --link --no-packages --no-chsh
```

## Testing

```sh
test/docker-test.sh            # fresh Debian 13 container, --link
test/docker-test.sh existing   # container with a pre-existing .zshrc, --append
IMAGE=ubuntu:24.04 test/docker-test.sh   # same on Ubuntu
shellcheck install.sh bootstrap.sh uninstall.sh firstboot/*.sh shell/*.sh
~/.xt-dotfiles/install.sh --dry-run
```

CI (`.github/workflows/lint.yml`) runs shellcheck and a full install in `debian:13` and `ubuntu:24.04` containers
on every push.

## Maintenance

**Add an alias:** edit `shell/aliases.sh` (or `docker.sh`), commit, push; `dotup` on each host.

**Add a package:** add to `DEB_PKGS` / `BREW_PKGS` in `install.sh`; `dotupfull` on hosts.

**Set up the plugin submodules (once, when creating the repo):**

```sh
git submodule add https://github.com/zsh-users/zsh-autosuggestions plugins/zsh-autosuggestions
git submodule add https://github.com/zsh-users/zsh-syntax-highlighting plugins/zsh-syntax-highlighting
git -C plugins/zsh-autosuggestions checkout v0.7.1
git -C plugins/zsh-syntax-highlighting checkout 0.8.0
git add . && git commit -m "pin zsh plugins"
```

**Bump plugins:** `git -C plugins/<name> checkout <newtag> && git add plugins && git commit`.

**Uninstall:** `~/.xt-dotfiles/uninstall.sh` — removes symlinks/include lines, restores the most
recent `.bak`. Packages stay. `chsh -s /bin/bash` if you want bash back.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `bat`/`fd` not found on Debian/Ubuntu | Installer symlinks `batcat`/`fdfind` into `~/.local/bin`; check it's on `PATH` (`path`) |
| Boxes instead of icons | Terminal font isn't a Nerd Font |
| `WARNING: terminal is not fully functional` / tmux colors wrong over ssh | `ssh-terminfo host`, or ensure `~/.ssh/config.d/00-term.conf` exists on the Mac |
| `perl: warning: Setting locale failed` | Host lacks `en_US.UTF-8`; firstboot runs `locale-gen`. Manually: `sudo dpkg-reconfigure locales` |
| Slow shell start | `shellbench`; move nvm/pyenv/conda init into `~/.aliases.local` and lazy-load |
| `chsh: PAM authentication failed` | Run `chsh -s $(which zsh)` yourself; or ignore and keep bash |
| Git says "dubious ownership" as root | `git config --global --add safe.directory /home/<user>/.xt-dotfiles` |
| Old alias still winning in append mode | It's defined in `~/.aliases.local` or your terminal app; `type <alias>`, then remove or override |

## When to outgrow this

- **Per-host templating, secrets, many OS variants** → [chezmoi](https://www.chezmoi.io) (same layout, adds templates/encryption/`chezmoi update`).
- **Fleet config that must be re-applied** (users, sshd, firewall, docker daemon) → convert `firstboot/linux-firstboot.sh` to an Ansible playbook; it's already structured as idempotent tasks.
