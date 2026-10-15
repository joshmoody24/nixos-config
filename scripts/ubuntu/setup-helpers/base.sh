#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
. "$(dirname "$0")/lib.sh"
NIX_DAEMON_SH="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

# Ensure curl is available
if ! command -v curl &>/dev/null; then
  sudo apt install -y curl
fi

# Install Nix
if ! command -v nix &>/dev/null; then
  if [ -f "$NIX_DAEMON_SH" ]; then
    echo "Nix is installed but not on PATH. Sourcing nix-daemon.sh..."
    . "$NIX_DAEMON_SH"
    # Sourcing is a no-op once a login shell has already done it, which leaves
    # PATH unrepaired in sessions that set their own.
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  else
    echo "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    . "$NIX_DAEMON_SH"
  fi
fi

# Enable flakes
mkdir -p ~/.config/nix
if ! grep -q 'experimental-features' ~/.config/nix/nix.conf 2>/dev/null; then
  echo "Enabling flakes..."
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# Apply home-manager
echo "Applying home-manager configuration..."
nix run home-manager -- switch -b backup --flake "$REPO_DIR#josh@$(hostname)"

# Sudo: don't re-prompt for password during the session
install_system_file 440 /etc/sudoers.d/timeout 'Defaults timestamp_timeout=-1'

# Install and configure keyd (needs PPA on Ubuntu 24.04)
if ! command -v keyd &>/dev/null; then
  echo "Installing keyd..."
  sudo add-apt-repository -y ppa:keyd-team/ppa
  sudo apt update
  sudo apt install -y keyd
fi
install_system_file 644 /etc/keyd/default.conf \
  "$(cat "$REPO_DIR/shared/dotfiles/keyd/default.conf")" \
  sudo systemctl restart keyd
sudo systemctl enable --now keyd

# Install Tailscale
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# sshd, for reaching this machine over the tailnet
if ! dpkg -s openssh-server &>/dev/null; then
  echo "Installing openssh-server..."
  sudo apt install -y openssh-server
fi

# The JumpCloud agent owns ~/.ssh/authorized_keys, so our own keys go in a
# second file. It lives under /etc because sshd's StrictModes rejects keys
# resolving into the group-writable /nix/store.
# Every .pub in there, matching the keyFiles glob in shared/configuration.nix.
echo "Installing SSH authorized keys..."
cat "$REPO_DIR"/shared/dotfiles/ssh/*.pub |
  sudo install -D -m 444 -o root -g root /dev/stdin /etc/ssh/authorized_keys.d/josh

install_system_file 644 /etc/ssh/sshd_config.d/10-nixos-config.conf \
  'AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
PasswordAuthentication no
KbdInteractiveAuthentication no' \
  sudo systemctl restart ssh
sudo systemctl enable --now ssh

# Nix garbage collection (weekly, delete older than 30 days)
if ! systemctl --user is-enabled nix-gc.timer &>/dev/null 2>&1; then
  echo "Setting up nix garbage collection timer..."
  mkdir -p ~/.config/systemd/user

  cat > ~/.config/systemd/user/nix-gc.service <<'UNIT'
[Unit]
Description=Nix garbage collection

[Service]
Type=oneshot
ExecStart=/nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 30d
UNIT

  cat > ~/.config/systemd/user/nix-gc.timer <<'UNIT'
[Unit]
Description=Weekly nix garbage collection

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
UNIT

  systemctl --user daemon-reload
  systemctl --user enable --now nix-gc.timer
fi

# zram: compressed swap in RAM (fewer OOMs on large type checks)
if ! dpkg -s zram-tools &>/dev/null; then
  echo "Installing zram-tools..."
  sudo apt install -y zram-tools
fi

install_system_file 644 /etc/default/zramswap 'ALGO=zstd
PERCENT=50
PRIORITY=100' \
  sudo systemctl restart zramswap

# Tuning for zram-backed swap: prefer compressing pages over evicting code
install_system_file 644 /etc/sysctl.d/99-zram.conf 'vm.swappiness=180
vm.watermark_boost_factor=0
vm.watermark_scale_factor=125
vm.page-cluster=0' \
  sudo sysctl --system --quiet

# earlyoom: kill the offending process early instead of freezing on kernel OOM
if ! dpkg -s earlyoom &>/dev/null; then
  echo "Installing earlyoom..."
  sudo apt install -y earlyoom
fi

install_system_file 644 /etc/default/earlyoom \
  "EARLYOOM_ARGS=\"-r 60 -m 5 -s 5 --avoid '(^|/)(systemd|Xorg|gnome-shell|sshd)\$' --prefer '(^|/)(node|tsc|tsserver|esbuild)\$'\"" \
  sudo systemctl restart earlyoom
sudo systemctl enable --now earlyoom

# Ubuntu's systemd-oomd kills whole session cgroups (logs you out); mask the
# service and its triggering socket so nothing pulls it back up, leaving
# earlyoom in charge
for unit in systemd-oomd.service systemd-oomd.socket; do
  if [ "$(systemctl is-enabled "$unit" 2>/dev/null)" != "masked" ]; then
    echo "Masking $unit in favor of earlyoom..."
    sudo systemctl mask --now "$unit"
  fi
done

echo "Base setup done!"
