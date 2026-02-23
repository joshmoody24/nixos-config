#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
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

# Install and configure keyd (needs PPA on Ubuntu 24.04)
if ! command -v keyd &>/dev/null; then
  echo "Installing keyd..."
  sudo add-apt-repository -y ppa:keyd-team/ppa
  sudo apt update
  sudo apt install -y keyd
fi
echo "Copying keyd configuration..."
sudo mkdir -p /etc/keyd
sudo cp "$REPO_DIR/shared/dotfiles/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload

# Install Tailscale
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# Nix garbage collection (weekly, delete older than 30 days)
if ! systemctl --user is-enabled nix-gc.timer &>/dev/null 2>&1; then
  echo "Setting up nix garbage collection timer..."
  mkdir -p ~/.config/systemd/user

  cat > ~/.config/systemd/user/nix-gc.service <<'UNIT'
[Unit]
Description=Nix garbage collection

[Service]
Type=oneshot
ExecStart=nix-collect-garbage --delete-older-than 30d
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

echo "Base setup done!"
