#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v keyd &>/dev/null && ! command -v keyd.rvaiya &>/dev/null; then
  echo "Installing keyd..."
  sudo add-apt-repository -y ppa:keyd-team/ppa
  sudo apt update
  sudo apt install -y keyd
fi

sudo mkdir -p /etc/keyd
sudo cp "$REPO_DIR/shared/dotfiles/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo systemctl restart keyd
echo "keyd config applied."
