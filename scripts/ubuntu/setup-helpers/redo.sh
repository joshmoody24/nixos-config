#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"

# Add redo hosts entries to /etc/hosts
if ! grep -q 'getredo.localhost' /etc/hosts; then
  echo "Adding redo hosts entries to /etc/hosts..."
  printf '\n' | sudo tee -a /etc/hosts >/dev/null
  cat "$REPO_DIR/shared/dotfiles/redo/hosts/redo-hosts" | sudo tee -a /etc/hosts >/dev/null
else
  echo "Redo hosts entries already present, skipping."
fi

# Install and configure Caddy
if ! command -v caddy &>/dev/null; then
  echo "Installing Caddy..."
  sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  sudo apt update
  sudo apt install -y caddy
fi

echo "Copying Caddy configuration..."
sudo cp "$REPO_DIR/shared/dotfiles/redo/caddy/Caddyfile" /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
sudo systemctl reload caddy

echo "Trusting Caddy's local CA..."
caddy trust

echo "Redo setup done!"
