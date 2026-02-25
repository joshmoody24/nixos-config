#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"

# --- /etc/hosts (marker-based, safe to re-run) ---
HOSTS_FILE="$REPO_DIR/shared/dotfiles/redo/hosts/redo-hosts"
MARKER_START="# BEGIN redo-hosts"
MARKER_END="# END redo-hosts"

if grep -q "$MARKER_START" /etc/hosts; then
  sudo sed -i "/$MARKER_START/,/$MARKER_END/d" /etc/hosts
fi
echo "Updating /etc/hosts with redo entries..."
printf '%s\n%s\n%s\n' "$MARKER_START" "$(cat "$HOSTS_FILE")" "$MARKER_END" | sudo tee -a /etc/hosts >/dev/null
echo "redo hosts applied."

# --- Caddy ---
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

sudo cp "$REPO_DIR/shared/dotfiles/redo/caddy/Caddyfile" /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
sudo systemctl reload caddy
echo "Trusting Caddy's local CA..."
caddy trust

# --- Docker ---
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! groups | grep -q '\bdocker\b'; then
  echo "Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  echo "NOTE: Log out and back in for docker group to take effect."
fi

sudo systemctl enable --now docker

echo "Redo setup done!"
